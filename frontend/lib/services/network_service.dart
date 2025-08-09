// services/network_service.dart
// ignore_for_file: unrelated_type_equality_checks
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged async* {
    yield await isConnected;
    await for (final result in _connectivity.onConnectivityChanged) {
      yield result != ConnectivityResult.none;
    }
  }

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
