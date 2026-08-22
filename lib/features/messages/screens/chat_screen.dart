import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/message_controller.dart';
import '../models/message_model.dart';
import '../../profile/screens/profile_screen.dart';
import '../../calls/controllers/call_controller.dart';
import '../../calls/screens/call_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _audioRecorder = AudioRecorder();
  final _imagePicker = ImagePicker();

  bool _isRecording = false;
  bool _hasText = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final hasTextNow = _messageController.text.trim().isNotEmpty;
      if (hasTextNow != _hasText) {
        setState(() => _hasText = hasTextNow);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75, // Compress for bandwidth savings
      );
      if (image != null) {
        await ref.read(messageControllerProvider).sendMediaMessage(
          conversationId: widget.conversationId,
          receiverId: widget.otherUserId,
          file: File(image.path),
          messageType: MessageType.image,
        );
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return;

      final directory = await getApplicationDocumentsDirectory();
      _recordingPath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      const config = RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100);
      await _audioRecorder.start(config, path: _recordingPath!);

      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _recordDuration++);
      });
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    try {
      _recordTimer?.cancel();
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });

      if (!cancel && path != null && File(path).existsSync()) {
        await ref.read(messageControllerProvider).sendMediaMessage(
          conversationId: widget.conversationId,
          receiverId: widget.otherUserId,
          file: File(path),
          messageType: MessageType.audio,
        );
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    setState(() => _hasText = false);

    await ref.read(messageControllerProvider).sendMessage(
      conversationId: widget.conversationId,
      receiverId: widget.otherUserId,
      content: content,
    );

    _scrollToBottom();
  }

  void _handleCall({required bool isVideo}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isVideo ? Icons.videocam_rounded : Icons.phone_rounded, color: AppColors.rose),
            const SizedBox(width: 10),
            Text('Start ${isVideo ? "Video" : "Audio"} Call'),
          ],
        ),
        content: Text('Would you like to start a high-definition ${isVideo ? "video" : "audio"} call with ${widget.otherUserName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Call'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final channel = await ref.read(callControllerProvider).startCall(
            receiverId: widget.otherUserId,
            callType: isVideo ? 'video' : 'audio',
          );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              channelName: channel,
              otherUserName: widget.otherUserName,
              otherUserAvatar: widget.otherUserAvatar,
              isVideoCall: isVideo,
              isCaller: true,
            ),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final messagesAsync = ref.watch(messagesStreamProvider(widget.conversationId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: Stack(
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
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: isDarkMode 
                        ? Colors.black.withOpacity(0.4) 
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
              // Bottom border
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 0.5,
                  color: isDarkMode ? Colors.white12 : Colors.black12,
                ),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: widget.otherUserId),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundImage: widget.otherUserAvatar != null
                    ? CachedNetworkImageProvider(widget.otherUserAvatar!)
                    : null,
                child: widget.otherUserAvatar == null
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: widget.otherUserId),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUserName,
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Active in healing chat',
                      style: TextStyle(
                        fontSize: 11, 
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: AppColors.rose, size: 22),
            onPressed: () => _handleCall(isVideo: false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: AppColors.rose, size: 24),
            onPressed: () => _handleCall(isVideo: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyChatPrompt();
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMe = message.senderId == currentUserId;
                    return _MessageBubble(message: message, isMe: isMe);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.rose)),
              error: (err, stack) => Center(child: Text('Error loading messages: $err')),
            ),
          ),
          _buildMessageInputBar(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildEmptyChatPrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.rose.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, color: AppColors.rose, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            'Start a conversation with ${widget.otherUserName}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Share advice, support, and healing thoughts.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Dynamic Input Bar: Switches between Mic and Send smoothly
  // ---------------------------------------------------------------------
  Widget _buildMessageInputBar(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 8, 10, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCharcoal : Colors.white,
        border: Border(top: BorderSide(color: isDarkMode ? Colors.white12 : Colors.black12)),
      ),
      child: Row(
        children: [
          // Media attachments button (hidden when recording)
          if (!_isRecording) ...[
            IconButton(
              icon: const Icon(Icons.image_outlined, color: AppColors.rose, size: 24),
              onPressed: () => _pickImage(ImageSource.gallery),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: AppColors.rose, size: 24),
              onPressed: () => _pickImage(ImageSource.camera),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            ),
            const SizedBox(width: 4),
          ],

          // Middle input area (or recording timer)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: _isRecording
                  ? Row(
                children: [
                  const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${(_recordDuration ~/ 60).toString().padLeft(2, '0')}:${(_recordDuration % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _stopRecording(cancel: true),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              )
                  : TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Dynamic Action Button (Microphone vs. Send)
          GestureDetector(
            onTap: _hasText ? _sendMessage : null,
            onLongPressStart: !_hasText ? (_) => _startRecording() : null,
            onLongPressEnd: !_hasText ? (_) => _stopRecording() : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.rose,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.rose.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _hasText
                    ? Icons.arrow_upward_rounded
                    : (_isRecording ? Icons.mic : Icons.mic_none_rounded),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------
// Message Bubble with Tail & Timestamp
// -------------------------------------------------------------------------
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('hh:mm a').format(message.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.rose
              : (isDarkMode ? Colors.white12 : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildContent(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : (isDarkMode ? Colors.white60 : Colors.black45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (message.messageType) {
      case MessageType.image:
        return GestureDetector(
          onTap: () {
            if (message.mediaUrl != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _FullScreenImageViewer(imageUrl: message.mediaUrl!),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: message.mediaUrl!,
                fit: BoxFit.cover,
                width: 240,
                height: 240,
                placeholder: (context, url) => Container(
                  width: 240,
                  height: 240,
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => const SizedBox(
                  width: 240,
                  height: 120,
                  child: Icon(Icons.broken_image, size: 36, color: Colors.grey),
                ),
              ),
            ),
          ),
        );

      case MessageType.audio:
        return _InstagramVoicePlayer(url: message.mediaUrl!, isMe: isMe);

      case MessageType.text:
      default:
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
              fontSize: 15,
              height: 1.3,
            ),
          ),
        );
    }
  }
}

// -------------------------------------------------------------------------
// Instagram-Style Audio Waveform Player Widget
// -------------------------------------------------------------------------
class _InstagramVoicePlayer extends StatefulWidget {
  final String url;
  final bool isMe;

  const _InstagramVoicePlayer({required this.url, required this.isMe});

  @override
  State<_InstagramVoicePlayer> createState() => _InstagramVoicePlayerState();
}

class _InstagramVoicePlayerState extends State<_InstagramVoicePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerComplete.listen((_) => setState(() {
      _isPlaying = false;
      _position = Duration.zero;
    }));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.url));
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / Pause Button
          GestureDetector(
            onTap: _togglePlay,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: widget.isMe ? Colors.white : AppColors.rose,
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.isMe ? AppColors.rose : Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Simulated Waveform Bars + Duration
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(18, (index) {
                  final barFilled = (index / 18) <= progress;
                  final barHeights = [10, 16, 8, 22, 14, 26, 18, 12, 24, 16, 20, 14, 8, 22, 16, 10, 18, 12];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 3,
                    height: barHeights[index % barHeights.length].toDouble(),
                    decoration: BoxDecoration(
                      color: barFilled
                          ? (widget.isMe ? Colors.white : AppColors.rose)
                          : (widget.isMe ? Colors.white38 : Colors.black26),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                _duration == Duration.zero
                    ? 'Voice message'
                    : '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} / ${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: widget.isMe ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------
// Full-Screen Image Viewer
// -------------------------------------------------------------------------
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 3.5,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
            errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
    );
  }
}