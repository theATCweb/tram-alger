import 'package:flutter/material.dart';
import '../../../models/eta_result.dart';

class EtaDisplay extends StatelessWidget {
  final EtaResult eta;

  const EtaDisplay({
    super.key,
    required this.eta,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              eta.formattedMinutes,
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              eta.exactTime,
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildSourceBadge(context),
            const SizedBox(height: 16),
            _buildConfidenceBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge(BuildContext context) {
    final isGps = eta.source == 'gps';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isGps ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGps ? Icons.gps_fixed : Icons.schedule,
            size: 20,
            color: isGps ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 8),
          Text(
            eta.sourceLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isGps ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Confidence',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '${(eta.confidence * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: eta.confidence,
            backgroundColor: Colors.grey[200],
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
