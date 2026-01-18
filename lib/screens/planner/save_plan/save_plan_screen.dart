import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../state/planner_notifier.dart';
import '../../../models/trade_plan.dart';
import '../../../services/firebase/wheel_cycle_service.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../models/position.dart';
import '../../../models/wheel_cycle.dart';
import '../components/confirmation_summary_card.dart';
import '../components/notes_field.dart';
import '../components/tags_section.dart';

class SavePlanScreen extends ConsumerWidget {
  const SavePlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plannerNotifierProvider);
    final planner = ref.read(plannerNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Save Trade Plan"),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConfirmationSummaryCard(
                strategyName: state.strategyName,
                payoff: state.payoff,
                risk: state.risk,
              ),

              const SizedBox(height: 24),

              NotesField(
                initialValue: state.notes ?? "",
                onChanged: planner.updateNotes,
              ),

              const SizedBox(height: 24),

              TagsSection(
                selectedTags: state.tags,
                onChanged: planner.updateTags,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await planner.savePlan();
                    if (!ok) return;

                    // Build a local TradePlan representation based on current state
                    final plan = TradePlan(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      strategyId: state.strategyId ?? "",
                      strategyName: state.strategyName ?? "",
                      inputs: state.inputs!,
                      payoff: state.payoff!,
                      risk: state.risk!,
                      notes: state.notes ?? "",
                      tags: state.tags,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    // Minimal positions list to reflect planner intent
                    final positionsAfterSave = <Position>[];
                    if (plan.strategyId == "csp") {
                      positionsAfterSave.add(Position(
                        type: PositionType.csp,
                        symbol: plan.strategyName,
                        strategy: plan.strategyName,
                        quantity: plan.inputs.sharesOwned ?? 0,
                        expiration: plan.inputs.expiration ?? DateTime.now(),
                        isOpen: true,
                      ));
                    }

                    if (plan.strategyId == "cc") {
                      positionsAfterSave.add(Position(
                        type: PositionType.coveredCall,
                        symbol: plan.strategyName,
                        strategy: plan.strategyName,
                        quantity: plan.inputs.sharesOwned ?? 0,
                        expiration: plan.inputs.expiration ?? DateTime.now(),
                        isOpen: true,
                      ));
                    }

                    final wheelCycleService = ref.read(wheelCycleServiceProvider);
                    final auth = ref.read(authServiceProvider);
                    final uid = auth.currentUserId;

                    if (uid != null && positionsAfterSave.isNotEmpty) {
                      final previousCycle = await wheelCycleService.getCycle(uid) ??
                          WheelCycle(state: WheelCycleState.idle);

                      await wheelCycleService.updateCycle(
                        uid: uid,
                        previous: previousCycle,
                        positions: positionsAfterSave,
                      );
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Trade plan saved. No position has been placed."),
                        ),
                      );
                      context.goNamed("dashboard");
                    }
                  },
                  child: const Text("Save Trade Plan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}