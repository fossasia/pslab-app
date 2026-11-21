use anyhow::{anyhow, Result};
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
#[cfg(all(not(target_family = "wasm"), not(target_os = "ios")))]
use rusb::{request_type, Direction, Recipient, RequestType};
use std::collections::VecDeque;
use std::sync::Mutex;
use std::time::Duration;
use std::f64::consts::PI;

#[cfg(all(not(target_family = "wasm"), not(target_os = "ios")))]
use crate::api::common::USB_HANDLE;

lazy_static! {
    static ref FGEN_TRIPLE: Mutex<u8> = Mutex::new(0);
    static ref CACHED_WAVE_CH1: Mutex<Option<(u16, u16, Vec<u8>)>> = Mutex::new(None);
    static ref CACHED_WAVE_CH2: Mutex<Option<(u16, u16, Vec<u8>)>> = Mutex::new(None);
    static ref LABRADOR_CH1_BUFFER: Mutex<VecDeque<u8>> = Mutex::new(VecDeque::with_capacity(500_000));
    static ref LABRADOR_CH2_BUFFER: Mutex<VecDeque<u8>> = Mutex::new(VecDeque::with_capacity(500_000));
    static ref LABRADOR_STREAMING: Mutex<bool> = Mutex::new(false);
    static ref CURRENT_MODE: Mutex<u16> = Mutex::new(0);

    static ref RAW_USB_QUEUE: Mutex<VecDeque<u8>> = Mutex::new(VecDeque::with_capacity(500_000));

    static ref PROD_PACKET_COUNT: Mutex<u64> = Mutex::new(0);
    static ref CONS_PACKET_COUNT: Mutex<u64> = Mutex::new(0);
    static ref FETCH_CALL_COUNT: Mutex<u64> = Mutex::new(0);

    static ref LABRADOR_TRIGGER_ENABLED: Mutex<bool> = Mutex::new(true);
    static ref DIGITAL_OUT_STATE: Mutex<u16> = Mutex::new(0);
}

const FGEN_LIMIT: f64 = 3.2;
const XMEGA_MAIN_FREQ: f64 = 48_000_000.0;

fn calculate_gain_mask(gain: f64) -> u16 {
    let raw_mask: u16 = if (gain - 0.5).abs() < 0.05 { 0x07 }
    else if (gain - 1.0).abs() < 0.05 { 0x00 }
    else if (gain - 2.0).abs() < 0.05 { 0x01 }
    else if (gain - 4.0).abs() < 0.05 { 0x02 }
    else if (gain - 8.0).abs() < 0.05 { 0x03 }
    else if (gain - 16.0).abs() < 0.05 { 0x04 }
    else if (gain - 32.0).abs() < 0.05 { 0x05 }
    else if (gain - 64.0).abs() < 0.05 { 0x06 }
    else { 0x00 };
    (raw_mask << 2) | (raw_mask << 8)
}

#[frb(sync)]
pub fn labrador_calculate_gain_mask(gain: f64) -> u16 {
    calculate_gain_mask(gain)
}

