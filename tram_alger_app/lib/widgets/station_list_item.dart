import 'package:flutter/material.dart';
import '../models/station.dart';
import '../models/eta_response.dart';

class StationListItem extends StatelessWidget {
  final Station station;
  final ETAResponse? eta;
  final bool isSelected;
  final VoidCallback onTap;

  const StationListItem({
    super.key,
    required this.station,
    this.eta,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? const Color(0xFFE8F5E9) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: station.isTerminal
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFF4CAF50),
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
              const SizedBox(width: 16),
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
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (station.isTerminal)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B5E20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'TERMINAL',
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
                          fontSize: 14,
                          direction: TextDirection.rtl,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (eta != null) ...[
                          Icon(
                            eta!.source == 'gps'
                                ? Icons.gps_fixed
                                : Icons.schedule,
                            size: 14,
                            color: eta!.source == 'gps'
                                ? const Color(0xFF1B5E20)
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            eta!.source == 'gps' ? 'GPS' : 'Schedule',
                            style: TextStyle(
                              fontSize: 12,
                              color: eta!.source == 'gps'
                                  ? const Color(0xFF1B5E20)
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            eta!.formattedTime,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ] else
                          Text(
                            'Tap for ETA',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
