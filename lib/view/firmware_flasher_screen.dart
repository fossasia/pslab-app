import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/theme/colors.dart';

import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/handler/router/platform_handler.dart';
import '../others/web_firmware_flasher.dart';
import '../others/native_firmware_flasher.dart';

enum FirmwareSource { github, local }

class FirmwareFlasherScreen extends StatefulWidget {
  const FirmwareFlasherScreen({super.key});

  @override
  State<FirmwareFlasherScreen> createState() => _FirmwareFlasherScreenState();
}

class _FirmwareFlasherScreenState extends State<FirmwareFlasherScreen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  FirmwareSource _selectedSource = FirmwareSource.github;

  bool _isFlashing = false;
  bool _isLoadingRelease = false;
  double _progress = 0.0;

  String? _statusText;

  List<GitHubRelease> _releases = [];
  GitHubRelease? _selectedRelease;
  GitHubAsset? _selectedAsset;

  String? _loadedHexContent;
  String? _loadedFileName;

  CommunicationHandler? _platformHandler;
  NativeFirmwareFlasher? _nativeFlasher;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchGitHubReleases();
    });
  }

  @override
  void dispose() {
    _nativeFlasher?.dispose();
    _platformHandler?.close();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isError ? Colors.redAccent : Colors.white)),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _fetchGitHubReleases() async {
    setState(() {
      _isLoadingRelease = true;
      _statusText = appLocalizations.flasherStatusFetching;
    });
    try {
      final url = Uri.parse(
          'https://api.github.com/repos/fossasia/pslab-firmware/releases');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        final releases = data
            .map((r) => GitHubRelease.fromJson(r as Map<String, dynamic>))
            .where((r) => r.assets.isNotEmpty)
            .toList();

        setState(() {
          _releases = releases;
          if (releases.isNotEmpty) {
            _selectedRelease = releases.first;
            _selectedAsset = _selectedRelease!.assets.firstWhere(
                (a) =>
                    !a.name.toLowerCase().contains('esp01') &&
                    !a.name.toLowerCase().contains('v5'),
                orElse: () => _selectedRelease!.assets.first);
          }
          _statusText = appLocalizations.flasherStatusReleasesLoaded;
        });

        if (_selectedAsset != null) {
          await _downloadAndPrepareAsset(_selectedAsset!);
        }
      } else {
        setState(() => _statusText = appLocalizations.flasherStatusFetchFailed);
      }
    } on TimeoutException {
      if (mounted) {
        setState(
            () => _statusText = appLocalizations.flasherStatusNetworkTimeout);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusText = appLocalizations.flasherStatusNetworkError);
    } finally {
      if (mounted) setState(() => _isLoadingRelease = false);
    }
  }

  Future<void> _downloadAndPrepareAsset(GitHubAsset asset) async {
    setState(() {
      _isLoadingRelease = true;
      _statusText =
          "${appLocalizations.flasherStatusDownloading}${asset.name}...";
    });
    try {
      Uri downloadUri = Uri.parse(asset.downloadUrl);
      if (kIsWeb) {
        downloadUri = Uri.parse(
            'https://api.codetabs.com/v1/proxy/?quest=${asset.downloadUrl}');
      }

      final response =
          await http.get(downloadUri).timeout(const Duration(seconds: 15));

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
            final bytes = hexFile.content as List<int>;
            _loadedHexContent = utf8.decode(bytes);
            _loadedFileName = "${asset.name} (${hexFile.name})";
          } else {
            throw Exception(appLocalizations.flasherStatusInvalidFirmware);
          }
        }
        setState(() {
          _statusText =
              "${appLocalizations.flasherStatusReadyToFlash}$_loadedFileName";
          _progress = 0.0;
        });
      } else {
        setState(
            () => _statusText = appLocalizations.flasherStatusDownloadFailed);
      }
    } on TimeoutException {
      if (mounted) {
        setState(
            () => _statusText = appLocalizations.flasherStatusDownloadTimeout);
      }
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _statusText = appLocalizations.flasherStatusInvalidFirmware);
    } finally {
      if (mounted) setState(() => _isLoadingRelease = false);
    }
  }

  Future<void> _pickLocalFile() async {
    try {
      final platformFile = await FilePicker.pickFile(
          type: FileType.custom, allowedExtensions: ['hex']);
      if (platformFile != null) {
        String? content;
        if (kIsWeb) {
          final bytes = await platformFile.readAsBytes();
          content = utf8.decode(bytes);
        } else {
          if (platformFile.path != null) {
            final hexFile = File(platformFile.path!);
            content = await hexFile.readAsString();
          }
        }
        if (content != null) {
          if (!mounted) return;
          setState(() {
            _loadedHexContent = content;
            _loadedFileName = platformFile.name;
            _statusText =
                "${appLocalizations.flasherStatusLocalFileSelected}$_loadedFileName";
            _progress = 0.0;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(appLocalizations.flasherErrorLocalFileRead, isError: true);
    }
  }

  void _startFlashing() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _showSnackBar(appLocalizations.flasherErrorIOSNotSupported,
          isError: true);
      return;
    }

    if (_loadedHexContent == null || _loadedHexContent!.isEmpty) {
      _showSnackBar(appLocalizations.flasherErrorSelectFirmwareFirst,
          isError: true);
      return;
    }

    setState(() {
      _isFlashing = true;
      _progress = 0.02;
      _statusText = appLocalizations.flasherStatusCheckingUSB;
    });

    try {
      _platformHandler?.close();

      _platformHandler = getPlatformHandler();
      await _platformHandler!.initialize();

      if (kIsWeb) {
        setState(
            () => _statusText = appLocalizations.flasherStatusSelectBoardPopup);
        await _platformHandler!.open(overrideBaud: 460800);
      } else {
        if (!_platformHandler!.isDeviceFound()) {
          throw Exception(appLocalizations.flasherErrorNoDeviceFound);
        }
        _nativeFlasher = NativeFirmwareFlasher(
          handler: _platformHandler!,
          onProgress: (prog, stat) {
            if (mounted) {
              setState(() {
                _progress = prog;
                _statusText = stat;
              });
            }
          },
          onSuccess: () {
            if (mounted) {
              setState(() {
                _isFlashing = false;
              });
            }
          },
          onError: (err) {
            if (mounted) {
              setState(() {
                _statusText = appLocalizations.flasherErrorFlashingInterrupted;
                _isFlashing = false;
              });
            }
          },
        );
        await _nativeFlasher!.preparePort();
      }
    } catch (e) {
      if (!mounted) return;
      _platformHandler?.close();
      _showSnackBar(appLocalizations.flasherErrorNoPSLabDetected,
          isError: true);
      setState(() {
        _statusText = appLocalizations.flasherStatusConnectionFailed;
        _isFlashing = false;
        _progress = 0;
      });
      return;
    }

    if (!mounted) return;

    bool? readyToFlash = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.flasherBootloaderTitle,
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold)),
          content: Text(appLocalizations.flasherBootloaderContent),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(appLocalizations.flasherBtnCancel,
                    style: const TextStyle(color: Colors.grey))),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed, foregroundColor: Colors.white),
                child: Text(appLocalizations.flasherBtnContinue,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        );
      },
    );

    if (readyToFlash != true) {
      _platformHandler?.close();
      setState(() {
        _statusText = appLocalizations.flasherStatusCancelled;
        _isFlashing = false;
        _progress = 0;
      });
      return;
    }

    setState(() {
      _statusText = appLocalizations.flasherStatusInitBootloader;
    });

    if (kIsWeb) {
      try {
        final webFlasher = WebFirmwareFlasher(
          handler: _platformHandler!,
          onProgress: (prog, stat) {
            if (mounted) {
              setState(() {
                _progress = prog;
                _statusText = stat;
              });
            }
          },
        );
        await webFlasher.flashFirmware(_loadedHexContent!);
        if (mounted) {
          setState(() {
            _statusText = appLocalizations.flasherStatusSuccess;
            _progress = 1.0;
            _isFlashing = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _statusText = appLocalizations.flasherStatusUSBLost;
            _isFlashing = false;
          });
        }
      } finally {
        _platformHandler?.close();
      }
    } else {
      _nativeFlasher!.startFlashing(_loadedHexContent!);
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
              borderRadius: BorderRadius.circular(6)),
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
              child: Text(title.toUpperCase(),
                  style: TextStyle(
                      color: primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentStatus = _statusText ?? appLocalizations.flasherStatusReady;

    return CommonScaffold(
      title: appLocalizations.flasherTitle,
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOutlinedBox(
                title: appLocalizations.flasherInstructionsTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepText(appLocalizations.flasherInstStep1),
                    _StepText(appLocalizations.flasherInstStep2),
                    _StepText(appLocalizations.flasherInstStep3),
                    _StepText(appLocalizations.flasherInstStep4),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildOutlinedBox(
                title: appLocalizations.flasherSourceTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<FirmwareSource>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: Colors.red[50],
                          selectedForegroundColor: primaryRed),
                      segments: [
                        ButtonSegment(
                            value: FirmwareSource.github,
                            icon:
                                const FaIcon(FontAwesomeIcons.github, size: 18),
                            label: Text(appLocalizations.flasherSourceGithub)),
                        ButtonSegment(
                            value: FirmwareSource.local,
                            icon: const Icon(Icons.folder_open),
                            label: Text(appLocalizations.flasherSourceLocal)),
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
                title: appLocalizations.flasherStatusTitle,
                child: Column(
                  children: [
                    if (_loadedFileName != null) ...[
                      Text("${appLocalizations.flasherTarget}$_loadedFileName",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12)
                    ],
                    Text(currentStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: currentStatus.contains("error") ||
                                    currentStatus.contains("Failed") ||
                                    currentStatus.contains("failed")
                                ? primaryRed
                                : Colors.black)),
                    const SizedBox(height: 12),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 12,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _progress == 1.0
                                    ? Colors.green
                                    : Colors.redAccent))),
                    const SizedBox(height: 6),
                    Align(
                        alignment: Alignment.centerRight,
                        child: Text("${(_progress * 100).toInt()}%",
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6))),
                onPressed: _isFlashing ? null : _startFlashing,
                child: _isFlashing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(appLocalizations.flasherBtnStartFlash,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
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
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator()))
        else if (_releases.isEmpty)
          Text(appLocalizations.flasherNoReleaseFound,
              textAlign: TextAlign.center)
        else ...[
          Text(appLocalizations.flasherSelectVersion,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<GitHubRelease>(
                value: _selectedRelease,
                isExpanded: true,
                items: _releases.map((release) {
                  return DropdownMenuItem(
                      value: release,
                      child: Text(release.tagName,
                          style: const TextStyle(color: Colors.black)));
                }).toList(),
                onChanged: _isFlashing
                    ? null
                    : (val) {
                        setState(() {
                          _selectedRelease = val;
                          if (val != null && val.assets.isNotEmpty) {
                            _selectedAsset = val.assets.firstWhere(
                                (a) =>
                                    !a.name.toLowerCase().contains('esp01') &&
                                    !a.name.toLowerCase().contains('v5'),
                                orElse: () => val.assets.first);
                          } else {
                            _selectedAsset = null;
                          }
                          _loadedHexContent = null;
                          _loadedFileName = null;
                        });
                        if (_selectedAsset != null) {
                          _downloadAndPrepareAsset(_selectedAsset!);
                        }
                      },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(appLocalizations.flasherSelectVariant,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(height: 8),
          if (_selectedRelease != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(6)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<GitHubAsset>(
                  value: _selectedAsset,
                  isExpanded: true,
                  items: _selectedRelease!.assets.map((asset) {
                    String label = asset.name;
                    String nameLower = asset.name.toLowerCase();

                    if (nameLower.contains('esp01')) {
                      label =
                          "${appLocalizations.flasherVariantESP}${asset.name}";
                    } else if (nameLower.contains('v5')) {
                      label =
                          "${appLocalizations.flasherVariantLegacy}${asset.name}";
                    } else {
                      label =
                          "${appLocalizations.flasherVariantStandard}${asset.name}";
                    }

                    return DropdownMenuItem(
                        value: asset,
                        child: Text(label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black)));
                  }).toList(),
                  onChanged: _isFlashing
                      ? null
                      : (val) {
                          setState(() {
                            _selectedAsset = val;
                            _loadedHexContent = null;
                            _loadedFileName = null;
                          });
                          if (val != null) _downloadAndPrepareAsset(val);
                        },
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (_selectedAsset != null && _loadedHexContent == null)
            OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: Text(appLocalizations.flasherBtnDownloadHex),
                onPressed: () => _downloadAndPrepareAsset(_selectedAsset!)),
        ],
      ],
    );
  }

  Widget _buildLocalFilePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(appLocalizations.flasherLocalFileDesc,
            style: const TextStyle(fontSize: 13, color: Colors.black),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: primaryRed),
              foregroundColor: primaryRed),
          icon: const Icon(Icons.folder_open),
          label: Text(appLocalizations.flasherBtnBrowseFile,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _isFlashing ? null : _pickLocalFile,
        ),
      ],
    );
  }
}

class GitHubAsset {
  final String name;
  final String downloadUrl;
  final int size;

  GitHubAsset(
      {required this.name, required this.downloadUrl, required this.size});

  factory GitHubAsset.fromJson(Map<String, dynamic> json) {
    return GitHubAsset(
      name: json['name'] ?? '',
      downloadUrl: json['browser_download_url'] ?? '',
      size: json['size'] ?? 0,
    );
  }
}

class GitHubRelease {
  final String tagName;
  final List<GitHubAsset> assets;

  GitHubRelease({required this.tagName, required this.assets});

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final List rawAssets = json['assets'] ?? [];

    final assets = rawAssets
        .map((a) => GitHubAsset.fromJson(a))
        .where((a) => a.name.endsWith('.zip') || a.name.endsWith('.hex'))
        .toList();

    return GitHubRelease(
      tagName: json['tag_name'] ?? 'Unknown',
      assets: assets,
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
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("• ",
              style: TextStyle(
                  color: primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, height: 1.3, color: Colors.black)))
        ]));
  }
}
