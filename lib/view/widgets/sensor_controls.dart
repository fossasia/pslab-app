import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';

class SensorControlsWidget extends StatefulWidget {
  final bool isPlaying;
  final bool isLooping;
  final int timegapMs;
  final int numberOfReadings;
  final VoidCallback onPlayPause;
  final VoidCallback onLoop;
  final Function(int) onTimegapChanged;
  final Function(int) onNumberOfReadingsChanged;
  final VoidCallback? onClearData;
  final VoidCallback? onReset;

  const SensorControlsWidget({
    super.key,
    required this.isPlaying,
    required this.isLooping,
    required this.timegapMs,
    required this.numberOfReadings,
    required this.onPlayPause,
    required this.onLoop,
    required this.onTimegapChanged,
    required this.onNumberOfReadingsChanged,
    this.onClearData,
    this.onReset,
  });

  @override
  State<SensorControlsWidget> createState() => _SensorControlsWidgetState();
}

class _SensorControlsWidgetState extends State<SensorControlsWidget> {
  late TextEditingController _numberController;
  late FocusNode _textFieldFocusNode;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(
      text: widget.numberOfReadings.toString(),
    );
    _textFieldFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(SensorControlsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.numberOfReadings != oldWidget.numberOfReadings) {
      _numberController.text = widget.numberOfReadings.toString();
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  void _onNumberChanged(String value) {
    final number = int.tryParse(value);
    if (number != null && number > 0) {
      widget.onNumberOfReadingsChanged(number);
    }
  }

  void _onTextFieldSubmitted(String value) {
    _textFieldFocusNode.unfocus();
    _onNumberChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: primaryRed, width: 3),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildPlayPauseButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberOfReadingsField(),
                ),
                const SizedBox(width: 12),
                _buildLoopButton(),
                if (widget.onClearData != null || widget.onReset != null) ...[
                  const SizedBox(width: 12),
                  _buildActionButtons(),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _buildTimegapSlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTap: widget.onPlayPause,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: primaryRed,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryRed.withAlpha(80),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          widget.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNumberOfReadingsField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: TextField(
        controller: _numberController,
        focusNode: _textFieldFocusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          hintText: '100',
        ),
        onChanged: _onNumberChanged,
        onSubmitted: _onTextFieldSubmitted,
      ),
    );
  }

  Widget _buildLoopButton() {
    return GestureDetector(
      onTap: widget.onLoop,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color:
              widget.isLooping ? primaryRed.withAlpha(26) : Colors.transparent,
          border: Border.all(
            color: widget.isLooping ? primaryRed : Colors.grey.shade400,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.all_inclusive,
          color: widget.isLooping ? primaryRed : Colors.grey.shade600,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onClearData != null)
          _buildActionButton(
            icon: Icons.clear_all,
            onTap: widget.onClearData!,
            tooltip: 'Clear Data',
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(
            icon,
            color: Colors.grey.shade600,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildTimegapSlider() {
    return Row(
      children: [
        const Text(
          'Time gap',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryRed,
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: primaryRed,
              overlayColor: primaryRed.withAlpha(50),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 4,
              valueIndicatorColor: primaryRed,
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            child: Slider(
              value: widget.timegapMs.toDouble(),
              min: 200,
              max: 1000,
              divisions: 19,
              label: '${widget.timegapMs}ms',
              onChanged: (value) => widget.onTimegapChanged(value.toInt()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${widget.timegapMs}ms',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
