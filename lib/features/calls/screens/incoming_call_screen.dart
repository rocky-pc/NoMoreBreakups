import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/call_controller.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final Map<String, dynamic> callData;
  final String callerName;
  final String? callerAvatar;

  const IncomingCallScreen({
    super.key,
    required this.callData,
    required this.callerName,
    this.callerAvatar,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final _audioPlayer = AudioPlayer();
  bool _isRinging = true;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _playRingtone();
    _listenForStatus();
  }

  void _listenForStatus() {
    _statusSubscription = Supabase.instance.client
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('id', widget.callData['id'])
        .listen((data) {
      if (data.isNotEmpty) {
        final status = data.first['status'];
        if (status == 'ended' || status == 'declined' || status == 'accepted') {
          _stopRingtone();
          // If the call was accepted elsewhere (e.g. CallKit), close this screen
          if (mounted && status != 'accepted') {
             Navigator.pop(context);
          } else if (mounted && status == 'accepted') {
             // Let the MainScreen listener handle navigation to CallScreen
             Navigator.pop(context);
          }
        }
      }
    });
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // Fallback to outgoing if incoming is missing
      await _audioPlayer.play(AssetSource('sounds/outgoing_ringtone.mp3'));
    } catch (e) {
      debugPrint('Error playing ringtone: $e');
    }
  }

  void _stopRingtone() {
    if (_isRinging) {
      _audioPlayer.stop();
      _isRinging = false;
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _stopRingtone();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _acceptCall() async {
    _stopRingtone();
    
    // Ensure permissions are granted before proceeding
    await [
      Permission.microphone,
      if (widget.callData['call_type'] == 'video') Permission.camera,
    ].request();

    await CallController().acceptCall(widget.callData['id']);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            channelName: widget.callData['channel_name'],
            otherUserName: widget.callerName,
            otherUserAvatar: widget.callerAvatar,
            isVideoCall: widget.callData['call_type'] == 'video',
            isCaller: false,
          ),
        ),
      );
    }
  }

  void _declineCall() async {
    _stopRingtone();
    await CallController().endCall(widget.callData['channel_name']);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Blur / Image
          if (widget.callerAvatar != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: widget.callerAvatar!,
                fit: BoxFit.cover,
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Caller Info
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.rose.withValues(alpha: 0.2),
                  backgroundImage: widget.callerAvatar != null
                      ? CachedNetworkImageProvider(widget.callerAvatar!)
                      : null,
                  child: widget.callerAvatar == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Incoming ${widget.callData['call_type']} call...',
                  style: const TextStyle(
                    color: AppColors.rose,
                    fontSize: 16,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Decline
                      _actionButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        label: 'Decline',
                        onTap: _declineCall,
                      ),
                      
                      // Accept
                      _actionButton(
                        icon: Icons.call,
                        color: Colors.green,
                        label: 'Accept',
                        onTap: _acceptCall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}
