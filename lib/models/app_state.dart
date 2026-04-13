import 'domain.dart';

/// Simple singleton holding the current session state.
/// No ChangeNotifier needed — role switches trigger full navigation replacement.
class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  UserRole currentRole = UserRole.adminManager;
  String currentUserName = 'Nigel Bond';
  String currentUserId = 'ADMIN001';

  void switchToAdmin() {
    currentRole = UserRole.adminManager;
    currentUserName = 'Nigel Bond';
    currentUserId = 'ADMIN001';
  }

  void switchToSiteManager() {
    currentRole = UserRole.siteManager;
    currentUserName = 'Tom Chen';
    currentUserId = 'SM001';
  }
}