#[frb(sync)]
pub fn labrador_start_oscilloscope(channels: u8, gain: f64) -> Result<()> {
    let mode: u16 = if channels >= 2 { 2 } else { 0 };
    *CURRENT_MODE.lock().unwrap() = mode;

    #[cfg(all(not(target_family = "wasm"), not(target_os = "ios")))]
    {
        let handle_arc = {
            let guard = USB_HANDLE.lock().unwrap();
            guard.as_ref().cloned().ok_or_else(|| anyhow!("USB handle missing"))?
        };

        let _ = handle_arc.claim_interface(0);
        if let Ok(_) = handle_arc.claim_interface(2) {
            let _ = handle_arc.set_alternate_setting(2, 1);
        }
        let mut flush_buf = vec![0u8; 125];
        for i in 0..6 {
            while let Ok(len) = handle_arc.read_bulk(0x81 + i, &mut flush_buf, Duration::from_millis(5)) {
                if len == 0 { break; }
            }
        }
        let _ = handle_arc.clear_halt(0x88);

        let gain_mask = calculate_gain_mask(gain);
        let req_type = request_type(Direction::Out, RequestType::Vendor, Recipient::Device);

        println!("Setting device mode: {} (gain_mask=0x{:04X})", mode, gain_mask);
        handle_arc.write_control(req_type, 0xA5, mode, gain_mask, &[], Duration::from_millis(1000))
            .map_err(|e| anyhow!("Failed mode: {}", e))?;
        std::thread::sleep(Duration::from_millis(50));

        if let Some((tp, div, samples)) = CACHED_WAVE_CH1.lock().unwrap().as_ref() {
            let _ = handle_arc.write_control(req_type, 0xA2, *tp, *div, samples, Duration::from_millis(1000));
        }
        if let Some((tp, div, samples)) = CACHED_WAVE_CH2.lock().unwrap().as_ref() {
            let _ = handle_arc.write_control(req_type, 0xA1, *tp, *div, samples, Duration::from_millis(1000));
        }

        let current_triple = *FGEN_TRIPLE.lock().unwrap();
        let _ = handle_arc.write_control(req_type, 0xA4, current_triple as u16, 0, &[], Duration::from_millis(1000));

        let dig_mask = *DIGITAL_OUT_STATE.lock().unwrap();
        let _ = handle_arc.write_control(req_type, 0xA6, dig_mask, 0, &[], Duration::from_millis(1000));

        LABRADOR_CH1_BUFFER.lock().unwrap().clear();
        LABRADOR_CH2_BUFFER.lock().unwrap().clear();
        RAW_USB_QUEUE.lock().unwrap().clear();

        spawn_stream_thread();
    }

    #[cfg(any(target_family = "wasm", target_os = "ios"))]
    {
        let _ = gain;
        LABRADOR_CH1_BUFFER.lock().unwrap().clear();
        LABRADOR_CH2_BUFFER.lock().unwrap().clear();
        RAW_USB_QUEUE.lock().unwrap().clear();
    }

    Ok(())
}

#[frb(sync)]
pub fn labrador_start_multimeter() -> Result<()> {
    let mode: u16 = 7;
    *CURRENT_MODE.lock().unwrap() = mode;

    #[cfg(all(not(target_family = "wasm"), not(target_os = "ios")))]
    {
        let handle_arc = {
            let guard = USB_HANDLE.lock().unwrap();
            guard.as_ref().cloned().ok_or_else(|| anyhow!("USB handle missing"))?
        };

        let _ = handle_arc.claim_interface(0);

        let req_type = request_type(Direction::Out, RequestType::Vendor, Recipient::Device);
        handle_arc.write_control(req_type, 0xA5, mode, calculate_gain_mask(1.0), &[], Duration::from_millis(1000))
            .map_err(|e| anyhow!("Failed multimeter: {}", e))?;
        std::thread::sleep(Duration::from_millis(50));

        let current_triple = *FGEN_TRIPLE.lock().unwrap();
        let _ = handle_arc.write_control(req_type, 0xA4, current_triple as u16, 0, &[], Duration::from_millis(1000));

        LABRADOR_CH1_BUFFER.lock().unwrap().clear();
        RAW_USB_QUEUE.lock().unwrap().clear();
        spawn_stream_thread();
    }

    #[cfg(any(target_family = "wasm", target_os = "ios"))]
    {
        LABRADOR_CH1_BUFFER.lock().unwrap().clear();
        RAW_USB_QUEUE.lock().unwrap().clear();
    }

    Ok(())
}

