import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/wheel_cycle_provider.dart';
import '../../../models/wheel_cycle.dart';

class ActiveWheelCycleCard extends ConsumerWidget {
  const ActiveWheelCycleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycle = ref.watch(wheelCycleProvider);

    return cycle.when(
      loading: () => const _LoadingCard(),
      error: (error, stack) => const _ErrorCard(),
      data: (wheel) => _WheelCycleCard(wheel: wheel),
    );
  }
}

class _WheelCycleCard extends StatelessWidget {
  final WheelCycle wheel;

  const _WheelCycleCard({required this.wheel});

  @override
  Widget build(BuildContext context) {
    final stateLabel = _labelForState(wheel.state);
    final description = _descriptionForState(wheel.state);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Wheel Cycle",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              stateLabel,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text("Cycle Count: ${wheel.cycleCount}"),
            if (wheel.lastTransition != null)
              Text("Last Transition: ${wheel.lastTransition}"),
          ],
        ),
      ),
    );
  }

  String _labelForState(WheelCycleState state) {
    switch (state) {
      case WheelCycleState.idle:
        return "Idle";
      case WheelCycleState.cspOpen:
        return "CSP Open";
      case WheelCycleState.assigned:
        return "Assigned";
      case WheelCycleState.sharesOwned:
        return "Shares Owned";
      case WheelCycleState.ccOpen:
        return "Covered Call Open";
      case WheelCycleState.calledAway:
        return "Called Away";
    }
  }

  String _descriptionForState(WheelCycleState state) {
    switch (state) {
      case WheelCycleState.idle:
        return "No active wheel positions. Ready to start a new cycle.";
      case WheelCycleState.cspOpen:
        return "You have an active cash-secured put.";
      case WheelCycleState.assigned:
        return "You were assigned. Shares should now be in your account.";
      case WheelCycleState.sharesOwned:
        return "You own shares and can sell a covered call.";
      case WheelCycleState.ccOpen:
        return "You have an active covered call.";
      case WheelCycleState.calledAway:
        return "Your shares were called away. The wheel can restart.";
    }
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text("Loading wheel cycle..."),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text("Unable to load wheel cycle"),
      ),
    );
  }
}
