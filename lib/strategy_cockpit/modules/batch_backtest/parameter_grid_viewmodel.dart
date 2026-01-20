import 'package:flutter/foundation.dart';

import 'parameter_range.dart';

class ParameterGridViewModel extends ChangeNotifier {
  ParameterRange dte = const ParameterRange(start: 20, end: 45, step: 5);
  ParameterRange delta = const ParameterRange(start: 0.10, end: 0.30, step: 0.05);
  ParameterRange width = const ParameterRange(start: 1, end: 5, step: 1);

  List<Map<String, dynamic>> grid = [];

  ParameterGridViewModel() {
    _rebuildGrid();
  }

  void updateDte(ParameterRange r) {
    dte = r;
    _rebuildGrid();
  }

  void updateDelta(ParameterRange r) {
    delta = r;
    _rebuildGrid();
  }

  void updateWidth(ParameterRange r) {
    width = r;
    _rebuildGrid();
  }

  void applyPreset(Map<String, ParameterRange> preset) {
    dte = preset['dte']!;
    delta = preset['delta']!;
    width = preset['width']!;
    _rebuildGrid();
  }

  void _rebuildGrid() {
    final dtes = dte.expand();
    final deltas = delta.expand();
    final widths = width.expand();

    final newGrid = <Map<String, dynamic>>[];

    for (final d in dtes) {
      for (final del in deltas) {
        for (final w in widths) {
          newGrid.add({
            'dte': d.round(),
            'delta': del,
            'width': w,
          });
        }
      }
    }

    grid = newGrid;
    notifyListeners();
  }
}
