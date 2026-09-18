import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/curve_data_point.dart';

class LearningCurveChart extends StatelessWidget {
  final List<CurveDataPoint> points;

  const LearningCurveChart({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final tertiaryColor = theme.colorScheme.tertiary;

    if (points.isEmpty) {
      return Center(
        child: Text(
          'Chưa có dữ liệu ôn tập. Hãy bắt đầu học để vẽ đường cong học tập!',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final spotsWords = <FlSpot>[];
    final spotsEasiness = <FlSpot>[];

    for (var i = 0; i < points.length; i++) {
      spotsWords.add(FlSpot(i.toDouble(), points[i].wordCount.toDouble()));
      // Scale easiness (1.3 - 3.5) for visibility
      spotsEasiness.add(FlSpot(i.toDouble(), points[i].avgEasiness));
    }

    final maxWords = points.map((p) => p.wordCount).fold(0, (a, b) => a > b ? a : b);
    final maxY = (maxWords > 10 ? maxWords + 2 : 10).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Số lượt ôn tập',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: tertiaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Hệ số dễ (EF)',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < points.length) {
                        final d = points[index].date;
                        final parts = d.split('-');
                        final label = parts.length == 3 ? '${parts[1]}/${parts[2]}' : d;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                // Line 1: Word Count / Review Count
                LineChartBarData(
                  spots: spotsWords,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: primaryColor,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: primaryColor.withOpacity(0.12),
                  ),
                ),
                // Line 2: Easiness Factor (EF)
                LineChartBarData(
                  spots: spotsEasiness,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: tertiaryColor,
                  barWidth: 2,
                  dashArray: [5, 5],
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: tertiaryColor,
                      strokeWidth: 1.5,
                      strokeColor: theme.colorScheme.surface,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) =>
                      theme.colorScheme.surfaceContainerHighest,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final index = barSpot.x.toInt();
                      final pt = points[index];
                      if (barSpot.barIndex == 0) {
                        return LineTooltipItem(
                          '${pt.date}\n${pt.wordCount} lượt ôn (${pt.correctReviews} đúng, ${pt.wrongReviews} sai)',
                          TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      } else {
                        return LineTooltipItem(
                          'Hệ số dễ (EF): ${pt.avgEasiness}',
                          TextStyle(
                            color: tertiaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
