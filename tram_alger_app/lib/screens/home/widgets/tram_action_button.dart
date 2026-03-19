import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/gps_tracking_provider.dart';

class TramActionButton extends StatelessWidget {
  const TramActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GpsTrackingProvider>(
      builder: (context, gps, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _toggleGps(context, gps),
            style: ElevatedButton.styleFrom(
              backgroundColor: gps.isTracking ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (gps.isTracking) ...[
                  _PulsingDot(),
                  const SizedBox(width: 12),
                  const Text(
                    'ايقاف المشاركة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.directions_tram, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'انا داخل الترام الان',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleGps(BuildContext context, GpsTrackingProvider gps) async {
    if (gps.isTracking) {
      gps.stopTracking();
    } else {
      final hasPermission = await gps.checkPermission();
      if (hasPermission) {
        gps.startTracking(0);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission required'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.5 + _controller.value * 0.5),
          ),
        );
      },
    );
  }
}
