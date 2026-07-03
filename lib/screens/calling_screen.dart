import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flux_virtual/services/api_service.dart';
import 'package:flux_virtual/services/voice_service.dart';
import 'package:twilio_voice/twilio_voice.dart';

class CallingScreen extends StatefulWidget {
  final String toNumber;
  final String fromNumber;
  final String contactName;
  final bool autoCall;
  final bool isIncoming;

  const CallingScreen({
    super.key,
    required this.toNumber,
    required this.fromNumber,
    required this.contactName,
    this.autoCall = true,
    this.isIncoming = false,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeakerOn = false;
  bool _isMuted = false;

  Duration _elapsed = Duration.zero;
  Timer? _timer;

  late VoiceCallState _callState;
  StreamSubscription<VoiceCallState>? _callSub;
  bool _hasPopped = false;
  late final int _ratePerMinute;

  @override
  void initState() {
    super.initState();
    _callState = widget.isIncoming
        ? VoiceCallState.incoming
        : VoiceCallState.calling;
    _ratePerMinute = ApiService.callRateForNumber(
      ApiService.toE164(widget.toNumber),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    if (!widget.isIncoming) _startRinging();

    _callSub = VoiceService.instance.callStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _callState = state);
      if (state == VoiceCallState.connected) {
        _audioPlayer.stop();
        _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
        });
      } else if (state == VoiceCallState.disconnected) {
        _safePop();
      }
    });

    if (widget.autoCall) _initiateCall();
  }

  void _safePop() {
    if (_hasPopped || !mounted) return;
    _hasPopped = true;
    Navigator.of(context).pop();
  }

  Future<void> _initiateCall() async {
    try {
      await VoiceService.instance.makeCall(
        to: widget.toNumber,
        from: widget.fromNumber,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('denied')
                ? 'Microphone permission denied'
                : 'Call failed: ${e.toString()}',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _safePop();
    }
  }

  Future<void> _startRinging() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
    } catch (_) {
      // No ringtone asset — visual ringing only
    }
  }

  Future<void> _toggleSpeaker() async {
    final newVal = !_isSpeakerOn;
    setState(() => _isSpeakerOn = newVal);
    await VoiceService.instance.toggleSpeaker(speakerOn: newVal);
  }

  String get _formattedTime {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggleMute() async {
    final next = !_isMuted;
    setState(() => _isMuted = next);
    await VoiceService.instance.toggleMute(muted: next);
  }

  Future<void> _endCall() async {
    await VoiceService.instance.hangUp();
    // hangUp() emits disconnected → stream listener calls _safePop()
  }

  Future<void> _answerCall() async {
    try {
      await TwilioVoice.instance.call.answer();
    } catch (_) {}
  }

  Future<void> _declineCall() async {
    await VoiceService.instance.hangUp();
  }

  @override
  void dispose() {
    _callSub?.cancel();
    _pulseController.dispose();
    _audioPlayer.dispose();
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Widget _buildPulseRing(double phaseOffset) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, child) {
        final t = (_pulseController.value + phaseOffset) % 1.0;
        final scale = 1.0 + t;
        final opacity = (1.0 - t) * 0.38;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.greenAccent.withOpacity(opacity),
                width: 2.5,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.contactName.trim().isNotEmpty
        ? widget.contactName
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1017),
      body: Stack(
        children: [
          // Green-to-dark gradient behind the avatar
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A2E18), Color(0xFF0D1017)],
                  stops: [0.0, 0.55],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 52),

                // Status
                Text(
                  switch (_callState) {
                    VoiceCallState.calling => 'Calling...',
                    VoiceCallState.ringing => 'Ringing...',
                    VoiceCallState.incoming => 'Incoming Call',
                    VoiceCallState.connected => 'Connected',
                    VoiceCallState.disconnected => 'Call ended',
                    VoiceCallState.idle => '',
                  },
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const SizedBox(height: 12),

                // Name
                Text(
                  widget.contactName.isNotEmpty
                      ? widget.contactName
                      : widget.toNumber,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),

                if (widget.contactName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.toNumber,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.45),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Elapsed timer
                Text(
                  _formattedTime,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.3),
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),

                const Spacer(),

                // Pulsing avatar
                SizedBox(
                  width: 270,
                  height: 270,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildPulseRing(0.0),
                      _buildPulseRing(0.33),
                      _buildPulseRing(0.66),
                      // Avatar
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0D3B1E),
                          border: Border.all(
                            color: Colors.greenAccent.withOpacity(0.45),
                            width: 2,
                          ),
                        ),
                        child: initials.isNotEmpty
                            ? Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 46,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 64,
                              ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Controls row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: _callState == VoiceCallState.incoming
                      // Answer / Decline buttons for incoming call
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _CallingButton(
                              icon: Icons.call_end_rounded,
                              label: 'Decline',
                              size: 72,
                              isDestructive: true,
                              onTap: _declineCall,
                            ),
                            _CallingButton(
                              icon: Icons.call_rounded,
                              label: 'Answer',
                              size: 72,
                              isAnswer: true,
                              onTap: _answerCall,
                            ),
                          ],
                        )
                      // Normal in-call controls
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _CallingButton(
                              icon: _isSpeakerOn
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_down_rounded,
                              label: 'Speaker',
                              size: 64,
                              isActive: _isSpeakerOn,
                              onTap: _toggleSpeaker,
                            ),
                            _CallingButton(
                              icon: Icons.call_end_rounded,
                              label: 'End',
                              size: 80,
                              isDestructive: true,
                              onTap: _endCall,
                            ),
                            _CallingButton(
                              icon: _isMuted
                                  ? Icons.mic_off_rounded
                                  : Icons.mic_rounded,
                              label: _isMuted ? 'Unmute' : 'Mute',
                              size: 64,
                              isActive: _isMuted,
                              isDisabled: _callState != VoiceCallState.connected,
                              onTap: _toggleMute,
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 22),

                Text(
                  'From  ${widget.fromNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.28),
                  ),
                ),

                const SizedBox(height: 6),

                // Rate + running cost
                Text(
                  _callState == VoiceCallState.connected
                      ? '₦${(_ratePerMinute * _elapsed.inSeconds / 60).toStringAsFixed(0)}  •  ₦$_ratePerMinute/min'
                      : '₦$_ratePerMinute / min',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.greenAccent.withOpacity(0.55),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final double size;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDestructive;
  final bool isAnswer;
  final bool isDisabled;

  const _CallingButton({
    required this.icon,
    required this.label,
    required this.size,
    required this.onTap,
    this.isActive = false,
    this.isDestructive = false,
    this.isAnswer = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDestructive
        ? Colors.red
        : isAnswer
            ? Colors.green
            : isActive
                ? Colors.white.withOpacity(0.28)
                : Colors.white.withOpacity(0.1);

    final iconColor =
        isDisabled ? Colors.white.withOpacity(0.22) : Colors.white;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: size * 0.42),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDisabled
                  ? Colors.white.withOpacity(0.22)
                  : Colors.white.withOpacity(0.55),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
