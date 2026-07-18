use anyhow::{anyhow, Result};
use flutter_rust_bridge::frb;
use lazy_static::lazy_static;
use std::sync::Mutex;
use std::collections::VecDeque;

#[cfg(not(target_family = "wasm"))]
use rusb::{
    request_type, DeviceHandle, Direction, GlobalContext, Recipient,
    RequestType, TransferType, UsbContext,
};
#[cfg(not(target_family = "wasm"))]
use std::sync::{mpsc, Arc};
#[cfg(not(target_family = "wasm"))]
use std::thread;
#[cfg(not(target_family = "wasm"))]
use std::time::Duration;

#[cfg(not(target_family = "wasm"))]
lazy_static! {
    static ref TX_QUEUE: Mutex<Option<mpsc::Sender<Vec<u8>>>> = Mutex::new(None);
    static ref USB_HANDLE: Mutex<Option<Arc<DeviceHandle<GlobalContext>>>> = Mutex::new(None);
    static ref EP_IN: Mutex<u8> = Mutex::new(0);
    static ref EP_OUT: Mutex<u8> = Mutex::new(0);
    static ref INTERFACE_ID: Mutex<u8> = Mutex::new(0);
}


#[cfg(target_family = "wasm")]
lazy_static! {
    static ref WEB_RX_BUFFER: Mutex<VecDeque<u8>> = Mutex::new(VecDeque::new());
}


pub fn init_desktop(vid: u16, pid: u16) -> Result<()> {
    #[cfg(not(target_family = "wasm"))]
    {
        let handle = rusb::open_device_with_vid_pid(vid, pid)
            .ok_or_else(|| anyhow!("Device not found or permission denied"))?;
        setup_device(handle)
    }
    #[cfg(target_family = "wasm")]
    {
        let _ = (vid, pid);
        Err(anyhow!("Desktop initialization not supported on Web target"))
    }
}

pub fn init_android(fd: i32) -> Result<()> {
    #[cfg(all(target_os = "android", not(target_family = "wasm")))]
    {
        use std::os::unix::io::RawFd;

        unsafe {
            extern "C" {
                fn libusb_set_option(ctx: *mut std::ffi::c_void, option: i32) -> i32;
            }
            libusb_set_option(std::ptr::null_mut(), 2);
        }

        let context = GlobalContext::default();
        let handle = unsafe { context.open_device_with_fd(fd as RawFd) }
            .map_err(|e| anyhow!("Failed to open Android FD: {}", e))?;

        setup_device(handle)
    }
    #[cfg(not(all(target_os = "android", not(target_family = "wasm"))))]
    {
        let _ = fd;
        Err(anyhow!("Android initialization is only supported on Android OS"))
    }
}

#[cfg(not(target_family = "wasm"))]
fn setup_device(handle: DeviceHandle<GlobalContext>) -> Result<()> {
    let device = handle.device();
    let desc = device
        .device_descriptor()
        .map_err(|e| anyhow!("Failed to get device descriptor: {}", e))?;

    let config = device
        .active_config_descriptor()
        .map_err(|e| anyhow!("Failed to get config: {}", e))?;

    let is_v6_cp210x = desc.vendor_id() == 0x10C4 && desc.product_id() == 0xEA60;
    let is_v5_mcp2200 = desc.vendor_id() == 1240 && desc.product_id() == 223;

    let mut ep_in = 0;
    let mut ep_out = 0;
    let mut interface_num = 0;

    for interface in config.interfaces() {
        for interface_desc in interface.descriptors() {
            for endpoint in interface_desc.endpoint_descriptors() {
                if endpoint.transfer_type() == TransferType::Bulk {
                    if endpoint.direction() == Direction::In {
                        ep_in = endpoint.address();
                    } else if endpoint.direction() == Direction::Out {
                        ep_out = endpoint.address();
                    }
                }
            }
            interface_num = interface.number();
        }
    }

    if ep_in == 0 || ep_out == 0 {
        return Err(anyhow!("Could not find required Bulk Endpoints"));
    }

    let _ = handle.set_auto_detach_kernel_driver(true);
    handle
        .claim_interface(interface_num)
        .map_err(|e| anyhow!("Failed to claim interface: {}", e))?;

    let timeout = Duration::from_millis(100);

    if is_v6_cp210x {
        let req_type = request_type(Direction::Out, RequestType::Vendor, Recipient::Device);

        handle.write_control(req_type, 0x00, 0x0001, interface_num as u16, &[], timeout)
            .map_err(|e| anyhow!("Failed to enable UART: {}", e))?;

        let baud: u32 = 1_000_000;
        let baud_bytes = baud.to_le_bytes();
        handle.write_control(req_type, 0x1E, 0, interface_num as u16, &baud_bytes, timeout)
            .map_err(|e| anyhow!("Failed to set Baud Rate: {}", e))?;

        handle.write_control(req_type, 0x03, 0x0800, interface_num as u16, &[], timeout)
            .map_err(|e| anyhow!("Failed to set Line Control: {}", e))?;

        let flow_off: [u8; 16] = [
            0x01, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00,
        ];
        handle.write_control(req_type, 0x13, 0, interface_num as u16, &flow_off, timeout)
            .map_err(|e| anyhow!("Failed to disable Flow: {}", e))?;

        handle.write_control(req_type, 0x07, 0x0000, interface_num as u16, &[], timeout)
            .map_err(|e| anyhow!("Failed to set MHS: {}", e))?;

    } else if is_v5_mcp2200 {
        let req_type = request_type(Direction::Out, RequestType::Class, Recipient::Interface);

        let mut line_coding = vec![];
        line_coding.extend_from_slice(&1_000_000u32.to_le_bytes());
        line_coding.push(0x00);
        line_coding.push(0x00);
        line_coding.push(0x08);

        handle.write_control(req_type, 0x20, 0, interface_num as u16, &line_coding, timeout)
            .map_err(|e| anyhow!("Failed to set MCP2200 Baud Rate: {}", e))?;

        handle.write_control(req_type, 0x22, 0x03, interface_num as u16, &[], timeout)
            .map_err(|e| anyhow!("Failed to set MCP2200 DTR/RTS: {}", e))?;
    }

    let handle_arc = Arc::new(handle);
    *USB_HANDLE.lock().unwrap() = Some(handle_arc.clone());
    *EP_IN.lock().unwrap() = ep_in;
    *EP_OUT.lock().unwrap() = ep_out;
    *INTERFACE_ID.lock().unwrap() = interface_num;

    let (tx, rx) = mpsc::channel::<Vec<u8>>();
    *TX_QUEUE.lock().unwrap() = Some(tx);

    thread::spawn(move || {
        while let Ok(data) = rx.recv() {
            let _ = handle_arc.write_bulk(ep_out, &data, Duration::from_millis(100));
        }
    });

    Ok(())
}

