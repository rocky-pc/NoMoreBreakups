import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

class CallKitService {
  static Future<void> showIncomingCall({
    required String callerName,
    required String? avatar,
    required String channelName,
    required bool isVideo,
    required String callId,
  }) async {
    final params = CallKitParams(
      id: const Uuid().v4(),
      nameCaller: callerName,
      appName: 'No More Breakups',
      avatar: avatar,
      handle: isVideo ? 'Video Call' : 'Audio Call',
      type: isVideo ? 1 : 0,
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: <String, dynamic>{
        'channel_name': channelName,
        'call_id': callId,
        'is_video': isVideo,
        'caller_name': callerName,
        'caller_avatar': avatar,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#E91E63', // Rose color
        backgroundUrl: 'assets/images/logo.jpeg',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  static Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }
}
