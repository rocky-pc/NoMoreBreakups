import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/call_controller.dart';

// IMPORTANT: Insert your Agora App ID here
const String AGORA_APP_ID = "YOUR_AGORA_APP_ID";

class CallScreen extends StatefulWidget {
  final String channelName;
  final String otherUserName;
  final String? otherUserAvatar;
  final bool isVideoCall;
  final bool isCaller;

  const CallScreen({
    super.key,
    required this.channelName,
    required this.otherUserName,
    this.otherUserAvatar,
    this.isVideoCall = true,
    this.isCaller = true,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _muted = false;
  bool _cameraOff = false;
  late RtcEngine _engine;
  int _callDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // 1. Request microphone & camera permissions
    await [Permission.microphone, Permission.camera].request();

    // 2. Create Agora RTC engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: AGORA_APP_ID,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // 3. Register Event Handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
          _startTimer();
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _hangUp();
        },
      ),
    );

    // 4. Enable Audio / Video
    if (widget.isVideoCall) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.enableAudio();
    }

    // 5. Join the Channel
    await _engine.joinChannel(
      token: '', // Leave empty if testing without Agora Token Certificate
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callDuration++);
    });
  }

  Future<void> _hangUp() async {
    _timer?.cancel();
    await CallController().endCall(widget.channelName);
    await _engine.leaveChannel();
    await _engine.release();
    if (mounted) Navigator.of(context).pop();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _engine.muteLocalAudioStream(_muted);
  }

  void _toggleCamera() {
    if (!widget.isVideoCall) return;
    setState(() => _cameraOff = !_cameraOff);
    _engine.muteLocalVideoStream(_cameraOff);
  }

  void _switchCamera() {
    if (widget.isVideoCall) {
      _engine.switchCamera();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Remote Video / Audio Backdrop
            if (widget.isVideoCall && _remoteUid != null)
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: widget.channelName),
                ),
              )
            else
              _buildAudioBackdrop(),

            // 2. Floating Local Camera Preview (for video calls)
            if (widget.isVideoCall && _localUserJoined && !_cameraOff)
              Positioned(
                top: 20,
                right: 20,
                child: SizedBox(
                  width: 110,
                  height: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
              ),

            // 3. Top Call Info Bar
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _remoteUid == null
                        ? 'Ringing...'
                        : '${(_callDuration ~/ 60).toString().padLeft(2, '0')}:${(_callDuration % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            // 4. Bottom Control Bar
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Mic
                  _callActionBtn(
                    icon: _muted ? Icons.mic_off : Icons.mic,
                    color: _muted ? Colors.white : Colors.white24,
                    iconColor: _muted ? Colors.black : Colors.white,
                    onTap: _toggleMute,
                  ),

                  // End Call Button
                  _callActionBtn(
                    icon: Icons.call_end,
                    color: Colors.red,
                    iconColor: Colors.white,
                    size: 64,
                    onTap: _hangUp,
                  ),

                  // Switch Camera (Video Call only)
                  if (widget.isVideoCall)
                    _callActionBtn(
                      icon: Icons.switch_camera,
                      color: Colors.white24,
                      iconColor: Colors.white,
                      onTap: _switchCamera,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioBackdrop() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 54,
            backgroundColor: AppColors.rose.withValues(alpha: 0.2),
            backgroundImage: widget.otherUserAvatar != null
                ? CachedNetworkImageProvider(widget.otherUserAvatar!)
                : null,
            child: widget.otherUserAvatar == null
                ? const Icon(Icons.person, size: 54, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            widget.otherUserName,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _remoteUid != null ? 'Connected' : 'Calling...',
            style: const TextStyle(color: AppColors.rose, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _callActionBtn({
    required IconData icon,
    required Color color,
    required Color iconColor,
    double size = 52,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: size * 0.48),
      ),
    );
  }
}
