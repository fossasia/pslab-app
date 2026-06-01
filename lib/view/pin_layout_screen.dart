import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pslab/view/widgets/main_scaffold_widget.dart';

import '../models/pin_details.dart';
import '../theme/colors.dart';

enum BoardVersion { v6, v5 }

class PSLabPinLayoutScreen extends StatefulWidget {
  final bool initialIsFrontSide;

  const PSLabPinLayoutScreen({
    super.key,
    this.initialIsFrontSide = true,
  });

  @override
  State<PSLabPinLayoutScreen> createState() => _PSLabPinLayoutScreenState();
}

class _PSLabPinLayoutScreenState extends State<PSLabPinLayoutScreen> {
  BoardVersion currentVersion = BoardVersion.v6;
  late bool isFrontSide;

  ByteData? _colorMapPixels;
  int _colorMapWidth = 0;
  int _colorMapHeight = 0;

  final GlobalKey _imageKey = GlobalKey();
  List<PinDetails> _pinDetails = [];

  static final Map<String, Map<String, dynamic>> _nativeCache = {};

  @override
  void initState() {
    super.initState();
    isFrontSide = widget.initialIsFrontSide;

    Future.microtask(() => _loadColorMap());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePinDetailsList();
  }

  void _updatePinDetailsList() {
    setState(() {
      if (currentVersion == BoardVersion.v6) {
        _pinDetails = PinDetails.getV6Pins(context);
      } else {
        _pinDetails = PinDetails.getV5Pins(context);
      }
    });
  }

