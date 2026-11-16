import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/board_state_provider.dart';
import 'package:pslab/hal/labrador_board.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/theme/colors.dart';

import 'package:pslab/communication/handler/base.dart';
import 'package:pslab/communication/pslab_communication/platform_handler.dart';
import '../others/web_firmware_flasher.dart';
import '../others/native_firmware_flasher.dart';
import '../others/labrador_firmware_flasher.dart';

enum FirmwareSource { github, local }

enum LabradorFirmwareSource { builtin, local }

class FirmwareFlasherScreen extends StatefulWidget {
  const FirmwareFlasherScreen({super.key});

  @override
  State<FirmwareFlasherScreen> createState() => _FirmwareFlasherScreenState();
}

class _FirmwareFlasherScreenState extends State<FirmwareFlasherScreen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  String _selectedTarget = 'PSLab';

  FirmwareSource _selectedSource = FirmwareSource.github;
  List<GitHubRelease> _releases = [];
  GitHubRelease? _selectedRelease;
  GitHubAsset? _selectedAsset;

  LabradorFirmwareSource _selectedLabradorSource =
      LabradorFirmwareSource.builtin;
  static const String _defaultLabradorHex = 'labrafirm_000c_03.hex';
  String _selectedLabradorHex = _defaultLabradorHex;
  final Map<String, String> _labradorFirmwareDescriptions = {
    'labrafirm_000c_03.hex':
        'Variant 03 (Bulk USB Transfer - Recommended for high-speed streaming in this app)',
    'labrafirm_0007_01.hex': 'Variant 01 (Legacy Isochronous Streaming)',
    'labrafirm_0007_02.hex': 'Variant 02 (Legacy Isochronous Streaming)',
  };

  bool _isFlashing = false;
  bool _isLoadingRelease = false;
  double _progress = 0.0;
  String? _statusText;

  String? _loadedHexContent;
  String? _loadedFileName;

  CommunicationHandler? _platformHandler;
  NativeFirmwareFlasher? _nativeFlasher;

  @override
  void initState() {
    super.initState();
    final boardState = getIt.get<BoardStateProvider>();
    if (boardState.isLabrador) {
      _selectedTarget = 'EspoTek Labrador';
    } else {
      _selectedTarget = 'PSLab';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedTarget == 'EspoTek Labrador') {
        _selectBuiltInLabradorFirmware(_selectedLabradorHex);
      } else {
        _fetchGitHubReleases();
      }
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

  void _onTargetChanged(String newTarget) async {
    setState(() {
      _selectedTarget = newTarget;
      _loadedHexContent = null;
      _loadedFileName = null;
      _progress = 0.0;
    });

    if (newTarget == 'EspoTek Labrador') {
      await _selectBuiltInLabradorFirmware(_selectedLabradorHex);
    } else {
      if (_releases.isEmpty) {
        await _fetchGitHubReleases();
      } else if (_selectedAsset != null) {
        await _downloadAndPrepareAsset(_selectedAsset!);
      } else {
        setState(() => _statusText = appLocalizations.flasherStatusReady);
      }
    }
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

  Future<void> _selectBuiltInLabradorFirmware(String assetFileName) async {
    setState(() {
      _isLoadingRelease = true;
      _statusText =
          "${appLocalizations.flasherLoadingBuiltin}$assetFileName...";
    });
    try {
      final hexData =
          await rootBundle.loadString('assets/firmware/$assetFileName');
      if (!mounted) return;
      setState(() {
        _selectedLabradorHex = assetFileName;
        _loadedHexContent = hexData;
        _loadedFileName = assetFileName;
        _statusText =
            "${appLocalizations.flasherStatusReadyToFlash}$assetFileName";
        _progress = 0.0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = "${appLocalizations.flasherFailedLoadBuiltin}$e";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingRelease = false);
      }
    }
  }

  Future<void> _jumpConnectedLabradorToBootloader(
      BoardStateProvider provider) async {
    try {
      _showSnackBar(appLocalizations.flasherSendingBootloaderJump);
      final board = provider.activeBoard;
      if (board is LabradorHardwareBoard) {
        await board.jumpToBootloader();
      }
      _showSnackBar(appLocalizations.flasherLabradorSwitchedBootloader);
      setState(() {
        _statusText = appLocalizations.flasherLabradorInBootloaderReady;
      });
    } catch (e) {
      _showSnackBar("${appLocalizations.flasherErrorSwitchingBootloader}$e",
          isError: true);
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

  void _onStartFlashingPressed() {
    if (_selectedTarget == 'EspoTek Labrador') {
      _startFlashingLabrador();
    } else {
      _startFlashingPslab();
    }
  }

  void _startFlashingPslab() async {
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

  void _startFlashingLabrador() async {
    if (_loadedHexContent == null || _loadedHexContent!.isEmpty) {
      _showSnackBar(appLocalizations.flasherErrorSelectFirmwareFirst,
          isError: true);
      return;
    }

    bool? ready = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.flasherLabradorDialogTitle,
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(
            "${appLocalizations.flasherLabradorDialogContent}\n\n$_loadedFileName"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appLocalizations.flasherBtnCancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed, foregroundColor: Colors.white),
            child: Text(appLocalizations.flasherBtnContinue,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ready != true) return;

    setState(() {
      _isFlashing = true;
      _progress = 0.05;
      _statusText = appLocalizations.flasherInitiatingLabrador;
    });

    final flasher = LabradorFirmwareFlasher(
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
            _progress = 1.0;
          });
          _showSnackBar(appLocalizations.flasherLabradorSuccess);
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isFlashing = false;
            _statusText = "${appLocalizations.flasherLabradorFailed}$err";
          });
          _showSnackBar(err, isError: true);
        }
      },
    );

    await flasher.flashFirmware(
      hexContent: _loadedHexContent!,
      hexFileName: _loadedFileName,
    );
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

  Widget _buildTargetSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryRed, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.developer_board, color: primaryRed, size: 22),
              const SizedBox(width: 10),
              Text(
                appLocalizations.flasherTargetDevice,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryRed, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTarget,
                icon: Icon(Icons.arrow_drop_down, color: primaryRed, size: 22),
                isDense: true,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'PSLab',
                    child: Text('PSLab V6'),
                  ),
                  DropdownMenuItem(
                    value: 'EspoTek Labrador',
                    child: Text('EspoTek Labrador'),
                  ),
                ],
                onChanged: _isFlashing
                    ? null
                    : (val) {
                        if (val != null && val != _selectedTarget) {
                          _onTargetChanged(val);
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabradorInstructions() {
    return _buildOutlinedBox(
      title: appLocalizations.flasherLabradorInstructionsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepText(appLocalizations.flasherLabradorStepMethodA),
          _StepText(appLocalizations.flasherLabradorStepPlugUSB),
          _StepText(appLocalizations.flasherLabradorStepMethodB),
          _StepText(appLocalizations.flasherLabradorStepEnumerate),
          _StepText(appLocalizations.flasherLabradorStepSelectVariant),
          Consumer<BoardStateProvider>(
            builder: (context, provider, _) {
              if (provider.isLabrador && provider.pslabIsConnected) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryRed,
                      side: BorderSide(color: primaryRed),
                    ),
                    icon: const Icon(Icons.restart_alt),
                    label: Text(
                      appLocalizations.flasherBtnJumpBootloader,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isFlashing
                        ? null
                        : () => _jumpConnectedLabradorToBootloader(provider),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabradorSourcePanel() {
    return _buildOutlinedBox(
      title: appLocalizations.flasherSourceTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<LabradorFirmwareSource>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Colors.red[50],
                selectedForegroundColor: primaryRed),
            segments: [
              ButtonSegment(
                value: LabradorFirmwareSource.builtin,
                icon: const Icon(Icons.memory, size: 18),
                label: Text(appLocalizations.flasherBuiltinFirmware),
              ),
              ButtonSegment(
                value: LabradorFirmwareSource.local,
                icon: const Icon(Icons.folder_open, size: 18),
                label: Text(appLocalizations.flasherCustomFile),
              ),
            ],
            selected: {_selectedLabradorSource},
            onSelectionChanged: _isFlashing
                ? null
                : (set) {
                    setState(() {
                      _selectedLabradorSource = set.first;
                    });
                    if (set.first == LabradorFirmwareSource.builtin) {
                      _selectBuiltInLabradorFirmware(_selectedLabradorHex);
                    } else {
                      _loadedHexContent = null;
                      _loadedFileName = null;
                      _statusText = appLocalizations.flasherSelectCustomHex;
                    }
                  },
          ),
          const SizedBox(height: 16),
          if (_selectedLabradorSource == LabradorFirmwareSource.builtin) ...[
            Text(appLocalizations.flasherSelectFirmwareVariant,
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
                child: DropdownButton<String>(
                  value: _selectedLabradorHex,
                  isExpanded: true,
                  items: _labradorFirmwareDescriptions.keys.map((fname) {
                    final bool isBulk = fname.contains("000c_03");
                    return DropdownMenuItem(
                      value: fname,
                      child: Text(
                        isBulk
                            ? "$fname${appLocalizations.flasherBulkStreamingRecommended}"
                            : fname,
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight:
                                isBulk ? FontWeight.bold : FontWeight.normal),
                      ),
                    );
                  }).toList(),
                  onChanged: _isFlashing
                      ? null
                      : (val) {
                          if (val != null) {
                            _selectBuiltInLabradorFirmware(val);
                          }
                        },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _labradorFirmwareDescriptions[_selectedLabradorHex] ?? "",
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                          height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildLocalFilePanel(),
          ],
        ],
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
              _buildTargetSelector(),
              const SizedBox(height: 16),
              if (_selectedTarget == 'EspoTek Labrador')
                _buildLabradorInstructions()
              else
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
              if (_selectedTarget == 'EspoTek Labrador')
                _buildLabradorSourcePanel()
              else
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
                              icon: const FaIcon(FontAwesomeIcons.github,
                                  size: 18),
                              label:
                                  Text(appLocalizations.flasherSourceGithub)),
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
                onPressed: _isFlashing ? null : _onStartFlashingPressed,
                child: _isFlashing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        _selectedTarget == 'EspoTek Labrador'
                            ? "Flash Labrador Firmware"
                            : appLocalizations.flasherBtnStartFlash,
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
