import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

class AlarmService {
  final AudioPlayer _player = AudioPlayer();
  Timer? _stopTimer;
  bool _isPlaying = false;
  Uint8List? _cachedBeepWav;

  AlarmService() {
    _cachedBeepWav = _generateBeepWav(880, 1.0);
  }

  bool get isPlaying => _isPlaying;

  /// Memutar alarm sesuai pengaturan pengguna ('audio', 'vibrate', atau 'both')
  /// Berhenti otomatis setelah 10 detik atau saat stop() dipanggil.
  Future<void> triggerAlarm({
    required String alarmMode, // 'audio' | 'vibrate' | 'both'
    double volume = 1.0,
  }) async {
    stop(); // Hentikan alarm sebelumnya jika ada
    _isPlaying = true;

    final shouldPlayAudio = alarmMode == 'audio' || alarmMode == 'both';
    final shouldVibrate = alarmMode == 'vibrate' || alarmMode == 'both';

    if (shouldPlayAudio && _cachedBeepWav != null) {
      try {
        await _player.setVolume(volume.clamp(0.0, 1.0));
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(BytesSource(_cachedBeepWav!));
      } catch (e) {
        debugPrint('AlarmService audio error: $e');
      }
    }

    if (shouldVibrate) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          // Pola getar berulang: diam 400ms, getar 600ms
          await Vibration.vibrate(pattern: [400, 600, 400, 600], repeat: 0);
        }
      } catch (e) {
        debugPrint('AlarmService vibration error: $e');
      }
    }

    // Berhenti otomatis setelah 10 detik (Per requirement 4)
    _stopTimer = Timer(const Duration(seconds: 10), () {
      stop();
    });
  }

  void stop() {
    _stopTimer?.cancel();
    _stopTimer = null;
    _isPlaying = false;

    try {
      _player.stop();
    } catch (_) {}

    try {
      Vibration.cancel();
    } catch (_) {}
  }

  void dispose() {
    stop();
    _player.dispose();
  }

  /// Sintesis berkas WAV PCM 16-bit mono 22.05 kHz secara langsung di memori
  Uint8List _generateBeepWav(int frequencyHz, double durationSec) {
    const sampleRate = 22050;
    final numSamples = (sampleRate * durationSec).toInt();
    final dataSize = numSamples * 2;
    final fileSize = 44 + dataSize;

    final bytes = ByteData(fileSize);

    // RIFF Header
    bytes.setUint8(0, 0x52); // 'R'
    bytes.setUint8(1, 0x49); // 'I'
    bytes.setUint8(2, 0x46); // 'F'
    bytes.setUint8(3, 0x46); // 'F'
    bytes.setUint32(4, fileSize - 8, Endian.little);
    bytes.setUint8(8, 0x57);  // 'W'
    bytes.setUint8(9, 0x41);  // 'A'
    bytes.setUint8(10, 0x56); // 'V'
    bytes.setUint8(11, 0x45); // 'E'

    // fmt Chunk
    bytes.setUint8(12, 0x66); // 'f'
    bytes.setUint8(13, 0x6D); // 'm'
    bytes.setUint8(14, 0x74); // 't'
    bytes.setUint8(15, 0x20); // ' '
    bytes.setUint32(16, 16, Endian.little); // chunk size
    bytes.setUint16(20, 1, Endian.little);  // PCM format
    bytes.setUint16(22, 1, Endian.little);  // 1 channel (mono)
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    bytes.setUint16(32, 2, Endian.little); // block align
    bytes.setUint16(34, 16, Endian.little); // bits per sample

    // data Chunk
    bytes.setUint8(36, 0x64); // 'd'
    bytes.setUint8(37, 0x61); // 'a'
    bytes.setUint8(38, 0x74); // 't'
    bytes.setUint8(39, 0x61); // 'a'
    bytes.setUint32(40, dataSize, Endian.little);

    // Sine wave samples
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final sample = (sin(2 * pi * frequencyHz * t) * 26000).toInt();
      bytes.setInt16(44 + i * 2, sample, Endian.little);
    }

    return bytes.buffer.asUint8List();
  }
}
