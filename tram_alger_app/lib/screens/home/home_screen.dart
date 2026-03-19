import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stations_provider.dart';
import '../../providers/eta_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/gps_tracking_provider.dart';
import '../station_detail/station_detail_screen.dart';
import 'widgets/offline_banner.dart';
import 'widgets/station_eta_card.dart';
import 'widgets/tram_action_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentDirection = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final stationsProvider = context.read<StationsProvider>();
    final etaProvider = context.read<EtaProvider>();

    await stationsProvider.loadStations();

    if (stationsProvider.outboundStations.isNotEmpty) {
      final stationIds = stationsProvider.outboundStations
          .take(10)
          .map((s) => s.id)
          .toList();
      await etaProvider.loadAllEtas(stationIds, _currentDirection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Tram Alger'),
            Text(
              'Ligne 1',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<GpsTrackingProvider>(
            builder: (context, gps, _) {
              return Switch(
                value: gps.isTracking,
                onChanged: (value) {
                  if (value) {
                    gps.checkPermission().then((has) {
                      if (has) {
                        gps.startTracking(_currentDirection);
                      }
                    });
                  } else {
                    gps.stopTracking();
                  }
                },
                activeColor: Colors.white,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Aller'),
                  icon: Icon(Icons.arrow_forward),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Retour'),
                  icon: Icon(Icons.arrow_back),
                ),
              ],
              selected: {_currentDirection},
              onSelectionChanged: (selection) {
                setState(() {
                  _currentDirection = selection.first;
                });
                _loadEtasForDirection();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Prochaines arrivees',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer2<StationsProvider, EtaProvider>(
              builder: (context, stations, eta, _) {
                if (stations.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stationList = _currentDirection == 0
                    ? stations.outboundStations
                    : stations.inboundStations;

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: stationList.length,
                    itemBuilder: (context, index) {
                      final station = stationList[index];
                      final etaResult = eta.getEta(station.id, _currentDirection);

                      return StationEtaCard(
                        station: station,
                        eta: etaResult,
                        onTap: () => _openStationDetail(station.id, station.name),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const TramActionButton(),
        ],
      ),
    );
  }

  void _loadEtasForDirection() {
    final stations = context.read<StationsProvider>();
    final eta = context.read<EtaProvider>();

    final stationList = _currentDirection == 0
        ? stations.outboundStations
        : stations.inboundStations;

    final stationIds = stationList.take(10).map((s) => s.id).toList();
    eta.loadAllEtas(stationIds, _currentDirection);
  }

  void _openStationDetail(int stationId, String stationName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StationDetailScreen(
          stationId: stationId,
          stationName: stationName,
          initialDirection: _currentDirection,
        ),
      ),
    );
  }
}
