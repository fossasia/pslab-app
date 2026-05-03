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
              icon: Icon(
                Icons.arrow_back,
                color: appBarContentColor,
              ),
            );
          },
        ),
        backgroundColor: primaryRed,
        title: Text(
          widget.title,
          key: widget.scaffoldKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: appBarContentColor,
            fontSize: 15,
          ),
        ),
        actions: _buildResponsiveActions(width),
      ),
      body: widget.body,
    );
  }
}
