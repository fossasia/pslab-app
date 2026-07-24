import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/oled_display_provider.dart';
import 'package:flutter/services.dart';

class OledControlPanel extends StatefulWidget {
  const OledControlPanel({super.key});

  @override
  State<OledControlPanel> createState() => _OledControlPanelState();
}

class _OledControlPanelState extends State<OledControlPanel> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _keyboardFocus = FocusNode();
  static const Color primaryRed = Colors.red;

  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardFocus.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleKey(
    KeyEvent event,
    OledDisplayProvider provider,
  ) {
    if (provider.selectedGameType == GameModeType.racing) {
      final isDown = event is KeyDownEvent;
      final isUp = event is KeyUpEvent;

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.keyA) {
        if (isDown) {
          provider.setSteeringDirection(-1.0);
        } else if (isUp) {
          provider.setSteeringDirection(0.0);
        }
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.keyD) {
        if (isDown) {
          provider.setSteeringDirection(1.0);
        } else if (isUp) {
          provider.setSteeringDirection(0.0);
        }
      }
    } else {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (event is KeyDownEvent) {
          provider.jumpDino();
        }
      }
    }
  }

  Widget _buildToolButton(IconData icon, String toolId, Color primaryColor,
      OledDisplayProvider provider,
      {String? tooltip}) {
    final isSelected = provider.activeTool == toolId;
    return Tooltip(
      message: tooltip ?? '',
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: isSelected ? primaryColor : Colors.black54,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: const EdgeInsets.all(4),
        style: IconButton.styleFrom(
          backgroundColor: isSelected
              ? primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () => provider.setTool(toolId),
      ),
    );
  }

  Widget _buildGifButton(OledDisplayProvider provider) {
    return Tooltip(
      message: provider.isGifPlaying
          ? appLocalizations.stopGif
          : appLocalizations.uploadGif,
      child: IconButton(
        icon: Icon(
          provider.isGifPlaying
              ? Icons.stop_circle_outlined
              : Icons.gif_box_rounded,
          size: 22,
        ),
        color: provider.isGifPlaying ? primaryRed : Colors.black54,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: const EdgeInsets.all(4),
        style: IconButton.styleFrom(
          backgroundColor: provider.isGifPlaying
              ? primaryRed.withValues(alpha: 0.15)
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: (provider.isProcessing && !provider.isGifPlaying)
            ? null
            : () {
                if (provider.isGifPlaying) {
                  provider.stopGif();
                } else {
                  provider.pickAndPlayGif();
                }
              },
      ),
    );
  }

  Widget _buildGameBtn({
    IconData? icon,
    String? label,
    required Color color,
    required VoidCallback onDown,
    required VoidCallback onUp,
    double width = 64,
    double height = 42,
  }) {
    return Listener(
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onUp(),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(icon != null ? 14 : 20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: color, size: 24)
              : Text(
                  label!,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OledDisplayProvider>();

    if (provider.isGameMode) {
      return Focus(
          autofocus: true,
          focusNode: _keyboardFocus,
          onKeyEvent: (node, event) {
            _handleKey(event, provider);
            return KeyEventResult.handled;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1.2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<GameModeType>(
                          value: provider.selectedGameType,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: primaryRed),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: GameModeType.racing,
                                child: Text("Racer")),
                            DropdownMenuItem(
                                value: GameModeType.dino, child: Text("Dino")),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              provider.switchGame(val);
                            }
                          },
                        ),
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1.2),
                      ),
                      child: IconButton(
                        tooltip: provider.isGameRunning
                            ? appLocalizations.pauseGame
                            : appLocalizations.startGame,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          provider.isGameRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.black87,
                          size: 24,
                        ),
                        onPressed: () {
                          _keyboardFocus.requestFocus();
                          if (provider.isGameRunning) {
                            provider.stopGame();
                          } else {
                            provider.startGame();
                          }
                        },
                      ),
                    ),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1.2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<double>(
                          value: provider.baseSpeedMultiplier,
                          icon: const Padding(
                            padding: EdgeInsets.only(left: 4.0),
                            child: Icon(Icons.speed_rounded,
                                color: primaryRed, size: 18),
                          ),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          items: const [
                            DropdownMenuItem(value: 0.5, child: Text("0.5x")),
                            DropdownMenuItem(value: 1.0, child: Text("1.0x")),
                            DropdownMenuItem(value: 1.5, child: Text("1.5x")),
                            DropdownMenuItem(value: 2.0, child: Text("2.0x")),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              provider.setGameSpeed(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (provider.selectedGameType == GameModeType.racing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGameBtn(
                          icon: Icons.keyboard_arrow_left_rounded,
                          color: primaryRed,
                          onDown: () => provider.setSteeringDirection(-1.0),
                          onUp: () => provider.setSteeringDirection(0.0)),
                      const SizedBox(width: 32),
                      _buildGameBtn(
                          icon: Icons.keyboard_arrow_right_rounded,
                          color: primaryRed,
                          onDown: () => provider.setSteeringDirection(1.0),
                          onUp: () => provider.setSteeringDirection(0.0)),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGameBtn(
                          label: "JUMP",
                          width: 120,
                          height: 42,
                          color: primaryRed,
                          onDown: () => provider.jumpDino(),
                          onUp: () {}),
                    ],
                  ),
              ],
            ),
          ));
    } else {
      return Column(
        children: [
          TextField(
            controller: _textController,
            enabled: !provider.isGifPlaying,
            cursorColor: primaryRed,
            style: const TextStyle(color: Colors.black, fontSize: 14),
            onChanged: (val) => provider.renderTextToPreview(val),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor:
                  provider.isGifPlaying ? Colors.grey[200] : Colors.white,
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 40, minHeight: 40),
              suffixIcon: IconButton(
                tooltip: appLocalizations.send,
                icon: Icon(Icons.send_rounded,
                    color: provider.isGifPlaying ? Colors.black26 : primaryRed,
                    size: 22),
                padding: EdgeInsets.zero,
                onPressed: provider.isGifPlaying
                    ? null
                    : () async {
                        final text = _textController.text;
                        if (text.isNotEmpty) {
                          provider.renderTextToCanvas(text);
                          _textController.clear();
                        }
                        FocusScope.of(context).unfocus();
                        if (!provider.isLiveMode) {
                          await provider.syncManual();
                        }
                      },
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black38, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: primaryRed, width: 1.5),
              ),
              hintText: provider.isGifPlaying
                  ? appLocalizations.gifPlaying
                  : appLocalizations.typeAndSend,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGifButton(provider),
                    _buildToolButton(Icons.edit, 'draw', primaryRed, provider,
                        tooltip: appLocalizations.pencil),
                    _buildToolButton(Icons.cleaning_services_rounded, 'erase',
                        primaryRed, provider,
                        tooltip: appLocalizations.eraser),
                    Container(
                        height: 20, width: 1.5, color: Colors.grey.shade300),
                    _buildToolButton(
                        Icons.horizontal_rule, 'line', primaryRed, provider,
                        tooltip: appLocalizations.line),
                    _buildToolButton(
                        Icons.crop_square, 'rect', primaryRed, provider,
                        tooltip: appLocalizations.rectangle),
                    _buildToolButton(
                        Icons.grid_on, 'grid', primaryRed, provider,
                        tooltip: appLocalizations.grid),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolButton(
                        Icons.circle_outlined, 'circle', primaryRed, provider,
                        tooltip: appLocalizations.circle),
                    _buildToolButton(
                        Icons.change_history, 'triangle', primaryRed, provider,
                        tooltip: appLocalizations.triangle),
                    _buildToolButton(
                        Icons.hexagon_outlined, 'hexagon', primaryRed, provider,
                        tooltip: appLocalizations.hexagon),
                    _buildToolButton(
                        Icons.star_border, 'star', primaryRed, provider,
                        tooltip: appLocalizations.star),
                    _buildToolButton(
                        Icons.favorite_border, 'heart', primaryRed, provider,
                        tooltip: appLocalizations.heart),
                    _buildToolButton(
                        Icons.arrow_outward, 'arrow', primaryRed, provider,
                        tooltip: appLocalizations.arrow),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