#[frb(sync)]
pub fn labrador_start_logic_analyzer(channels: u8) -> Result<()> {
    let mode: u16 = if channels >= 2 { 4 } else { 3 };
    *CURRENT_MODE.lock().unwrap() = mode;

    #[cfg(all(not(target_family = "wasm"), not(target_os = "ios")))]
    {
        let handle_arc = {
            let guard = USB_HANDLE.lock().unwrap();
            guard.as_ref().cloned().ok_or_else(|| anyhow!("USB handle missing"))?
        };

        let _ = handle_arc.claim_interface(0);
        if let Ok(_) = handle_arc.claim_interface(2) {
            let _ = handle_arc.set_alternate_setting(2, 1);
        }
        let mut flush_buf = vec![0u8; 125];
        for i in 0..6 {
            while let Ok(len) = handle_arc.read_bulk(0x81 + i, &mut flush_buf, Duration::from_millis(5)) {
                if len == 0 { break; }
            }
        }

        let req_type = request_type(Direction::Out, RequestType::Vendor, Recipient::Device);

        println!("Setting Labrador Logic Analyzer mode: {}", mode);
        handle_arc.write_control(req_type, 0xA5, mode, 0, &[], Duration::from_millis(1000))
            .map_err(|e| anyhow!("Failed logic analyzer mode: {}", e))?;
        std::thread::sleep(Duration::from_millis(50));

        if let Some((tp, div, samples)) = CACHED_WAVE_CH1.lock().unwrap().as_ref() {
            let _ = handle_arc.write_control(req_type, 0xA2, *tp, *div, samples, Duration::from_millis(1000));
        }
        if let Some((tp, div, samples)) = CACHED_WAVE_CH2.lock().unwrap().as_ref() {
            let _ = handle_arc.write_control(req_type, 0xA1, *tp, *div, samples, Duration::from_millis(1000));
        }

        let current_triple = *FGEN_TRIPLE.lock().unwrap();
        let _ = handle_arc.write_control(req_type, 0xA4, current_triple as u16, 0, &[], Duration::from_millis(1000));

        let dig_mask = *DIGITAL_OUT_STATE.lock().unwrap();
        let _ = handle_arc.write_control(req_type, 0xA6, dig_mask, 0, &[], Duration::from_millis(1000));

        LABRADOR_CH1_BUFFER.lock().unwrap().clear();
        LABRADOR_CH2_BUFFER.lock().unwrap().clear();
        RAW_USB_QUEUE.lock().unwrap().clear();

        spawn_stream_thread();
    }

    #[cfg(any(target_family = "wasm", target_os = "ios"))]
    {
        LABRADOR_CH1_BUFFER.lock().unwrap().clear();
        LABRADOR_CH2_BUFFER.lock().unwrap().clear();
        RAW_USB_QUEUE.lock().unwrap().clear();
    }

    Ok(())
}


fn process_raw_bulk_frames(
    raw_stream: &mut Vec<u8>,
    last_good_ch1: &mut [u8],
    last_good_ch2: &mut [u8],
    last_good_all: &mut [u8],
    last_good_valid: &mut bool,
) {
    let add_data = |ch1_data: &[u8], ch2_data: Option<&[u8]>| {
        if let Ok(mut ch1) = LABRADOR_CH1_BUFFER.lock() {
            ch1.extend(ch1_data);
            let c = ch1.len();
            if c > 100_000 { ch1.drain(0..(c - 100_000)); }
        }
        if let Some(ch2_d) = ch2_data {
            if let Ok(mut ch2) = LABRADOR_CH2_BUFFER.lock() {
                ch2.extend(ch2_d);
                let c = ch2.len();
                if c > 100_000 { ch2.drain(0..(c - 100_000)); }
            }
        }
    };

    let current_mode = *CURRENT_MODE.lock().unwrap();

    while raw_stream.len() >= 832 {
        let mut magic_offset = None;
        for i in 0..=(raw_stream.len() - 832) {
            if raw_stream[i] == 0xEB && raw_stream[i+1] == 0x57 {
                magic_offset = Some(i);
                break;
            }
        }

        if let Some(offset) = magic_offset {
            if offset > 0 {
                raw_stream.drain(0..offset);
            }

            let frame = &raw_stream[0..832];
            let payload_len = (frame[4] as u16) | ((frame[5] as u16) << 8);
            if payload_len == 750 {
                let mut csum = 0u8;
                for b in 0..750 {
                    csum ^= frame[64 + b];
                }

                let is_valid = csum == frame[6];
                let payload = &frame[64..64 + 750];

                if is_valid {
                    last_good_all.copy_from_slice(payload);
                    last_good_ch1.copy_from_slice(&payload[0..375]);
                    last_good_ch2.copy_from_slice(&payload[375..750]);
                    *last_good_valid = true;

                    match current_mode {
                        6 => { add_data(payload, None); }
                        0 | 3 | 7 => { add_data(&payload[0..375], None); }
                        1 | 2 | 4 => { add_data(&payload[0..375], Some(&payload[375..750])); }
                        _ => {}
                    }
                } else if *last_good_valid {
                    match current_mode {
                        6 => { add_data(last_good_all, None); }
                        0 | 3 | 7 => { add_data(last_good_ch1, None); }
                        1 | 2 | 4 => { add_data(last_good_ch1, Some(last_good_ch2)); }
                        _ => {}
                    }
                } else {
                    match current_mode {
                        6 => { add_data(payload, None); }
                        0 | 3 | 7 => { add_data(&payload[0..375], None); }
                        1 | 2 | 4 => { add_data(&payload[0..375], Some(&payload[375..750])); }
                        _ => {}
                    }
                }
            }
            raw_stream.drain(0..832);
        } else {
            let drain_amount = raw_stream.len() - 831;
            raw_stream.drain(0..drain_amount);
            break;
        }
    }
}