#[frb(sync)]
pub fn set_baud_rate(baud_rate: u32) -> Result<()> {
    #[cfg(not(target_family = "wasm"))]
    {
        if let Some(handle) = USB_HANDLE.lock().unwrap().as_ref() {
            let interface_num = *INTERFACE_ID.lock().unwrap();
            let desc = handle.device().device_descriptor().unwrap();
            let is_v5_mcp2200 = desc.vendor_id() == 1240 && desc.product_id() == 223;

            if is_v5_mcp2200 {
                let req_type = request_type(Direction::Out, RequestType::Class, Recipient::Interface);
                let mut line_coding = vec![];
                line_coding.extend_from_slice(&baud_rate.to_le_bytes());
                line_coding.push(0x00);
                line_coding.push(0x00);
                line_coding.push(0x08);

                handle.write_control(req_type, 0x20, 0, interface_num as u16, &line_coding, Duration::from_millis(100))
                    .map_err(|e| anyhow!("Failed to set V5 Baud Rate: {}", e))?;
            } else {
                let req_type = request_type(Direction::Out, RequestType::Vendor, Recipient::Device);
                let baud_bytes = baud_rate.to_le_bytes();

                handle.write_control(req_type, 0x1E, 0, interface_num as u16, &baud_bytes, Duration::from_millis(100))
                    .map_err(|e| anyhow!("Failed to set V6 Baud Rate: {}", e))?;
            }
            Ok(())
        } else {
            Err(anyhow!("USB Not Connected"))
        }
    }
    #[cfg(target_family = "wasm")]
    {
        let _ = baud_rate;
        Ok(())
    }
}

#[frb(sync)]
pub fn set_dtr(state: bool) -> Result<()> {
    #[cfg(not(target_family = "wasm"))]
    {
        if let Some(handle) = USB_HANDLE.lock().unwrap().as_ref() {
            let interface_num = *INTERFACE_ID.lock().unwrap();
            let desc = handle.device().device_descriptor().unwrap();
            let is_v5_mcp2200 = desc.vendor_id() == 1240;

            if is_v5_mcp2200 {
                let req_type = request_type(Direction::Out, RequestType::Class, Recipient::Interface);
                let val = if state { 0x01 } else { 0x00 };
                let _ = handle.write_control(req_type, 0x22, val, interface_num as u16, &[], Duration::from_millis(100));
            } else {
                let req_type = request_type(Direction::Out, RequestType::Vendor, Recipient::Device);
                let val = if state { 0x0101 } else { 0x0100 };
                let _ = handle.write_control(req_type, 0x07, val, interface_num as u16, &[], Duration::from_millis(100));
            }
            Ok(())
        } else {
            Err(anyhow!("USB Not Connected"))
        }
    }
    #[cfg(target_family = "wasm")]
    {
        let _ = state;
        Ok(())
    }
}