  Future<void> _loadColorMap() async {
    String colormapPath = _currentColormapImagePath;
    String layoutPath = _currentLayoutImagePath;
    if (mounted) {
      precacheImage(AssetImage(layoutPath), context);
    }

    if (_nativeCache.containsKey(colormapPath)) {
      setState(() {
        _colorMapPixels = _nativeCache[colormapPath]!['pixels'];
        _colorMapWidth = _nativeCache[colormapPath]!['width'];
        _colorMapHeight = _nativeCache[colormapPath]!['height'];
      });
      return;
    }

    try {
      final ByteData data = await rootBundle.load(colormapPath);
      final Uint8List bytes = data.buffer.asUint8List();

      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 400,
      );

      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image nativeImage = frameInfo.image;

      final ByteData? rawPixels =
          await nativeImage.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (mounted && rawPixels != null) {
        _nativeCache[colormapPath] = {
          'pixels': rawPixels,
          'width': nativeImage.width,
          'height': nativeImage.height,
        };

        setState(() {
          _colorMapPixels = rawPixels;
          _colorMapWidth = nativeImage.width;
          _colorMapHeight = nativeImage.height;
        });
      }
    } catch (e) {
      log("Error natively decoding colormap: $e");
    }
  }

  void _handleTap(TapUpDetails details) {
    if (_colorMapPixels == null) return;

    final RenderBox renderBox =
        _imageKey.currentContext!.findRenderObject() as RenderBox;
    final Size renderedSize = renderBox.size;
    final Offset localPosition = details.localPosition;

    double scaleX = _colorMapWidth / renderedSize.width;
    double scaleY = _colorMapHeight / renderedSize.height;

    int pixelX = (localPosition.dx * scaleX).toInt();
    int pixelY = (localPosition.dy * scaleY).toInt();

    if (pixelX >= 0 &&
        pixelX < _colorMapWidth &&
        pixelY >= 0 &&
        pixelY < _colorMapHeight) {
      int byteOffset = (pixelY * _colorMapWidth + pixelX) * 4;

      int r = _colorMapPixels!.getUint8(byteOffset);
      int g = _colorMapPixels!.getUint8(byteOffset + 1);
      int b = _colorMapPixels!.getUint8(byteOffset + 2);
      int a = _colorMapPixels!.getUint8(byteOffset + 3);

      if (a == 0) return;

      Color tappedColor = Color.fromARGB(255, r, g, b);
      _findAndDisplayPin(tappedColor);
    }
  }

  void _findAndDisplayPin(Color tappedColor) {
    for (var pin in _pinDetails) {
      Color normalizedPinColor = pin.pinColor.withAlpha(255);

      if (normalizedPinColor.toARGB32() == tappedColor.toARGB32()) {
        _showPinDialog(pin);
        return;
      }
    }
    log("MISSING COLOR: The image returned Hex #${tappedColor.toARGB32().toRadixString(16).toUpperCase()}");
  }

  void _showPinDialog(PinDetails pin) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          clipBehavior: Clip.antiAlias,
          backgroundColor: cardBackgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 56.0,
                color: appBarColor,
                alignment: Alignment.center,
                child: Text(
                  pin.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                        width: 16.0,
                        height: 60.0,
                        color: pin.pinColor,
                        margin: const EdgeInsets.only(right: 16.0)),
                    Expanded(
                      child: Text(
                        pin.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: blackTextColor, fontSize: 16.0),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("OK",
                        style:
                            TextStyle(color: blackTextColor, fontSize: 16.0)),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        );
      },
    );
  }

  String get _currentLayoutImagePath {
    if (currentVersion == BoardVersion.v6) {
      return isFrontSide
          ? 'assets/images/PSLab_v6_top.png'
          : 'assets/images/PSLab_v6_bottom.png';
    } else {
      return isFrontSide
          ? 'assets/images/pslab_v5_front_layout.png'
          : 'assets/images/pslab_v5_back_layout.png';
    }
  }

  String get _currentColormapImagePath {
    if (currentVersion == BoardVersion.v6) {
      return isFrontSide
          ? 'assets/images/pslab_v6_top_colormap.png'
          : 'assets/images/pslab_v6_bottom_colormap.png';
    } else {
      return isFrontSide
          ? 'assets/images/pslab_v5_front_colormap.png'
          : 'assets/images/pslab_v5_back_colormap.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Pin Layout",
      index: -1,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 11,
                  child: PopupMenuButton<BoardVersion>(
                    initialValue: currentVersion,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    offset: const Offset(0, 48),
                    color: cardBackgroundColor,
                    elevation: 4,
                    onSelected: (BoardVersion newVersion) {
                      if (newVersion != currentVersion) {
                        setState(() {
                          currentVersion = newVersion;
                          _colorMapPixels = null;
                        });
                        _updatePinDetailsList();
                        _loadColorMap();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<BoardVersion>(
                        value: BoardVersion.v6,
                        height: 36,
                        child: Text("PSLab V6",
                            style: TextStyle(
                                color: blackTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                      PopupMenuItem<BoardVersion>(
                        value: BoardVersion.v5,
                        height: 36,
                        child: Text("PSLab V5",
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 14)),
                      ),
                    ],
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4.0,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.developer_board,
                                  size: 18, color: appBarColor),
                              const SizedBox(width: 6),
                              Text(
                                currentVersion == BoardVersion.v6
                                    ? "V6 (Latest)"
                                    : "V5 (Legacy)",
                                style: TextStyle(
                                    color: blackTextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Icon(Icons.expand_more_rounded,
                              size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 9,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4.0,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!isFrontSide) {
                                setState(() {
                                  isFrontSide = true;
                                  _colorMapPixels = null;
                                });
                                _loadColorMap();
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isFrontSide
                                    ? appBarColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Front",
                                style: TextStyle(
                                  color: isFrontSide
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: isFrontSide
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (isFrontSide) {
                                setState(() {
                                  isFrontSide = false;
                                  _colorMapPixels = null;
                                });
                                _loadColorMap();
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: !isFrontSide
                                    ? appBarColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Back",
                                style: TextStyle(
                                  color: !isFrontSide
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: !isFrontSide
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: _colorMapPixels == null
                  ? CircularProgressIndicator(color: primaryRed)
                  : InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 6.0,
                      child: GestureDetector(
                        onTapUp: _handleTap,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              _currentLayoutImagePath,
                              key: _imageKey,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                            Opacity(
                              opacity: 0.6,
                              child: Image.asset(
                                _currentColormapImagePath,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