#[cfg(all(not(target_family = "wasm"), not(target_os = "ios")))]
fn spawn_stream_thread() {
    let mut streaming = LABRADOR_STREAMING.lock().unwrap();
    if *streaming { return; }
    *streaming = true;
    drop(streaming);

    if let Some(handle) = crate::api::common::USB_HANDLE.lock().unwrap().as_ref() {
        let reader = handle.clone();

        println!("Spawning AIO Bulk (0x88) stream thread...");

        std::thread::spawn(move || {
            let mut buf = vec![0u8; 832 * 12]; 
            let mut last_good_ch1 = vec![128u8; 375];
            let mut last_good_ch2 = vec![128u8; 375];
            let mut last_good_all = vec![128u8; 750];
            let mut last_good_valid = false;
            let mut raw_stream = Vec::new();

            while *LABRADOR_STREAMING.lock().unwrap() {
                match reader.read_bulk(0x88, &mut buf, Duration::from_millis(100)) {
                    Ok(len) if len > 0 => {
                        raw_stream.extend_from_slice(&buf[0..len]);
                        process_raw_bulk_frames(
                            &mut raw_stream,
                            &mut last_good_ch1,
                            &mut last_good_ch2,
                            &mut last_good_all,
                            &mut last_good_valid,
                        );
                    }
                    Ok(_) => {}
                    Err(rusb::Error::Timeout) => {}
                    Err(e) => { 
                        println!("read_bulk 0x88 error: {:?}. Clearing halt...", e);
                        let _ = reader.clear_halt(0x88);
                        std::thread::sleep(Duration::from_millis(20)); 
                    }
                }
            }
        });
    }
}

lazy_static! {
    static ref WEB_RAW_STREAM: Mutex<Vec<u8>> = Mutex::new(Vec::new());
    static ref WEB_LAST_GOOD_CH1: Mutex<Vec<u8>> = Mutex::new(vec![128u8; 375]);
    static ref WEB_LAST_GOOD_CH2: Mutex<Vec<u8>> = Mutex::new(vec![128u8; 375]);
    static ref WEB_LAST_GOOD_ALL: Mutex<Vec<u8>> = Mutex::new(vec![128u8; 750]);
    static ref WEB_LAST_GOOD_VALID: Mutex<bool> = Mutex::new(false);
}

#[frb(sync)]
pub fn labrador_push_web_bulk_data(data: Vec<u8>) {
    if let (Ok(mut raw), Ok(mut lg1), Ok(mut lg2), Ok(mut lga), Ok(mut lgv)) = (
        WEB_RAW_STREAM.lock(),
        WEB_LAST_GOOD_CH1.lock(),
        WEB_LAST_GOOD_CH2.lock(),
        WEB_LAST_GOOD_ALL.lock(),
        WEB_LAST_GOOD_VALID.lock(),
    ) {
        raw.extend_from_slice(&data);
        process_raw_bulk_frames(&mut raw, &mut lg1, &mut lg2, &mut lga, &mut lgv);
    }
}

