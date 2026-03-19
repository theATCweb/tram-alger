import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;

  ConnectivityProvider() {
    _init();
  }

  bool get isOnline => _isOnline;

  void _init() {
    Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
    });
  }

  Future<void> check() async {
    final results = await Connectivity().checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _isOnline = result != ConnectivityResult.none;
    notifyListeners();
  }
}
