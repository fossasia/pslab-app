import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pslab/src/rust/api/bootloader.dart';
import 'package:pslab/src/rust/api/simple.dart' as rust_api;
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/theme/colors.dart';

enum FirmwareSource { github, local }

class GitHubAsset {
  final String name;
  final String downloadUrl;
  final int size;

  GitHubAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  factory GitHubAsset.fromJson(Map<String, dynamic> json) {
    return GitHubAsset(
      name: json['name'] ?? '',
      downloadUrl: json['browser_download_url'] ?? '',
      size: json['size'] ?? 0,
    );
  }
}

class FirmwareFlasherScreen extends StatefulWidget {
  const FirmwareFlasherScreen({super.key});

  @override
  State<FirmwareFlasherScreen> createState() => _FirmwareFlasherScreenState();
}

class _FirmwareFlasherScreenState extends State<FirmwareFlasherScreen> {
  FirmwareSource _selectedSource = FirmwareSource.github;

  bool _isDeviceConnected = false;
  bool _isFlashing = false;
  bool _isLoadingRelease = false;
  double _progress = 0.0;
  String _statusText = "Ready";

  StreamSubscription<FlashState>? _flashingSubscription;

  List<GitHubAsset> _releaseAssets = [];
  GitHubAsset? _selectedAsset;

  String? _loadedHexContent;
  String? _loadedFileName;

  @override
  void initState() {
    super.initState();
    _checkDeviceConnection();
    _fetchLatestGitHubRelease();
  }

  @override
  void dispose() {
    _flashingSubscription?.cancel();
    super.dispose();
  }

  void _checkDeviceConnection() {
    try {
      final isPresent = rust_api.checkDesktopDevicePresent();
      if (!mounted) return;
      setState(() {
        _isDeviceConnected = isPresent;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDeviceConnected = true;
      });
    }
  }

  Future<void> _fetchLatestGitHubRelease() async {
    setState(() {
      _isLoadingRelease = true;
      _statusText = "Fetching releases from GitHub...";
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/fossasia/pslab-firmware/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tagName = data['tag_name'] ?? 'Latest';
        final List rawAssets = data['assets'] ?? [];

        final assets = rawAssets
            .map((a) => GitHubAsset.fromJson(a))
            .where((a) =>
        (a.name.endsWith('.zip') || a.name.endsWith('.hex')) &&
            a.name.toLowerCase().contains('v6')
        )
            .toList();

        setState(() {
          _releaseAssets = assets;
          if (assets.isNotEmpty) {
            _selectedAsset = assets.firstWhere(
                  (a) => a.name.contains('v6') && !a.name.contains('esp01'),
              orElse: () => assets.first,
            );
          }
          _statusText = "Release $tagName loaded.";
        });

        if (_selectedAsset != null) {
          await _downloadAndPrepareAsset(_selectedAsset!);
        }
      } else {
        setState(() {
          _statusText = "Failed to fetch release (Status: ${response.statusCode})";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = "GitHub API Error: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRelease = false;
        });
      }
    }
  }

  Future<void> _downloadAndPrepareAsset(GitHubAsset asset) async {
    setState(() {
      _isLoadingRelease = true;
      _statusText = "Downloading ${asset.name}...";
    });

    try {
      final response = await http.get(Uri.parse(asset.downloadUrl));
      if (!mounted) return;

      if (response.statusCode == 200) {
        if (asset.name.endsWith('.hex')) {
          _loadedHexContent = utf8.decode(response.bodyBytes);
          _loadedFileName = asset.name;
        } else if (asset.name.endsWith('.zip')) {
          final archive = ZipDecoder().decodeBytes(response.bodyBytes);
          ArchiveFile? hexFile;

          for (final file in archive) {
            if (file.isFile && file.name.endsWith('.hex')) {
              hexFile = file;
              break;
            }
          }

          if (hexFile != null) {
            _loadedHexContent = utf8.decode(hexFile.content as List<int>);
            _loadedFileName = "${asset.name} (${hexFile.name})";
          } else {
            throw Exception("No .hex file found inside ${asset.name}");
          }
        }

        setState(() {
          _statusText = "Ready to flash: $_loadedFileName";
          _progress = 0.0;
        });
      } else {
        setState(() {
          _statusText = "Download failed: ${response.statusCode}";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = "Error preparing firmware: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRelease = false;
        });
      }
    }
  }

