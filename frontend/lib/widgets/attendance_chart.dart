import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendanceChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> report;

  const AttendanceChartWidget({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final top5 =
        report
            .map(
              (e) => {
                'name': e['name'].split(' ').first,
                'hours': (e['total_hours'] as num).toDouble(),
              },
            )
            .toList()
          ..sort((a, b) => b['hours'].compareTo(a['hours']))
          ..take(5);

    final xAxisLabels = top5.map((e) => e['name'] as String).toList();
    final yAxisValues = top5.map((e) => e['hours'] as double).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Top 5 Employees by Hours",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= xAxisLabels.length) {
                            return const Text('');
                          }
                          return RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              xAxisLabels[index],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}h');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                  barGroups: yAxisValues.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: Colors.blue,
                          width: 24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
