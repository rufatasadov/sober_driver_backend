import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundNotificationService {
  static final SoundNotificationService _instance =
      SoundNotificationService._internal();
  factory SoundNotificationService() => _instance;
  SoundNotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  bool _isPlaying = false;

  /// Initialize the sound service
  Future<void> initialize() async {
    try {
      // Set audio context for better performance
      await _audioPlayer.setAudioContext(AudioContext());

      print('🔊 SoundNotificationService initialized');
    } catch (e) {
      print('❌ Error initializing SoundNotificationService: $e');
    }
  }

  /// Play new order notification sound
  Future<void> playNewOrderSound() async {
    if (_isPlaying) return;

    try {
      _isPlaying = true;

      // Play sound if enabled
      if (_isSoundEnabled) {
        await _playSystemNotificationSound();
        print('🔊 Playing new order notification sound');
      } else {
        // If sound is disabled, just play vibration
        await _playHapticFeedback();
        _isPlaying = false;
      }
    } catch (e) {
      print('❌ Error playing new order sound: $e');
      _isPlaying = false;

      // Fallback to haptic feedback
      await _playHapticFeedback();
    }
  }

  /// Play assigned order notification sound
  Future<void> playAssignedOrderSound() async {
    if (_isPlaying) return;

    try {
      _isPlaying = true;

      // Play sound if enabled
      if (_isSoundEnabled) {
        await _audioPlayer.play(AssetSource('sounds/new_assigned_order.mp3'));
        _audioPlayer.onPlayerComplete.listen(
          (event) {
            _isPlaying = false;
          },
          onError: (error) {
            _isPlaying = false;
            _playHapticFeedback();
          },
        );
        print('🔊 Playing assigned order notification sound');
      } else {
        // If sound is disabled, just play vibration
        await _playHapticFeedback();
        _isPlaying = false;
      }
    } catch (e) {
      print('❌ Error playing assigned order sound: $e');
      _isPlaying = false;

      // Fallback to haptic feedback
      await _playHapticFeedback();
    }
  }

  /// Play broadcast order notification sound
  Future<void> playBroadcastOrderSound() async {
    if (_isPlaying) return;

    try {
      _isPlaying = true;

      // Play sound if enabled
      if (_isSoundEnabled) {
        await _playSystemNotificationSound();
        print('🔊 Playing broadcast order notification sound');
      } else {
        // If sound is disabled, just play vibration
        await _playHapticFeedback();
        _isPlaying = false;
      }
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
      // Try to play asset sound first
      await _audioPlayer.play(AssetSource('sounds/new_order.mp3'));

      // Listen for completion
      _audioPlayer.onPlayerComplete.listen(
        (event) {
          _isPlaying = false;
        },
        onError: (error) {
          _isPlaying = false;
          print('❌ Error in audio player: $error');
          // Fallback to haptic feedback
          _playHapticFeedback();
        },
      );
    } catch (e) {
      print('❌ Error playing sound asset: $e');
      // If asset doesn't exist, use haptic feedback
      _isPlaying = false;
      await _playHapticFeedback();
    }
  }

  /// Play haptic feedback as notification (vibration)
  Future<void> _playHapticFeedback() async {
    if (!_isVibrationEnabled) return;

    try {
      // Use haptic feedback for notification (vibration)
      HapticFeedback.heavyImpact();

      // Add a small delay and play again for notification effect
      await Future.delayed(const Duration(milliseconds: 300));
      HapticFeedback.heavyImpact();

      await Future.delayed(const Duration(milliseconds: 300));
      HapticFeedback.heavyImpact();

      print('📳 Playing vibration notification');
    } catch (e) {
      print('❌ Error playing haptic feedback: $e');
    }
  }

  /// Enable/disable sound notifications
  void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
    print('🔊 Sound notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if sound is enabled
  bool get isSoundEnabled => _isSoundEnabled;

  /// Enable/disable vibration notifications
  void setVibrationEnabled(bool enabled) {
    _isVibrationEnabled = enabled;
    print('📳 Vibration notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if vibration is enabled
  bool get isVibrationEnabled => _isVibrationEnabled;

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
