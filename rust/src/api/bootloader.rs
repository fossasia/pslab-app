use anyhow::{anyhow, Result};
use byteorder::{LittleEndian, ReadBytesExt, WriteBytesExt};
use std::io::Cursor;

use crate::frb_generated::StreamSink;
use crate::api::simple::{read_data, set_baud_rate, write_data};

const FLASH_UNLOCK_KEY: u32 = 0x00AA0055;

#[derive(Clone, Debug)]
pub enum FlashState {
    Connecting,
    Erasing,
    Writing { progress_percent: i32 },
    Verifying,
    Finished,
    Error { message: String },
}

#[derive(Clone)]
struct Segment {
    address: u32,
    data: Vec<u8>,
}

fn read_exact(size: u32, timeout_ms: u32) -> Result<Vec<u8>> {
    let mut buf = Vec::new();
    let start = std::time::Instant::now();
    let timeout = std::time::Duration::from_millis(timeout_ms as u64);

    while buf.len() < size as usize {
        if start.elapsed() > timeout {
            return Err(anyhow!("Read timeout: Expected {} bytes, got {}", size, buf.len()));
        }
        let chunk = read_data(size - buf.len() as u32, 100);
        if !chunk.is_empty() {
            buf.extend(chunk);
        }
    }
    Ok(buf)
}

fn exchange(
    command: u8,
    data_len: u16,
    unlock: u32,
    addr: u32,
    payload: &[u8],
    timeout_ms: u32,
) -> Result<Vec<u8>> {
    let mut tx = Vec::new();
    tx.write_u8(command)?;
    tx.write_u16::<LittleEndian>(data_len)?;
    tx.write_u32::<LittleEndian>(unlock)?;
    tx.write_u32::<LittleEndian>(addr)?;
    tx.extend_from_slice(payload);

    write_data(tx);

    let header = read_exact(11, timeout_ms)?;
    if header[0] != command {
        return Err(anyhow!("Command echo mismatch: expected 0x{:02X}, got 0x{:02X}", command, header[0]));
    }

    if command == 0x00 {
        let remainder = read_exact(26, timeout_ms)?;
        let mut resp = header;
        resp.extend(remainder);
        return Ok(resp);
    }

    let success = read_exact(1, timeout_ms)?;
    if success[0] != 0x01 {
        return Err(anyhow!("Bootloader error code: 0x{:02X}", success[0]));
    }

    let remainder_len = match command {
        0x0B => 8,
        0x08 => 2,
        _ => 0,
    };

    let mut resp = header;
    resp.extend(success);
    if remainder_len > 0 {
        let remainder = read_exact(remainder_len, timeout_ms)?;
        resp.extend(remainder);
    }

    Ok(resp)
}

fn get_local_checksum(data: &[u8]) -> u16 {
    let mut chksum: u32 = 0;
    for chunk in data.chunks(4) {
        if chunk.len() >= 3 {
            chksum += chunk[0] as u32 + ((chunk[1] as u32) << 8) + chunk[2] as u32;
        }
    }
    (chksum & 0xFFFF) as u16
}


fn prepare_flash_chunks(hex_str: &str, program_start: u32, program_end: u32, max_packet: u16, write_size: u16) -> Result<Vec<Segment>> {
    let num_pc_addresses = program_end - program_start;
    let mut mem_size_bytes = num_pc_addresses * 2;

    let rem = mem_size_bytes % (write_size as u32);
    if rem != 0 { mem_size_bytes += (write_size as u32) - rem; }

    let mut flash_mem = vec![0xFFu8; mem_size_bytes as usize];
    let mut has_data = vec![false; mem_size_bytes as usize];

    let mut ext_lin_addr: u32 = 0;
    let mut ext_seg_addr: u32 = 0;

    for record in ihex::Reader::new(hex_str) {
        let rec = match record {
            Ok(r) => r,
            Err(e) => return Err(anyhow!("HEX parse error: {:?}", e)),
        };

        match rec {
            ihex::Record::ExtendedLinearAddress(addr) => {
                ext_lin_addr = (addr as u32) << 16;
                ext_seg_addr = 0;
            }
            ihex::Record::ExtendedSegmentAddress(addr) => {
                ext_seg_addr = (addr as u32) << 4;
                ext_lin_addr = 0;
            }
            ihex::Record::Data { offset, value } => {
                let base_hex_addr = ext_lin_addr + ext_seg_addr + (offset as u32);

                for (i, &byte) in value.iter().enumerate() {
                    let hex_addr = base_hex_addr + (i as u32);

                    let pc_addr = hex_addr / 2;

                    if pc_addr >= program_start && pc_addr < program_end {
                        let pc_offset = pc_addr - program_start;
                        let byte_offset = (pc_offset * 2) + (hex_addr % 2);

                        flash_mem[byte_offset as usize] = byte;
                        has_data[byte_offset as usize] = true;
                    }
                }
            }
            ihex::Record::EndOfFile => break,
            _ => {}
        }
    }

    let mut segments: Vec<Segment> = Vec::new();
    let mut i = 0;

    while i < mem_size_bytes {
        let block_end = std::cmp::min(i + (write_size as u32), mem_size_bytes);
        let mut block_has_data = false;

        for j in i..block_end {
            if has_data[j as usize] {
                block_has_data = true;
                break;
            }
        }

        if block_has_data {
            let block_data = &flash_mem[i as usize .. block_end as usize];
            let block_pc_addr = program_start + (i / 2);

            if let Some(last) = segments.last_mut() {
                let last_end_pc = last.address + (last.data.len() as u32 / 2);
                if last_end_pc == block_pc_addr {
                    last.data.extend_from_slice(block_data);
                } else {
                    segments.push(Segment { address: block_pc_addr, data: block_data.to_vec() });
                }
            } else {
                segments.push(Segment { address: block_pc_addr, data: block_data.to_vec() });
            }
        }
        i += write_size as u32;
    }

    let max_payload_bytes = ((max_packet as u32 - 11) / (write_size as u32)) * (write_size as u32);
    let mut chunks = Vec::new();

    for seg in segments {
        let mut offset = 0;
        while offset < seg.data.len() {
            let take = std::cmp::min(max_payload_bytes as usize, seg.data.len() - offset);
            chunks.push(Segment {
                address: seg.address + (offset as u32 / 2),
                data: seg.data[offset .. offset + take].to_vec(),
            });
            offset += take;
        }
    }

    Ok(chunks)
}

