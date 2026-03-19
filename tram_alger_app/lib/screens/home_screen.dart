import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/station.dart';
import '../models/eta_response.dart';
import '../services/api_service.dart';
import '../widgets/station_list_item.dart';
import '../widgets/eta_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  List<Station> _stations = [];
  Map<int, ETAResponse> _etas = {};
  bool _loading = true;
  String? _error;
  int _direction = 0;
  int? _selectedStationId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _direction = _tabController.index;
        _selectedStationId = null;
        _etas.clear();
      });
    });
    _loadStations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routeId = _direction == 0 ? 4 : 5;
      final stations = await _apiService.getStations(routeId: routeId);
      setState(() {
        _stations = stations;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectStation(Station station) async {
    setState(() {
      _selectedStationId = station.id;
    });
    await _loadETA(station.id);
  }

  Future<void> _loadETA(int stationId) async {
    try {
      final eta = await _apiService.getETA(
        stationId: stationId,
        direction: _direction,
      );
      setState(() {
        _etas[stationId] = eta;
      });
    } catch (e) {
      // Silently fail, ETA will show as unavailable
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tram Alger'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Outbound', icon: Icon(Icons.arrow_forward)),
            Tab(text: 'Inbound', icon: Icon(Icons.arrow_back)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_selectedStationId != null && _etas[_selectedStationId] != null)
            ETACard(
              eta: _etas[_selectedStationId]!,
              station: _stations.firstWhere((s) => s.id == _selectedStationId),
              onClose: () => setState(() => _selectedStationId = null),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text('Error loading stations', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadStations,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStations,
                        child: ListView.builder(
                          itemCount: _stations.length,
                          itemBuilder: (context, index) {
                            final station = _stations[index];
                            return StationListItem(
                              station: station,
                              eta: _etas[station.id],
                              isSelected: station.id == _selectedStationId,
                              onTap: () => _selectStation(station),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
