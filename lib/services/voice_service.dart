import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:twilio_voice/twilio_voice.dart';
import 'package:flux_virtual/services/api_service.dart';

enum VoiceCallState { idle, calling, ringing, connected, disconnected }

class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final _stateCtrl = StreamController<VoiceCallState>.broadcast();
  Stream<VoiceCallState> get callStateStream => _stateCtrl.stream;

  VoiceCallState _current = VoiceCallState.idle;
  VoiceCallState get currentState => _current;

  StreamSubscription<CallEvent>? _eventSub;
  bool _initialized = false;

  Future<bool> _requestMic() async {
    final hasAccess = await TwilioVoice.instance.hasMicAccess();
    if (hasAccess) return true;
    final granted = await TwilioVoice.instance.requestMicAccess();
    return granted ?? false;
  }

  // Requests READ_PHONE_NUMBERS runtime permission and registers the Android
  // phone account. On first install the user must also enable the account in
  // Settings → Phone → Calling accounts; we open that page for them.
  static Future<void> setupAndroid() async {
    if (!Platform.isAndroid) return;

    // 1. Request READ_PHONE_NUMBERS permission (required by ConnectionService)
    await TwilioVoice.instance.requestReadPhoneNumbersPermission();

    // 2. Register the phone account with Android TelecomManager
    await TwilioVoice.instance.registerPhoneAccount();

    // 3. Check if it's enabled — if not, open the Settings page so the user
    //    can enable "Flux Virtual" under Calling accounts (one-time step).
    final registered = await TwilioVoice.instance.hasRegisteredPhoneAccount();
    if (registered != true) {
      await TwilioVoice.instance.openPhoneAccountSettings();
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    final tokenData = await ApiService.getVoiceToken();
    final accessToken = tokenData['token'] as String? ?? '';
    if (accessToken.isEmpty) throw Exception('Failed to get voice token');

    String? deviceToken;
    if (Platform.isAndroid) {
      deviceToken = await FirebaseMessaging.instance.getToken();
    }

    await TwilioVoice.instance.setTokens(
      accessToken: accessToken,
      deviceToken: deviceToken,
    );

    _eventSub = TwilioVoice.instance.callEventsListener.listen((event) {
      switch (event) {
        case CallEvent.ringing:
          _emit(VoiceCallState.ringing);
        case CallEvent.connected:
        case CallEvent.reconnected:
          _emit(VoiceCallState.connected);
        case CallEvent.callEnded:
        case CallEvent.declined:
          _emit(VoiceCallState.disconnected);
        default:
          break;
      }
    });

    _initialized = true;
  }

  Future<void> makeCall({required String to, required String from}) async {
    final granted = await _requestMic();
    if (!granted) throw Exception('Microphone permission denied');

    // On Android, ensure the phone account is registered before placing a call
    if (Platform.isAndroid) {
      final registered = await TwilioVoice.instance.hasRegisteredPhoneAccount();
      if (registered != true) {
        // Re-register and open settings — user hasn't enabled the account yet
        await TwilioVoice.instance.registerPhoneAccount();
        await TwilioVoice.instance.openPhoneAccountSettings();
        throw Exception(
          'Please enable "Flux Virtual" under Settings → Phone → Calling accounts, then try again.',
        );
      }
    }

    await initialize();

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _emit(VoiceCallState.calling);

    await TwilioVoice.instance.call.place(
      from: uid,
      to: ApiService.toE164(to),
      extraOptions: {'CallerId': ApiService.toE164(from)},
    );
  }

  Future<void> hangUp() async {
    try {
      await TwilioVoice.instance.call.hangUp();
    } catch (_) {}
    _emit(VoiceCallState.disconnected);
  }

  Future<void> toggleMute({required bool muted}) async {
    try {
      await TwilioVoice.instance.call.toggleMute(muted);
    } catch (_) {}
  }

  Future<void> toggleSpeaker({required bool speakerOn}) async {
    try {
      await TwilioVoice.instance.call.toggleSpeaker(speakerOn);
    } catch (_) {}
  }

  void _emit(VoiceCallState state) {
    _current = state;
    _stateCtrl.add(state);
  }

  void dispose() {
    _eventSub?.cancel();
    _stateCtrl.close();
    _initialized = false;
  }
}
