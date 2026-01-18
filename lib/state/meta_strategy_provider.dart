import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/meta_strategy_controller.dart';

final metaStrategyControllerProvider = Provider<MetaStrategyController>((ref) {
  return MetaStrategyController();
});