#[frb(sync)]
pub fn labrador_stop_streaming() {
    *LABRADOR_STREAMING.lock().unwrap() = false;
}

#[frb(sync)]
pub fn labrador_fetch_interpolated(
    channel: u8,
    sample_window_secs: f64,
    num_samples: u32,
    _delay_offset_secs: f64,
) -> Vec<f64> {
    let mut fcount = FETCH_CALL_COUNT.lock().unwrap();
    *fcount += 1;
    let cur = *fcount;
    drop(fcount);

    let current_mode = *CURRENT_MODE.lock().unwrap();
    let samples_per_second = if current_mode == 6 { 750_000.0 } else { 375_000.0 };

    let total_needed = sample_window_secs * samples_per_second;
    let step = total_needed / (num_samples as f64);
    let smoothing_window = f64::max(step, 2.0) as usize;

    let delay_samples = _delay_offset_secs * samples_per_second;

    if num_samples == 0 {
        return vec![];
    }
    if channel > 2 {
        return vec![0.0; num_samples as usize];
    }
    let (local_data, len, trigger_start_of_win) = {
        let buffer_guard = if channel == 2 {
            LABRADOR_CH2_BUFFER.lock().unwrap()
        } else {
            LABRADOR_CH1_BUFFER.lock().unwrap()
        };
        let b_len = buffer_guard.len();
        
        let end_of_win = (b_len as f64) - delay_samples;
        let mut start_of_win = end_of_win - total_needed;
        
        if cur % 100 == 0 {
            println!("b_len={}, end_of_win={}, start_of_win={}, total_needed={}, num_samples={}, delay_samples={}", b_len, end_of_win, start_of_win, total_needed, num_samples, delay_samples);
        }
        
        let base_idx = start_of_win as isize;
        let search_limit = ((total_needed * 4.0) as isize).max(35_000).min(base_idx.max(0));
        
        let (first, second) = buffer_guard.as_slices();
        let first_len = first.len();
        
        let get_val = |idx: isize| -> u8 {
            if idx < 0 || idx >= b_len as isize { return 0; }
            let u_idx = idx as usize;
            if u_idx < first_len { first[u_idx] } else { second[u_idx - first_len] }
        };

        let trigger_enabled = *LABRADOR_TRIGGER_ENABLED.lock().unwrap();

        if trigger_enabled && _delay_offset_secs.abs() < 0.0001 && search_limit > 10 {
            let mut w_min: i8 = 127;
            let mut w_max: i8 = -128;
            for offset in 0..search_limit {
                let val = get_val(base_idx - offset) as i8;
                if val < w_min { w_min = val; }
                if val > w_max { w_max = val; }
            }
        
            if w_max.saturating_sub(w_min) > 3 {
                let midpoint = w_min as isize + ((w_max as isize - w_min as isize) / 2);
                let hysteresis = ((w_max as isize - w_min as isize) / 8).max(1);
                
                let mut crest_offset: Option<isize> = None;
                
                for offset in 0..search_limit {
                    let idx = base_idx - offset;
                    let current_val = get_val(idx) as i8 as isize;
                    
                    if crest_offset.is_none() {
                        if current_val >= midpoint + hysteresis {
                            crest_offset = Some(offset);
                        }
                    } else {
                        if current_val <= midpoint - hysteresis {
                            let trough_idx = idx;
                            let crest_idx = base_idx - crest_offset.unwrap();
                            let mut trigger_idx = trough_idx;
                            for k in trough_idx..=crest_idx {
                                if (get_val(k) as i8 as isize) >= midpoint {
                                    trigger_idx = k;
                                    break;
                                }
                            }
                            start_of_win = trigger_idx as f64;
                            break;
                        }
                    }
                }
            }
        }
    
        let end_of_win_trig = start_of_win + total_needed;
        let min_idx = (start_of_win - (smoothing_window as f64 / 2.0)).round() as isize;
        let max_idx = (end_of_win_trig + (smoothing_window as f64 / 2.0)).round() as isize;
        
        let min_idx = min_idx.max(0) as usize;
        let max_idx = max_idx.min(b_len as isize) as usize;
        
        let slice_len = if max_idx > min_idx { max_idx - min_idx } else { 0 };
        let mut local_data = vec![0u8; slice_len];
        
        if slice_len > 0 {
            for i in 0..slice_len {
                let global_idx = min_idx + i;
                local_data[i] = if global_idx < first_len {
                    first[global_idx]
                } else {
                    second[global_idx - first_len]
                };
            }
        }
        (local_data, b_len, start_of_win)
    };

    let start_of_win = trigger_start_of_win;

    let offset_idx = (start_of_win - (smoothing_window as f64 / 2.0)).round() as isize;
    let offset_idx = offset_idx.max(0) as usize;

    let mut out = vec![0.0; num_samples as usize];

    for i in 0..(num_samples as usize) {
        let exact_idx = start_of_win + (i as f64 * step);
        let idx_floor = exact_idx.floor() as isize;
        let idx_ceil = exact_idx.ceil() as isize;
        
        let get_sample = |global_idx: isize| -> f64 {
            let offset_isize = offset_idx as isize;
            if global_idx >= offset_isize && (global_idx - offset_isize) < (local_data.len() as isize) {
                let raw = local_data[(global_idx - offset_isize) as usize];
                (raw as i8) as f64
            } else {
                0.0
            }
        };

        let val_floor = get_sample(idx_floor);
        
        let interpolated = if idx_floor == idx_ceil {
            val_floor
        } else {
            let val_ceil = get_sample(idx_ceil);
            val_floor + (val_ceil - val_floor) * (exact_idx - (idx_floor as f64))
        };

        out[i] = interpolated;
    }

    if cur % 30 == 0 {
        let min_v = out.iter().cloned().fold(f64::INFINITY, f64::min);
        let max_v = out.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
        let preview: Vec<f64> = out.iter().take(5).map(|v| (v * 100.0).round() / 100.0).collect();
        println!("#{} | CH{} | Win: {:.4}s | Len: {} | Step: {:.2} | Min: {:.2}, Max: {:.2} | First 5: {:?}",
            cur, channel, sample_window_secs, len, step, min_v, max_v, preview);
    }

    out
}

