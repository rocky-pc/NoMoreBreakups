import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/call_controller.dart';

const String AGORA_APP_ID = "de92d45464f74c409523c380fadd2d29";

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
  bool _isSpeakerPhone = true;
  late RtcEngine _engine;
  int _callDuration = 0;
  Timer? _timer;
  final _audioPlayer = AudioPlayer();
  bool _isRinging = false;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _updateAudioPlayerContext(); 
    _listenForCallStatus();
    if (widget.isCaller) {
      _startRinging();
    }
    // End callkit if active
    FlutterCallkitIncoming.endAllCalls();
  }

  void _listenForCallStatus() {
    _statusSubscription = Supabase.instance.client
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('channel_name', widget.channelName)
        .listen((data) {
      if (data.isNotEmpty) {
        final status = data.first['status'];
        if (status == 'ended' || status == 'declined') {
          _hangUp(localOnly: true);
        }
      }
    });
  }

  Future<void> _startRinging() async {
    _isRinging = true;
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/outgoing_ringtone.mp3'));
    } catch (e) {
      debugPrint('Error playing ringing sound: $e');
    }
  }

  void _stopRinging() {
    if (_isRinging) {
      _audioPlayer.stop();
      _isRinging = false;
    }
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: AGORA_APP_ID,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    await _engine.setDefaultAudioRouteToSpeakerphone(_isSpeakerPhone);
    await _engine.setEnableSpeakerphone(_isSpeakerPhone);

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _localUserJoined = true);
          _engine.setEnableSpeakerphone(_isSpeakerPhone);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _stopRinging();
          setState(() => _remoteUid = remoteUid);
          _startTimer();
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _hangUp();
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Agora Error: $err, $msg");
        },
      ),
    );

    if (widget.isVideoCall) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.enableAudio();
    }

    await _engine.joinChannel(
      token: '', 
      channelId: widget.channelName,
      uid: 0,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        publishCameraTrack: widget.isVideoCall,
        autoSubscribeAudio: true,
        autoSubscribeVideo: widget.isVideoCall,
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callDuration++);
    });
  }

  Future<void> _hangUp({bool localOnly = false}) async {
    _stopRinging();
    _timer?.cancel();
    _statusSubscription?.cancel();
    if (!localOnly) {
      await CallController().endCall(widget.channelName);
    }
    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (e) {
      debugPrint('Error releasing Agora: $e');
    }
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

  void _toggleSpeaker() {
    setState(() => _isSpeakerPhone = !_isSpeakerPhone);
    _engine.setEnableSpeakerphone(_isSpeakerPhone);
    _updateAudioPlayerContext();
  }

  void _updateAudioPlayerContext() {
    _audioPlayer.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: _isSpeakerPhone,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.voiceCommunication,
        audioFocus: AndroidAudioFocus.gain,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playAndRecord,
        options: _isSpeakerPhone
            ? {AVAudioSessionOptions.defaultToSpeaker, AVAudioSessionOptions.allowBluetooth}
            : {AVAudioSessionOptions.allowBluetooth},
      ),
    ));
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _stopRinging();
    _audioPlayer.dispose();
    _timer?.cancel();
    try {
      _engine.release();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Video Render / Audio Backdrop
          if (widget.isVideoCall && _remoteUid != null)
            Positioned.fill(
              child: AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: widget.channelName),
                ),
              ),
            )
          else
            _buildAudioBackdrop(),

          // 2. Gradient Overlay for better UI legibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 3. Floating Local Camera Preview
          if (widget.isVideoCall && _localUserJoined && !_cameraOff)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 20,
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10),
                  ],
                ),
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

          // 4. Top Info (User & Duration)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _remoteUid == null
                          ? 'Connecting...'
                          : _formatDuration(_callDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Bottom Controls
          Positioned(
            bottom: 40 + MediaQuery.of(context).padding.bottom,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _circleButton(
                      icon: _muted ? Icons.mic_off : Icons.mic,
                      isActive: !_muted,
                      onTap: _toggleMute,
                    ),
                    _circleButton(
                      icon: _isSpeakerPhone ? Icons.volume_up : Icons.volume_down,
                      isActive: _isSpeakerPhone,
                      onTap: _toggleSpeaker,
                    ),
                    if (widget.isVideoCall) ...[
                      _circleButton(
                        icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                        isActive: !_cameraOff,
                        onTap: _toggleCamera,
                      ),
                      _circleButton(
                        icon: Icons.switch_camera_rounded,
                        isActive: false,
                        onTap: _switchCamera,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => _hangUp(),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.redAccent, blurRadius: 20, spreadRadius: -5),
                      ],
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildAudioBackdrop() {
    return Stack(
      children: [
        if (widget.otherUserAvatar != null)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.otherUserAvatar!,
              fit: BoxFit.cover,
            ),
          ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.rose.withValues(alpha: 0.5), width: 4),
                  boxShadow: [
                    BoxShadow(color: AppColors.rose.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 10),
                  ],
                ),
                child: CircleAvatar(
                  radius: 70,
                  backgroundImage: widget.otherUserAvatar != null
                      ? CachedNetworkImageProvider(widget.otherUserAvatar!)
                      : null,
                  child: widget.otherUserAvatar == null
                      ? const Icon(Icons.person, size: 70, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 30),
              if (_remoteUid == null)
                const Text(
                  'Contacting Support...',
                  style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1.2),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleButton({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: isActive ? Colors.black : Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
