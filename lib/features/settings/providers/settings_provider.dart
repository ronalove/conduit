import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings keys.
const _notificationsEnabledKey = 'notifications_enabled';
const _soundEnabledKey = 'sound_enabled';
const _compactModeKey = 'compact_mode';
const _showTimestampsKey = 'show_timestamps';

/// App settings state.
class SettingsState {
  const SettingsState({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.compactMode = true,
    this.showTimestamps = true,
  });

  /// Whether notifications are enabled.
  final bool notificationsEnabled;

  /// Whether sounds are enabled.
  final bool soundEnabled;

  /// Whether to use compact message display.
  final bool compactMode;

  /// Whether to show timestamps.
  final bool showTimestamps;

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? compactMode,
    bool? showTimestamps,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      compactMode: compactMode ?? this.compactMode,
      showTimestamps: showTimestamps ?? this.showTimestamps,
    );
  }
}

/// Settings provider.
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

/// Settings notifier.
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = SettingsState(
        notificationsEnabled: prefs.getBool(_notificationsEnabledKey) ?? true,
        soundEnabled: prefs.getBool(_soundEnabledKey) ?? true,
        compactMode: prefs.getBool(_compactModeKey) ?? true,
        showTimestamps: prefs.getBool(_showTimestampsKey) ?? true,
      );
    } catch (_) {
      // Use defaults on error
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, state.notificationsEnabled);
      await prefs.setBool(_soundEnabledKey, state.soundEnabled);
      await prefs.setBool(_compactModeKey, state.compactMode);
      await prefs.setBool(_showTimestampsKey, state.showTimestamps);
    } catch (_) {
      // Ignore save errors
    }
  }

  /// Toggle notifications.
  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _save();
  }

  /// Toggle sound.
  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    await _save();
  }

  /// Toggle compact mode.
  Future<void> setCompactMode(bool enabled) async {
    state = state.copyWith(compactMode: enabled);
    await _save();
  }

  /// Toggle timestamps.
  Future<void> setShowTimestamps(bool enabled) async {
    state = state.copyWith(showTimestamps: enabled);
    await _save();
  }

  /// Clear all settings.
  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      state = const SettingsState();
    } catch (_) {
      // Ignore errors
    }
  }
}
