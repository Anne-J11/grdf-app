// lib/auth/providers/user_provider.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  String get uid => _user?.uid ?? '';
  String get agenceId => _user?.agenceId ?? '';
  String get siteId => _user?.siteId ?? '';
  String get nomComplet => '${_user?.prenom ?? ''} ${_user?.nom ?? ''}'.trim();
  String get role => _user?.role ?? '';
  bool get isReferent => _user?.isReferent ?? false;
  bool get isManager => _user?.isManager ?? false;
  bool get isTechnicien => _user?.isTechnicien ?? false;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
