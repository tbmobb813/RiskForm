import 'parameter_range.dart';

final Map<String, Map<String, ParameterRange>> parameterPresets = {
  'Wheel': {
    'dte': const ParameterRange(start: 30, end: 45, step: 5),
    'delta': const ParameterRange(start: 0.15, end: 0.25, step: 0.05),
    'width': const ParameterRange(start: 1, end: 3, step: 1),
  },
  'Credit Spread': {
    'dte': const ParameterRange(start: 20, end: 35, step: 5),
    'delta': const ParameterRange(start: 0.10, end: 0.30, step: 0.05),
    'width': const ParameterRange(start: 2, end: 5, step: 1),
  },
  'Iron Condor': {
    'dte': const ParameterRange(start: 25, end: 45, step: 5),
    'delta': const ParameterRange(start: 0.10, end: 0.20, step: 0.05),
    'width': const ParameterRange(start: 3, end: 5, step: 1),
  },
  'Neutral Income': {
    'dte': const ParameterRange(start: 20, end: 30, step: 5),
    'delta': const ParameterRange(start: 0.10, end: 0.15, step: 0.05),
    'width': const ParameterRange(start: 1, end: 2, step: 1),
  },
};