#[frb(sync)]
pub fn labrador_set_trigger_enabled(enabled: bool) -> Result<()> {
    *LABRADOR_TRIGGER_ENABLED.lock().unwrap() = enabled;
    Ok(())
}

#[frb(sync)]
pub fn labrador_calculate_psu_duty(voltage: f64) -> u16 {
    if voltage <= 0.001 {
        0u16
    } else {
        let comp_v = (voltage - 0.29).max(0.0);
        let calculated = ((comp_v / 11.0 / 1.65) * 128.0).round() as u16;
        calculated.clamp(21, 106)
    }
}

#[frb(sync)]
pub fn labrador_set_psu_voltage(voltage: f64) -> Result<()> {
    let duty_psu = labrador_calculate_psu_duty(voltage);

    println!("Setting PSU voltage: {:.2}V -> target duty={}", voltage, duty_psu);

    #[cfg(all(not(target_family = "wasm"), not(target_os = "ios")))]
    {
        let handle_arc = {
            let guard = USB_HANDLE.lock().unwrap();
            guard.as_ref().cloned().ok_or_else(|| anyhow!("USB handle missing"))?
        };

        let req_type = request_type(Direction::Out, RequestType::Vendor, Recipient::Device);
        handle_arc.write_control(req_type, 0xA3, duty_psu, 0, &[], Duration::from_millis(1000))
            .map_err(|e| anyhow!("Failed to set PSU: {}", e))?;
        let _ = handle_arc.clear_halt(0x88);
    }

    Ok(())
}

fn generator_sin(x: f64) -> u8 { (255.0 * ((x.sin() + 1.0) / 2.0)).round() as u8 }
fn generator_sawtooth(x: f64) -> u8 { (255.0 * (x / (2.0 * PI))).round() as u8 }
fn generator_triangle(x: f64) -> u8 {
    if x <= PI { (255.0 * (x / PI)).round() as u8 }
    else { (255.0 * (1.0 - ((x - PI) / PI))).round() as u8 }
}