pub fn flash_firmware(hex_str: String, progress_sink: StreamSink<FlashState>) -> Result<()> {
    let _ = progress_sink.add(FlashState::Connecting);

    match flash_inner(hex_str, &progress_sink) {
        Ok(_) => {
            println!("[FLASHER DEBUG] SEQUENCE COMPLETE.");
            Ok(())
        }
        Err(e) => {
            let err_msg = format!("Flasher failed: {}", e);
            println!("\n[FLASHER FATAL ERROR] {}\n", err_msg);
            let _ = progress_sink.add(FlashState::Error { message: err_msg.clone() });
            Err(anyhow!(err_msg))
        }
    }
}

fn flash_inner(hex_str: String, progress_sink: &StreamSink<FlashState>) -> Result<()> {
    set_baud_rate(460800).unwrap_or(());
    let _ = read_data(2048, 200);

    let version_resp = exchange(0x00, 0, 0, 0, &[], 2000)?;
    let mut cursor = Cursor::new(&version_resp[11..]);
    let _version = cursor.read_u16::<LittleEndian>()?;
    let max_packet_length = cursor.read_u16::<LittleEndian>()?;
    let _1 = cursor.read_u16::<LittleEndian>()?;
    let _device_id = cursor.read_u16::<LittleEndian>()?;
    let _2 = cursor.read_u16::<LittleEndian>()?;
    let erase_size = cursor.read_u16::<LittleEndian>()?;
    let write_size = cursor.read_u16::<LittleEndian>()?;
    let mem_resp = exchange(0x0B, 0, 0, 0, &[], 2000)?;
    let mut cursor = Cursor::new(&mem_resp[12..]);
    let program_start = cursor.read_u32::<LittleEndian>()?;
    let mut program_end = cursor.read_u32::<LittleEndian>()?;
    program_end += 2;
    let chunks = prepare_flash_chunks(&hex_str, program_start, program_end, max_packet_length, write_size)?;
    let total_bytes: usize = chunks.iter().map(|c| c.data.len()).sum();

    if total_bytes == 0 {
        return Err(anyhow!("Hex file is empty or missing physical flash data."));
    }

    let _ = progress_sink.add(FlashState::Erasing);
    let pages_to_erase = (program_end - program_start) / (erase_size as u32);

    if let Err(e) = exchange(0x03, pages_to_erase as u16, FLASH_UNLOCK_KEY, program_start, &[], 15000) {
        return Err(anyhow!("Bulk erase failed: {}", e));
    }

    let mut written_bytes = 0;
    for chunk in chunks {
        exchange(0x02, chunk.data.len() as u16, FLASH_UNLOCK_KEY, chunk.address, &chunk.data, 2000)?;
        let chk_resp = exchange(0x08, chunk.data.len() as u16, 0, chunk.address, &[], 2000)?;
        let remote_checksum = Cursor::new(&chk_resp[12..]).read_u16::<LittleEndian>()?;
        let local_checksum = get_local_checksum(&chunk.data);

        if remote_checksum != local_checksum {
            return Err(anyhow!("Checksum mismatch at 0x{:08X}", chunk.address));
        }

        written_bytes += chunk.data.len();
        let percent = (written_bytes as f32 / total_bytes as f32 * 100.0) as i32;
        let _ = progress_sink.add(FlashState::Writing { progress_percent: percent });
    }
    let _ = progress_sink.add(FlashState::Verifying);

    if let Err(e) = exchange(0x0A, 0, 0, 0, &[], 5000) {
        return Err(anyhow!("Self Verify Failed: Bootloader rejected flash integrity. Error: {}", e));
    }

    let _ = exchange(0x09, 0, 0, 0, &[], 1000);

    let _ = progress_sink.add(FlashState::Finished);
    Ok(())
}