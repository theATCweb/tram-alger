import 'package:flutter/material.dart';
import '../../../models/station.dart';
import '../../../models/eta_result.dart';

class StationEtaCard extends StatelessWidget {
  final Station station;
  final EtaResult? eta;
  final VoidCallback onTap;

  const StationEtaCard({
    super.key,
    required this.station,
    this.eta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: station.isTerminal
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${station.sequence}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            station.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (station.isTerminal)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TERM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (station.nameAr != null)
                      Text(
                        station.nameAr!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          direction: TextDirection.rtl,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (eta != null && eta!.hasData) ...[
                          _buildSourceBadge(context, eta!),
                        ] else
                          Text(
                            'Appuyez pour l\'ETA',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (eta != null && eta!.hasData) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      eta!.formattedMinutes,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      eta!.exactTime,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceBadge(BuildContext context, EtaResult eta) {
    final isGps = eta.source == 'gps';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isGps ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGps ? Icons.gps_fixed : Icons.schedule,
            size: 12,
            color: isGps ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(
            isGps ? 'GPS' : 'Horaire',
            style: TextStyle(
              fontSize: 11,
              color: isGps ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }
}