#[derive(Clone, Debug, Default)]
pub struct LabradorWavePayload {
    pub request_id: u8,
    pub timer_period: u16,
    pub clock_divider: u16,
    pub triple_mask: u8,
    pub samples: Vec<u8>,
}

#[frb(sync)]
pub fn labrador_calculate_wave_payload(
    channel: u8,
    frequency_hz: f64,
    wave_type: String,
    amplitude_v: f64,
    offset_v: f64,
) -> Result<LabradorWavePayload> {
    let mut amp = amplitude_v;
    let mut off = offset_v;
    let mut num_samples: u16 = 128;
    while (num_samples as f64) * frequency_hz > 1_000_000.0 && num_samples > 8 {
        num_samples /= 2;
    }
    if num_samples == 0 { return Err(anyhow!("Frequency too high")); }

    let mut raw_samples = Vec::with_capacity(num_samples as usize);

    let (base_type, duty) = if wave_type.starts_with("pwm") {
        let d = wave_type.split(':').nth(1).and_then(|s| s.parse::<f64>().ok()).unwrap_or(0.5);
        let d = if d > 1.0 { d / 100.0 } else { d };
        ("pwm", d)
    } else if wave_type.starts_with("square") {
        let d = wave_type.split(':').nth(1).and_then(|s| s.parse::<f64>().ok()).unwrap_or(0.5);
        let d = if d > 1.0 { d / 100.0 } else { d };
        ("pwm", d)
    } else {
        (wave_type.as_str(), 0.5)
    };

    if base_type == "pwm" {
        let duty_samples = ((duty.clamp(0.001, 0.999) * (num_samples as f64)).round() as usize)
            .clamp(1, (num_samples - 1) as usize);
        for i in 0..num_samples as usize {
            if i < duty_samples {
                raw_samples.push(255);
            } else {
                raw_samples.push(0);
            }
        }
    } else {
        for i in 0..num_samples {
            let x_temp = (i as f64) * (2.0 * PI / (num_samples as f64));
            let val = match base_type {
                "sine" => generator_sin(x_temp),
                "sawtooth" => generator_sawtooth(x_temp),
                "tria" => generator_triangle(x_temp),
                "dc" => 255,
                _ => generator_sin(x_temp),
            };
            raw_samples.push(val);
        }
    }

    let mut current_triple = *FGEN_TRIPLE.lock().unwrap();
    if (amp + off) > FGEN_LIMIT {
        amp /= 3.0; off /= 3.0;
        if channel == 1 { current_triple |= 0b00000001; } else { current_triple |= 0b00000010; }
    } else {
        if channel == 1 { current_triple &= 0b11111110; } else { current_triple &= 0b11111101; }
    }
    *FGEN_TRIPLE.lock().unwrap() = current_triple;

    let mut amp_sample = (amp * 255.0) / FGEN_LIMIT;
    let mut off_sample = (off * 255.0) / FGEN_LIMIT;

    const FGEN_SAMPLE_MIN: f64 = 5.0;

    if off_sample < FGEN_SAMPLE_MIN {
        if amp_sample > FGEN_SAMPLE_MIN { amp_sample -= FGEN_SAMPLE_MIN; }
        else { amp_sample = 0.0; }
        off_sample = FGEN_SAMPLE_MIN;
    }

    let mut processed = vec![0u8; num_samples as usize];
    for i in 0..num_samples as usize {
        let mut d = raw_samples[i] as f64;
        d = (d * amp_sample / 255.0) + off_sample;
        d = d.max(0.0).min(255.0);
        processed[i] = d as u8;
    }
    let valid_divs: [f64; 7] = [1.0, 2.0, 4.0, 8.0, 64.0, 256.0, 1024.0];
    let mut clk_setting = 0;
    let mut timer_period = 0u16;
    for i in 0..7 {
        let p = (XMEGA_MAIN_FREQ / (valid_divs[i] * (num_samples as f64) * frequency_hz)) - 0.5;
        if p < 65535.0 && p >= 0.0 {
            clk_setting = i;
            timer_period = p.round() as u16;
            break;
        }
    }

    let clock_divider = (clk_setting + 1) as u16;
    let request_id = if channel == 1 { 0xA2 } else { 0xA1 };

    Ok(LabradorWavePayload {
        request_id,
        timer_period,
        clock_divider,
        triple_mask: current_triple,
        samples: processed,
    })
}

