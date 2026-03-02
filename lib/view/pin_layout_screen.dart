import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pslab/view/widgets/main_scaffold_widget.dart';

import '../models/pin_details.dart';
import '../theme/colors.dart';

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
  late bool isFrontSide;
  img.Image? _colorMapImage;
  final GlobalKey _imageKey = GlobalKey();

  List<PinDetails> _pinDetails = [];

  @override
  void initState() {
    super.initState();
    isFrontSide = widget.initialIsFrontSide;
    _loadColorMap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pinDetails = PinDetails.getAllPins(context);
  }

  Future<void> _loadColorMap() async {
    String path = isFrontSide
        ? 'assets/images/pslab_v6_top_colormap.png'
        : 'assets/images/pslab_v6_bottom_colormap.png';

    try {
      final ByteData data = await rootBundle.load(path);
      final Uint8List bytes = data.buffer.asUint8List();

      final decodedImage = await compute(decodeImageInBackground, bytes);

      if (mounted) {
        setState(() {
          _colorMapImage = decodedImage;
        });
      }
    } catch (e) {
      log("Error loading colormap: $e");
    }
  }

  void _handleTap(TapUpDetails details) {
    if (_colorMapImage == null) return;

    final RenderBox renderBox =
        _imageKey.currentContext!.findRenderObject() as RenderBox;
    final Size renderedSize = renderBox.size;
    final Offset localPosition = details.localPosition;

    double scaleX = _colorMapImage!.width / renderedSize.width;
    double scaleY = _colorMapImage!.height / renderedSize.height;

    int pixelX = (localPosition.dx * scaleX).toInt();
    int pixelY = (localPosition.dy * scaleY).toInt();

    if (pixelX >= 0 &&
        pixelX < _colorMapImage!.width &&
        pixelY >= 0 &&
        pixelY < _colorMapImage!.height) {
      final img.Pixel pixel = _colorMapImage!.getPixel(pixelX, pixelY);

      if (pixel.a == 0) return;

      Color tappedColor = Color.fromARGB(
          255, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());

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
  }

  void _showPinDialog(PinDetails pin) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
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
                    fontWeight: FontWeight.bold,
                  ),
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
                      margin: const EdgeInsets.only(right: 16.0),
                    ),
                    Expanded(
                      child: Text(
                        pin.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: blackTextColor,
                          fontSize: 16.0,
                        ),
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
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "OK",
                      style: TextStyle(
                        color: blackTextColor,
                        fontSize: 16.0,
                      ),
                    ),
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

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: isFrontSide ? "Front Layout" : "Back Layout",
      index: -1,
      body: Center(
        child: _colorMapImage == null
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
                        isFrontSide
                            ? 'assets/images/PSLab_v6_top.png'
                            : 'assets/images/PSLab_v6_bottom.png',
                        key: _imageKey,
                        fit: BoxFit.contain,
                      ),
                      Opacity(
                        opacity: 0.5,
                        child: Image.asset(
                          isFrontSide
                              ? 'assets/images/pslab_v6_top_colormap.png'
                              : 'assets/images/pslab_v6_bottom_colormap.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

img.Image? decodeImageInBackground(Uint8List bytes) {
  return img.decodeImage(bytes);
}
