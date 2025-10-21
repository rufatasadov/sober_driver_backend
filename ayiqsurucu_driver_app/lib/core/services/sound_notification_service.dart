import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundNotificationService {
  static final SoundNotificationService _instance =
      SoundNotificationService._internal();
  factory SoundNotificationService() => _instance;
  SoundNotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundEnabled = true;
  bool _isPlaying = false;

  /// Initialize the sound service
  Future<void> initialize() async {
    try {
      // Set audio context for better performance
      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            defaultToSpeaker: true,
            category: AVAudioSessionCategory.playback,
            options: [
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.allowBluetooth,
              AVAudioSessionOptions.allowBluetoothA2DP,
            ],
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );

      print('🔊 SoundNotificationService initialized');
    } catch (e) {
      print('❌ Error initializing SoundNotificationService: $e');
    }
  }

  /// Play new order notification sound
  Future<void> playNewOrderSound() async {
    if (!_isSoundEnabled || _isPlaying) return;

    try {
      _isPlaying = true;

      // Use system notification sound
      await _playSystemNotificationSound();

      print('🔊 Playing new order notification sound');
    } catch (e) {
      print('❌ Error playing new order sound: $e');
      _isPlaying = false;

      // Fallback to haptic feedback
      await _playHapticFeedback();
    }
  }

  /// Play assigned order notification sound
  Future<void> playAssignedOrderSound() async {
    if (!_isSoundEnabled || _isPlaying) return;

    try {
      _isPlaying = true;

      // Use system notification sound
      await _playSystemNotificationSound();

      print('🔊 Playing assigned order notification sound');
    } catch (e) {
      print('❌ Error playing assigned order sound: $e');
      _isPlaying = false;

      // Fallback to haptic feedback
      await _playHapticFeedback();
    }
  }

  /// Play broadcast order notification sound
  Future<void> playBroadcastOrderSound() async {
    if (!_isSoundEnabled || _isPlaying) return;

    try {
      _isPlaying = true;

      // Use system notification sound
      await _playSystemNotificationSound();

      print('🔊 Playing broadcast order notification sound');
    } catch (e) {
      print('❌ Error playing broadcast order sound: $e');
      _isPlaying = false;

      // Fallback to haptic feedback
      await _playHapticFeedback();
    }
  }

  /// Play system notification sound using platform channels
  Future<void> _playSystemNotificationSound() async {
    try {
      // Play a sequence of sounds to create notification effect
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));

      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((event) {
        _isPlaying = false;
      });
    } catch (e) {
      // If asset doesn't exist, use haptic feedback
      await _playHapticFeedback();
    }
  }

  /// Play haptic feedback as notification
  Future<void> _playHapticFeedback() async {
    try {
      // Use haptic feedback for notification
      HapticFeedback.heavyImpact();

      // Add a small delay and play again for notification effect
      await Future.delayed(const Duration(milliseconds: 300));
      HapticFeedback.heavyImpact();

      await Future.delayed(const Duration(milliseconds: 300));
      HapticFeedback.heavyImpact();

      _isPlaying = false;
      print('🔊 Playing haptic feedback notification');
    } catch (e) {
      print('❌ Error playing haptic feedback: $e');
      _isPlaying = false;
    }
  }

  /// Enable/disable sound notifications
  void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
    print('🔊 Sound notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if sound is enabled
  bool get isSoundEnabled => _isSoundEnabled;

  /// Stop any currently playing sound
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      print('🔊 Sound stopped');
    } catch (e) {
      print('❌ Error stopping sound: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      print('🔊 SoundNotificationService disposed');
    } catch (e) {
      print('❌ Error disposing SoundNotificationService: $e');
    }
  }
}
