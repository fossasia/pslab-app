import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pslab/others/light_distance_experiment.dart';

import '../../theme/colors.dart';

class CommonScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final Key? scaffoldKey;
  final List<Widget>? actions;
  final VoidCallback? onGuidePressed;
  final VoidCallback? onOptionsPressed;
  final VoidCallback? onRecordPressed;
  final bool isRecording;
  final String icRecord = 'assets/icons/ic_record_white.png';
  final String icStopRecord = 'assets/icons/ic_record_stop_white.png';

  final bool isPlayingBack;
  final bool isPlaybackPaused;
  final VoidCallback? onPlaybackPauseResume;
  final VoidCallback? onPlaybackStop;

  const CommonScaffold({
    super.key,
    required this.body,
    required this.title,
    this.scaffoldKey,
    this.actions,
    this.onGuidePressed,
    this.onOptionsPressed,
    this.onRecordPressed,
    this.isRecording = false,
    this.isPlayingBack = false,
    this.isPlaybackPaused = false,
    this.onPlaybackPauseResume,
    this.onPlaybackStop,
  });

  @override
  State<StatefulWidget> createState() => _CommonScaffoldState();
}

class _CommonScaffoldState extends State<CommonScaffold> {
  Timer? _recordingTimer;
  Duration _recordingElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.isRecording) {
      _startRecordingTimer();
    }
  }

  @override
  void didUpdateWidget(CommonScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _startRecordingTimer();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _stopRecordingTimer();
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _startRecordingTimer() {
    _recordingElapsed = Duration.zero;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordingElapsed += const Duration(seconds: 1);
      });
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingElapsed = Duration.zero;
  }

  String _formatRecordingDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Widget _buildRecordingTimer() {
    final formatted = _formatRecordingDuration(_recordingElapsed);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Semantics(
        label: '${appLocalizations.recordingStarted}: $formatted',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: appBarContentColor, size: 10),
            const SizedBox(width: 6),
            Text(
              formatted,
              style: TextStyle(
                color: appBarContentColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  List<Widget> _buildResponsiveActions(double width) {
    final bool isVerySmall = width < 260;
    final bool isSmall = width < 320;

    final List<Widget> responsiveActions = [];

    if (widget.actions != null) {
      responsiveActions.addAll(widget.actions!);
    }

    if (widget.isPlayingBack) {
      if (!isVerySmall && widget.onPlaybackPauseResume != null) {
        responsiveActions.add(
          IconButton(
            onPressed: widget.onPlaybackPauseResume,
            icon: Icon(
              widget.isPlaybackPaused ? Icons.play_arrow : Icons.pause,
              color: appBarContentColor,
            ),
            tooltip: widget.isPlaybackPaused
                ? appLocalizations.resumePlayback
                : appLocalizations.pausePlayback,
          ),
        );
      }

      if (!isSmall && widget.onPlaybackStop != null) {
        responsiveActions.add(
          IconButton(
            onPressed: widget.onPlaybackStop,
            icon: Icon(
              Icons.stop,
              color: appBarContentColor,
            ),
            tooltip: appLocalizations.stopPlayback,
          ),
        );
      }
    } else {
      if (widget.isRecording) {
        responsiveActions.add(_buildRecordingTimer());
      }
      if (!isVerySmall && widget.onRecordPressed != null) {
        responsiveActions.add(
          IconButton(
            onPressed: widget.onRecordPressed,
            icon: Image.asset(
              widget.isRecording ? widget.icStopRecord : widget.icRecord,
              width: 24,
              height: 24,
            ),
            tooltip: widget.isRecording
                ? appLocalizations.stopRecording
                : appLocalizations.startRecording,
          ),
        );
      }
    }

    if (!isSmall && widget.onGuidePressed != null) {
      responsiveActions.add(
        IconButton(
          onPressed: widget.onGuidePressed,
          tooltip: appLocalizations.showGuide,
          icon: Icon(
            Icons.info,
            color: appBarContentColor,
          ),
        ),
      );
    }

    if (widget.onOptionsPressed != null) {
      responsiveActions.add(
        IconButton(
          onPressed: widget.onOptionsPressed,
          tooltip: appLocalizations.options,
          icon: Icon(
            Icons.more_vert,
            color: appBarContentColor,
          ),
        ),
      );
    }

    return responsiveActions;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;

        if (!widget.isPlayingBack) {
          _setPortraitOrientation();
        }
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: isLandscape,
        removeRight: isLandscape,
        child: Scaffold(
          backgroundColor: scaffoldBackgroundColor,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 4,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: appBarColor,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            backgroundColor: primaryRed,
            title: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: appLocalizations.back,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    if (!widget.isPlayingBack) {
                      _setPortraitOrientation();
                    }
                    SystemChrome.setEnabledSystemUIMode(
                        SystemUiMode.edgeToEdge);
                    Navigator.maybePop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: appBarContentColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    key: widget.scaffoldKey,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: appBarContentColor,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            actions: _buildResponsiveActions(width),
          ),
          body: widget.body,
        ),
      ),
    );
  }
}
