import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _notificationsKey = 'notifications_enabled';

class NotificationsNotifier extends StateNotifier<bool> {
  SharedPreferences? _prefs;

  NotificationsNotifier() : super(true) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    state = _prefs?.getBool(_notificationsKey) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    await _prefs?.setBool(_notificationsKey, state);
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, bool>((ref) {
  return NotificationsNotifier();
});