#[frb(sync)]
pub fn labrador_generate_analog_wave(
    channel: u8,
    frequency_hz: f64,
    wave_type: String,
    amplitude_v: f64,
    offset_v: f64,
) -> Result<()> {
    println!("Generating wave: CH={}, freq={:.1}Hz, type={}, amp={:.2}V, offset={:.2}V",
        channel, frequency_hz, wave_type, amplitude_v, offset_v);

    let payload = labrador_calculate_wave_payload(channel, frequency_hz, wave_type, amplitude_v, offset_v)?;

    #[cfg(all(not(target_family = "wasm"), not(target_os = "ios")))]
    {
        let handle_arc = {
            let guard = USB_HANDLE.lock().unwrap();
            guard.as_ref().cloned().ok_or_else(|| anyhow!("USB handle missing"))?
        };

        let req_type = request_type(Direction::Out, RequestType::Vendor, Recipient::Device);

        println!("Writing wave params: req=0x{:02X}, period={}, div={}, samples={}",
            payload.request_id, payload.timer_period, payload.clock_divider, payload.samples.len());

        handle_arc.write_control(req_type, payload.request_id, payload.timer_period, payload.clock_divider, &payload.samples, Duration::from_millis(1000))
            .map_err(|e| anyhow!("Failed wave: {}", e))?;
        handle_arc.write_control(req_type, 0xA4, payload.triple_mask as u16, 0, &[], Duration::from_millis(1000))
            .map_err(|e| anyhow!("Failed triple: {}", e))?;
    }

    if channel == 1 {
        *CACHED_WAVE_CH1.lock().unwrap() = Some((payload.timer_period, payload.clock_divider, payload.samples));
    } else {
        *CACHED_WAVE_CH2.lock().unwrap() = Some((payload.timer_period, payload.clock_divider, payload.samples));
    }

    Ok(())
}

#[frb(sync)]
pub fn labrador_calculate_digital_out_state(channel: u8, state: bool) -> u16 {
    let mut mask = DIGITAL_OUT_STATE.lock().unwrap();
    if channel >= 1 && channel <= 4 {
        if state {
            *mask |= 1 << (channel - 1);
        } else {
            *mask &= !(1 << (channel - 1));
        }
    } else if channel == 0 {
        *mask = if state { 0x0F } else { 0 };
    }
    *mask
}

#[frb(sync)]
pub fn labrador_set_digital_out(channel: u8, state: bool) -> Result<()> {
    let dig_state = labrador_calculate_digital_out_state(channel, state);

    #[cfg(all(not(target_family = "wasm"), not(target_os = "ios")))]
    {
        let handle_arc = {
            let guard = USB_HANDLE.lock().unwrap();
            guard.as_ref().cloned().ok_or_else(|| anyhow!("USB handle missing"))?
        };

        let req_type = request_type(Direction::Out, RequestType::Vendor, Recipient::Device);

        handle_arc.write_control(req_type, 0xA6, dig_state, 0, &[], Duration::from_millis(1000))
            .map_err(|e| anyhow!("Failed digital out: {}", e))?;
        let _ = handle_arc.clear_halt(0x88);
    }

    Ok(())
}

#[frb(sync)]
pub fn labrador_fetch_raw_bytes(channel: u8, num_bytes: u32) -> Vec<u8> {
    let mut buffer = if channel == 2 {
        LABRADOR_CH2_BUFFER.lock().unwrap()
    } else {
        LABRADOR_CH1_BUFFER.lock().unwrap()
    };

    let len = buffer.len();
    let needed = num_bytes as usize;

    if len < needed {
        return Vec::new();
    }

    buffer.drain(0..(len - needed));
    buffer.drain(..).collect()
}