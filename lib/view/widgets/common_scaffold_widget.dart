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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: appBarColor,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              onPressed: () {
                Navigator.maybePop(context);
              },
              icon: Icon(Icons.arrow_back, color: appBarContentColor),
            );
          },
        ),
        backgroundColor: primaryRed,
        title: Text(
          key: widget.scaffoldKey,
          widget.title,
          style: TextStyle(color: appBarContentColor, fontSize: 15),
        ),
        actions: [
          if (widget.actions != null) ...widget.actions!,
          if (widget.isPlayingBack) ...[
            if (widget.onPlaybackPauseResume != null)
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
            if (widget.onPlaybackStop != null)
              IconButton(
                onPressed: widget.onPlaybackStop,
                icon: Icon(Icons.stop, color: appBarContentColor),
                tooltip: appLocalizations.stopPlayback,
              ),
          ] else if (widget.onRecordPressed != null)
            IconButton(
              onPressed: widget.onRecordPressed,
              icon: Image.asset(
                widget.isRecording ? widget.icStopRecord : widget.icRecord,
                width: 24,
                height: 24,
              ),
              tooltip: widget.isRecording
                  ? 'Stop Recording'
                  : 'Start Recording',
            ),
          if (widget.onGuidePressed != null)
            IconButton(
              onPressed: widget.onGuidePressed,
              icon: Icon(Icons.info, color: appBarContentColor),
            ),
          if (widget.onOptionsPressed != null)
            IconButton(
              onPressed: widget.onOptionsPressed,
              icon: Icon(Icons.more_vert, color: appBarContentColor),
            ),
        ],
      ),
      body: widget.body,
    );
  }
}
