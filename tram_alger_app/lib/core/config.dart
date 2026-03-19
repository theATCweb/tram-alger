class AppConfig {
  static const String apiBaseUrl = 'https://tram-alger-production.up.railway.app';
  static const int outboundRouteId = 4;
  static const int inboundRouteId  = 5;
  static const int etaCacheSec        = 30;
  static const int stationCacheHours  = 24;
  static const int gpsPingIntervalSec = 15;
  static const int gpsAutoStopSec     = 90;
  static const int notificationDelaySec = 120;
  static const double gpsMinSpeedKmh = 2.0;
}
