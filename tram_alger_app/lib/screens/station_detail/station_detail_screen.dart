import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config.dart';
import '../../providers/eta_provider.dart';
import '../../providers/gps_tracking_provider.dart';
import '../../services/notification_service.dart';
import 'widgets/direction_toggle.dart';
import 'widgets/eta_display.dart';

class StationDetailScreen extends StatefulWidget {
  final int stationId;
  final String stationName;
  final int initialDirection;

  const StationDetailScreen({
    super.key,
    required this.stationId,
    required this.stationName,
    required this.initialDirection,
  });

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  int _direction = 0;
  Timer? _refreshTimer;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _direction = widget.initialDirection;
    _loadEta();
    _startAutoRefresh();
    _startNotificationTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadEta(),
    );
  }

  void _startNotificationTimer() {
    _notificationTimer = Timer(
      Duration(seconds: AppConfig.notificationDelaySec),
      _showNotificationIfNeeded,
    );
  }

  void _showNotificationIfNeeded() {
    final gps = context.read<GpsTrackingProvider>();
    if (!gps.isTracking) {
      NotificationService.showTramPrompt();
    }
  }

  Future<void> _loadEta() async {
    await context.read<EtaProvider>().loadEta(widget.stationId, _direction);
    if (mounted) setState(() {});
  }

  void _onDirectionChanged(int direction) {
    setState(() {
      _direction = direction;
    });
    _loadEta();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stationName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DirectionToggle(
              selectedDirection: _direction,
              onDirectionChanged: _onDirectionChanged,
            ),
            const SizedBox(height: 24),
            Consumer<EtaProvider>(
              builder: (context, etaProvider, _) {
                final eta = etaProvider.getEta(widget.stationId, _direction);

                if (eta == null) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!eta.hasData) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune donnee disponible',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadEta,
                            child: const Text('Reessayer'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: SingleChildScrollView(
                    child: EtaDisplay(eta: eta),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