  Future<void> _pickLocalFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['hex'],
      );

      if (file != null && file.path != null) {
        final hexFile = File(file.path!);
        final content = await hexFile.readAsString();

        if (!mounted) return;
        setState(() {
          _loadedHexContent = content;
          _loadedFileName = file.name;
          _statusText = "Selected local file: $_loadedFileName";
          _progress = 0.0;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file: $e")),
      );
    }
  }

  void _startFlashing() async {
    if (!_isDeviceConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PSLab not detected. Please plug it in and tap the refresh icon at the top right."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_loadedHexContent == null || _loadedHexContent!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select or download firmware first.")),
      );
      return;
    }

    setState(() {
      _isFlashing = true;
      _progress = 0.02;
      _statusText = "Initializing bootloader...";
    });

    try {
      _flashingSubscription?.cancel();
      _flashingSubscription = flashFirmware(hexStr: _loadedHexContent!).listen(
            (state) {
          if (!mounted) return;
          setState(() {
            if (state is FlashState_Connecting) {
              _statusText = "Connecting at 460800 baud...";
              _progress = 0.05;
            } else if (state is FlashState_Erasing) {
              _statusText = "Erasing Flash Memory...";
              _progress = 0.20;
            } else if (state is FlashState_Writing) {
              _statusText = "Writing Flash: ${state.progressPercent}%";
              _progress = 0.20 + (state.progressPercent / 100.0 * 0.70);
            } else if (state is FlashState_Verifying) {
              _statusText = "Verifying On-Board Checksum...";
              _progress = 0.95;
            } else if (state is FlashState_Finished) {
              _statusText = "Flashing Successful! Reset or power cycle the device.";
              _progress = 1.0;
              _isFlashing = false;
            } else if (state is FlashState_Error) {
              _statusText = "Error: ${state.message}";
              _isFlashing = false;
            }
          });
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _statusText = "Flashing failed: $err";
            _isFlashing = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = "Error starting flash: $e";
        _isFlashing = false;
      });
    }
  }

  Widget _buildOutlinedBox({required String title, required Widget child}) {
    const Color boxColor = Colors.white;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16).copyWith(top: 24),
          decoration: BoxDecoration(
            color: boxColor,
            border: Border.all(color: primaryRed, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: child,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 1,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: const BoxDecoration(color: boxColor),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: primaryRed,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: "Firmware Update",
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: "Refresh Connection",
          onPressed: _isFlashing
              ? null
              : () {
            _checkDeviceConnection();
            _fetchLatestGitHubRelease();
          },
        ),
      ],
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isDeviceConnected ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isDeviceConnected ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isDeviceConnected ? Icons.usb : Icons.usb_off,
                        color: _isDeviceConnected ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isDeviceConnected ? "Connected" : "Not Detected",
                        style: TextStyle(
                          color: _isDeviceConnected ? Colors.green[800] : Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildOutlinedBox(
                title: "Instructions",
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepText("1. Plug the PSLab board with USB"),
                    _StepText("2. Press and hold the 'BOOT' button"),
                    _StepText("3. Press the 'RESET' button"),
                    _StepText("4. The 'Status' LED should start blinking, indicating bootloader mode"),
                    _StepText("5. Release the 'BOOT' button"),
                    _StepText("6. Click on START FLASH below"),
                    _StepText("7. After flashing is complete, reset or power cycle the device"),
                    _StepText("8. Note: Only V6 and above is compatible for flashing"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildOutlinedBox(
                title: "Firmware Source",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<FirmwareSource>(
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: Colors.red[50],
                        selectedForegroundColor: primaryRed,
                      ),
                      segments: const [
                        ButtonSegment(
                          value: FirmwareSource.github,
                          icon: Icon(Icons.cloud_download),
                          label: Text("GitHub Releases"),
                        ),
                        ButtonSegment(
                          value: FirmwareSource.local,
                          icon: Icon(Icons.folder_open),
                          label: Text("Local File"),
                        ),
                      ],
                      selected: {_selectedSource},
                      onSelectionChanged: _isFlashing
                          ? null
                          : (set) {
                        setState(() {
                          _selectedSource = set.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedSource == FirmwareSource.github)
                      _buildGitHubPanel()
                    else
                      _buildLocalFilePanel(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildOutlinedBox(
                title: "Flashing Status",
                child: Column(
                  children: [
                    if (_loadedFileName != null) ...[
                      Text(
                        "Target: $_loadedFileName",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _statusText.contains("Error") ? primaryRed : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _progress == 1.0 ? Colors.green : Colors.redAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${(_progress * 100).toInt()}%",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: (_isFlashing || _loadedHexContent == null) ? null : _startFlashing,
                child: _isFlashing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  "START FLASH",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGitHubPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoadingRelease)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
        else if (_releaseAssets.isEmpty)
          const Text("No firmware release assets found.", textAlign: TextAlign.center)
        else ...[
            const Text("Select Hardware Variant:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<GitHubAsset>(
                  value: _selectedAsset,
                  isExpanded: true,
                  items: _releaseAssets.map((asset) {
                    String label = asset.name;
                    if (asset.name.contains('v6_esp01')) {
                      label = "PSLab V6 (with ESP-01 Wi-Fi)";
                    } else if (asset.name.contains('v6')) {
                      label = "PSLab V6 (Standard)";
                    }
                    return DropdownMenuItem(value: asset, child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black)));
                  }).toList(),
                  onChanged: _isFlashing
                      ? null
                      : (val) {
                    setState(() {
                      _selectedAsset = val;
                      _loadedHexContent = null;
                      _loadedFileName = null;
                    });
                    if (val != null) {
                      _downloadAndPrepareAsset(val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedAsset != null && _loadedHexContent == null)
              OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text("Download HEX"),
                onPressed: () => _downloadAndPrepareAsset(_selectedAsset!),
              ),
          ],
      ],
    );
  }

  Widget _buildLocalFilePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Select a pre-compiled .hex file from device storage.",
          style: TextStyle(fontSize: 13, color: Colors.black),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(color: primaryRed),
            foregroundColor: primaryRed,
          ),
          icon: const Icon(Icons.folder_open),
          label: const Text("BROWSE FILE", style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _isFlashing ? null : _pickLocalFile,
        ),
      ],
    );
  }
}

class _StepText extends StatelessWidget {
  final String text;
  const _StepText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}