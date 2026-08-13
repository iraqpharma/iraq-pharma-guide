import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../core/l10n/app_strings.dart';

class ConnectivityService {
  ConnectivityService._();
  static final instance = ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get onStatusChange => _controller.stream;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void init() {
    _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
  }

  void dispose() => _controller.close();
}

/// Widget يُعرض في أي شاشة — يستمع لتغيّر الإنترنت ويُظهر SnackBar
class ConnectivityListener extends StatefulWidget {
  final Widget child;
  const ConnectivityListener({super.key, required this.child});

  @override
  State<ConnectivityListener> createState() => _ConnectivityListenerState();
}

class _ConnectivityListenerState extends State<ConnectivityListener> {
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ConnectivityService.instance.onStatusChange.listen(_onStatusChange);
  }

  void _onStatusChange(bool isOnline) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final s = context.s;
    if (isOnline) {
      messenger.showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.wifi_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(s.connectedToInternet,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(s.noInternetConnection,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 1), // يبقى حتى يعود الإنترنت
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
