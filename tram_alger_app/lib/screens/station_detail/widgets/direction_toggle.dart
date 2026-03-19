import 'package:flutter/material.dart';

class DirectionToggle extends StatelessWidget {
  final int selectedDirection;
  final ValueChanged<int> onDirectionChanged;

  const DirectionToggle({
    super.key,
    required this.selectedDirection,
    required this.onDirectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
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
      selected: {selectedDirection},
      onSelectionChanged: (selection) {
        onDirectionChanged(selection.first);
      },
    );
  }
}
