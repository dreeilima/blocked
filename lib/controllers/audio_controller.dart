import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioController extends ChangeNotifier {
  static const String _soundKey = 'is_sound_on';
  static const String _musicKey = 'is_music_on';

  final AudioPlayer _sfxPlayer = AudioPlayer();
  // final AudioPlayer _musicPlayer = AudioPlayer(); // Futuro: Música

  bool _isSoundOn = true;
  bool _isMusicOn = true;

  bool get isSoundOn => _isSoundOn;
  bool get isMusicOn => _isMusicOn;

  AudioController() {
    _loadSettings();

    // Configurar áudio para não interromper outros apps se possível (mode low latency)
    _sfxPlayer.setReleaseMode(ReleaseMode.stop); // Efeitos rápidos
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundOn = prefs.getBool(_soundKey) ?? true;
    _isMusicOn = prefs.getBool(_musicKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _isSoundOn = !_isSoundOn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, _isSoundOn);
    notifyListeners();
  }

  // Future<void> toggleMusic() async { ... }

  // ----------- Actions -----------

  Future<void> playMove() async {
    if (!_isSoundOn) return;
    try {
      // Usando stop antes de play para evitar delay se spammar o botão
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/move.ogg'));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  Future<void> playWin() async {
    if (!_isSoundOn) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/win.ogg'));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  Future<void> playUnlock() async {
    if (!_isSoundOn) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/unlock.ogg'));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  Future<void> playButton() async {
    if (!_isSoundOn) return;
    try {
      // Opcional: usar soundpool para sons muito curtos e frequentes,
      // mas audioplayers modernos são rápidos o suficiente.
      // await _sfxPlayer.play(AssetSource('audio/click.mp3'), mode: PlayerMode.lowLatency);
    } catch (e) {
      // Debug silencioso
    }
  }
}
