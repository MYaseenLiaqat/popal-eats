import 'package:flutter/foundation.dart';

/// Notifies admin shell pages when approval or platform data changes.
class AdminPortalNotifier extends ChangeNotifier {
  void notifyApprovalsChanged() => notifyListeners();

  void notifyPlatformDataChanged() => notifyListeners();
}
