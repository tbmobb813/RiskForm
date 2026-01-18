import 'package:flutter/material.dart';
import 'next_strategy_card.dart';
import 'active_positions_section.dart';
import 'account_snapshot_card.dart';
import 'tools_and_strategy_library.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              NextStrategyCard(),
              SizedBox(height: 16),
              ActivePositionsSection(),
              SizedBox(height: 16),
              AccountSnapshotCard(),
              SizedBox(height: 16),
              ToolsAndStrategyLibrary(),
            ],
          ),
        ),
      ),
    );
  }
}