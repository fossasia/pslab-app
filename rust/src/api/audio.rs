use anyhow::Result;
use crate::frb_generated::StreamSink;
#[flutter_rust_bridge::frb(ignore)]
#[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
mod desktop_audio {
    use super::*;
    use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
    use std::sync::{Mutex, OnceLock};
    use std::sync::mpsc::{self, Sender};

    static STOP_SENDER: OnceLock<Mutex<Option<Sender<()>>>> = OnceLock::new();

    fn get_stop_sender() -> &'static Mutex<Option<Sender<()>>> {
        STOP_SENDER.get_or_init(|| Mutex::new(None))
    }

    pub fn stop_microphone() {
        let mut sender_guard = get_stop_sender().lock().unwrap();
        if let Some(sender) = sender_guard.take() {
            let _ = sender.send(());
        }
    }

    pub fn start_microphone(sink: StreamSink<Vec<f64>>) -> Result<()> {
        stop_microphone();
        let (stop_tx, stop_rx) = mpsc::channel();
        let (init_tx, init_rx) = mpsc::channel();

        {
            let mut sender_guard = get_stop_sender().lock().unwrap();
            *sender_guard = Some(stop_tx);
        }

        std::thread::spawn(move || {
            let host = cpal::default_host();
            let device = match host.default_input_device() {
                Some(d) => d,
                None => {
                    let _ = init_tx.send(Err(anyhow::anyhow!("No microphone found")));
                    return;
                }
            };

            let config = match device.default_input_config() {
                Ok(c) => c,
                Err(e) => {
                    let _ = init_tx.send(Err(anyhow::anyhow!("Failed to get default input config: {}", e)));
                    return;
                }
            };

            let channels = config.channels() as usize;
            let sample_format = config.sample_format();
            let stream_config: cpal::StreamConfig = config.into();

            let stream_result = match sample_format {
                cpal::SampleFormat::I16 => device.build_input_stream(
                    &stream_config,
                    move |data: &[i16], _| {
                        let f64_data: Vec<f64> = data
                            .iter()
                            .step_by(channels)
                            .map(|&s| s as f64 / 32768.0)
                            .collect();
                        let _ = sink.add(f64_data);
                    },
                    |err| eprintln!("Stream error: {}", err),
                    None,
                ),
                cpal::SampleFormat::F32 => device.build_input_stream(
                    &stream_config,
                    move |data: &[f32], _| {
                        let f64_data: Vec<f64> = data
                            .iter()
                            .step_by(channels)
                            .map(|&s| s as f64)
                            .collect();
                        let _ = sink.add(f64_data);
                    },
                    |err| eprintln!("Stream error: {}", err),
                    None,
                ),
                _ => {
                    let _ = init_tx.send(Err(anyhow::anyhow!("Unsupported sample format")));
                    return;
                }
            };

            match stream_result {
                Ok(stream) => {
                    if let Err(e) = stream.play() {
                        let _ = init_tx.send(Err(anyhow::anyhow!("Failed to play stream: {}", e)));
                        return;
                    }
                    let _ = init_tx.send(Ok(()));
                    let _ = stop_rx.recv();
                }
                Err(e) => {
                    let _ = init_tx.send(Err(anyhow::anyhow!("Failed to build input stream: {}", e)));
                }
            }
        });
        match init_rx.recv() {
            Ok(Ok(())) => Ok(()),
            Ok(Err(e)) => Err(e),
            Err(_) => Err(anyhow::anyhow!("Audio thread panicked during initialization")),
        }
    }
}

pub fn stop_microphone() {
    #[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
    desktop_audio::stop_microphone();
}

pub fn start_microphone(sink: StreamSink<Vec<f64>>) -> Result<()> {
    #[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
    {
        desktop_audio::start_microphone(sink)
    }

    #[cfg(not(any(target_os = "windows", target_os = "linux", target_os = "macos")))]
    {

        Err(anyhow::anyhow!("Audio is only configured for desktop platforms."))
    }
}