#[frb(sync)]
pub fn set_rts(state: bool) -> Result<()> {
    #[cfg(not(target_family = "wasm"))]
    {
        if let Some(handle) = USB_HANDLE.lock().unwrap().as_ref() {
            let interface_num = *INTERFACE_ID.lock().unwrap();
            let desc = handle.device().device_descriptor().unwrap();
            let is_v5_mcp2200 = desc.vendor_id() == 1240;

            if is_v5_mcp2200 {
                let req_type = request_type(Direction::Out, RequestType::Class, Recipient::Interface);
                let val = if state { 0x03 } else { 0x00 };
                let _ = handle.write_control(req_type, 0x22, val, interface_num as u16, &[], Duration::from_millis(100));
            } else {
                let req_type = request_type(Direction::Out, RequestType::Vendor, Recipient::Device);
                let val = if state { 0x0202 } else { 0x0200 };
                let _ = handle.write_control(req_type, 0x07, val, interface_num as u16, &[], Duration::from_millis(100));
            }
            Ok(())
        } else {
            Err(anyhow!("USB Not Connected"))
        }
    }
    #[cfg(target_family = "wasm")]
    {
        let _ = state;
        Ok(())
    }
}


#[frb(sync)]
pub fn push_web_data(data: Vec<u8>) {
    #[cfg(target_family = "wasm")]
    {
        if let Ok(mut buffer) = WEB_RX_BUFFER.lock() {
            buffer.extend(data);
        }
    }
    #[cfg(not(target_family = "wasm"))]
    {
        let _ = data;
    }
}

#[frb(sync)]
pub fn write_data(data: Vec<u8>) {
    #[cfg(not(target_family = "wasm"))]
    {
        if let Some(tx) = TX_QUEUE.lock().unwrap().as_ref() {
            let _ = tx.send(data);
        }
    }
    #[cfg(target_family = "wasm")]
    {
        let _ = data;

    }
}

pub fn read_data(bytes_to_read: u32, timeout_ms: u32) -> Vec<u8> {
    #[cfg(not(target_family = "wasm"))]
    {
        let handle_opt = USB_HANDLE.lock().unwrap().clone();
        let ep_in = *EP_IN.lock().unwrap();

        if let Some(handle) = handle_opt {
            let mut buf = vec![0u8; bytes_to_read as usize];
            match handle.read_bulk(ep_in, &mut buf, Duration::from_millis(timeout_ms as u64)) {
                Ok(len) => {
                    buf.truncate(len);
                    buf
                }
                Err(_) => vec![],
            }
        } else {
            vec![]
        }
    }
    #[cfg(target_family = "wasm")]
    {
        let _ = (bytes_to_read, timeout_ms);
        vec![]
    }
}
#[frb(sync)]
pub fn read_web_data(bytes_to_read: u32) -> Vec<u8> {
    #[cfg(target_family = "wasm")]
    {
        let mut result = Vec::new();
        if let Ok(mut buffer) = WEB_RX_BUFFER.lock() {
            while result.len() < bytes_to_read as usize && !buffer.is_empty() {
                if let Some(byte) = buffer.pop_front() {
                    result.push(byte);
                }
            }
        }
        result
    }
    #[cfg(not(target_family = "wasm"))]
    {
        let _ = bytes_to_read;
        vec![]
    }
}
#[frb(sync)]
pub fn close_usb() {
    #[cfg(not(target_family = "wasm"))]
    {
        *TX_QUEUE.lock().unwrap() = None;
        if let Some(handle) = USB_HANDLE.lock().unwrap().take() {
            let interface_num = *INTERFACE_ID.lock().unwrap();
            let req_type = request_type(Direction::Out, RequestType::Vendor, Recipient::Device);

            let _ = handle.write_control(req_type, 0x00, 0x0000, interface_num as u16, &[], Duration::from_millis(100));
            let _ = handle.write_control(req_type, 0x12, 0x000F, interface_num as u16, &[], Duration::from_millis(100));
            let _ = handle.release_interface(interface_num);
        }
    }
    #[cfg(target_family = "wasm")]
    {
        if let Ok(mut buffer) = WEB_RX_BUFFER.lock() {
            buffer.clear();
        }
    }
}

#[frb(sync)]
pub fn check_desktop_device_present() -> bool {
    #[cfg(not(target_family = "wasm"))]
    {
        if let Ok(devices) = rusb::devices() {
            for device in devices.iter() {
                if let Ok(desc) = device.device_descriptor() {
                    if (desc.vendor_id() == 0x10C4 && desc.product_id() == 0xEA60) ||
                       (desc.vendor_id() == 1240 && desc.product_id() == 223) {
                        return true;
                    }
                }
            }
        }
        false
    }
    #[cfg(target_family = "wasm")]
    {
        false
    }
}