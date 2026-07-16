import 'package:flutter/material.dart';

// Table view displaying all discovered survivors in a list.
class SurvivorsTableWidget extends StatelessWidget {
  const SurvivorsTableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Survivor Roster',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Critical (3)'),
                      selected: false,
                      onSelected: (b) {},
                    ),
                    FilterChip(
                      label: const Text('Injured (5)'),
                      selected: false,
                      onSelected: (b) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Needs')),
                    DataColumn(label: Text('Last Updated')),
                    DataColumn(label: Text('GPS Coordinates')),
                  ],
                  rows: [
                    DataRow(cells: [
                      const DataCell(Text('John Doe')),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(4)),
                        child: const Text('Critical', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      )),
                      const DataCell(Text('First Aid, Water')),
                      const DataCell(Text('5 mins ago')),
                      const DataCell(Text('-6.2088, 106.8456')),
                    ]),
                    DataRow(cells: [
                      const DataCell(Text('Jane Smith')),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(4)),
                        child: const Text('Injured', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      )),
                      const DataCell(Text('Blankets / Warmth')),
                      const DataCell(Text('12 mins ago')),
                      const DataCell(Text('-6.2100, 106.8480')),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
