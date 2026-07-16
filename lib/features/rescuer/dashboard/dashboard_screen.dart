import 'package:flutter/material.dart';
import 'map/osm_map_widget.dart';
import 'table/survivors_table_widget.dart';
import 'ai/ai_planner_widget.dart';

// Central Rescuer Dashboard UI for Desktop / Web.
class RescuerDashboardScreen extends StatefulWidget {
  const RescuerDashboardScreen({super.key});

  @override
  State<RescuerDashboardScreen> createState() => _RescuerDashboardScreenState();
}

class _RescuerDashboardScreenState extends State<RescuerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resku Command Center Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync with Mobile Collector',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading database updates from mobile collector...')),
              );
            },
          ),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Panel - Map & Table
        Expanded(
          flex: 3,
          child: Column(
            children: const [
              Expanded(flex: 3, child: OsmMapWidget()),
              Divider(height: 1),
              Expanded(flex: 2, child: SurvivorsTableWidget()),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Right Panel - AI Triage Recommendations & Broadcast console
        const Expanded(
          flex: 1,
          child: AiPlannerWidget(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: const [
          TabBar(
            labelColor: Colors.blue,
            tabs: [
              Tab(icon: Icon(Icons.map), text: 'Map'),
              Tab(icon: Icon(Icons.list), text: 'Survivors'),
              Tab(icon: Icon(Icons.psychology), text: 'AI Plan'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                OsmMapWidget(),
                SurvivorsTableWidget(),
                AiPlannerWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
