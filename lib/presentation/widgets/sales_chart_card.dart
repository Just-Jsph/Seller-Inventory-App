import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/dashboard_repository.dart';

class SalesChartCard extends StatelessWidget {
  final List<DailySalesData> data;
  final int selectedDays;
  final Function(int days) onDaysChanged;
  final bool isLoading;

  const SalesChartCard({
    super.key,
    required this.data,
    required this.selectedDays,
    required this.onDaysChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate totals
    final totalCents = data.fold<int>(0, (sum, item) => sum + item.totalSalesCents);
    final avgCents = data.isNotEmpty ? (totalCents / data.length).round() : 0;

    // Calculate max Y for chart scale
    double maxY = 100.0;
    for (final item in data) {
      final val = Money.toDouble(item.totalSalesCents);
      if (val > maxY) {
        maxY = val;
      }
    }
    maxY = (maxY * 1.25).ceilToDouble(); // Give top margin padding

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Title + Segmented Time Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.show_chart_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sales Revenue Trend',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: ${Money.format(totalCents)} • Avg: ${Money.format(avgCents)}/day',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Days selector chips
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [7, 14, 30].map((days) {
                      final isSelected = selectedDays == days;
                      return GestureDetector(
                        onTap: () => onDaysChanged(days),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            '${days}D',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Chart area
            SizedBox(
              height: 210,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : data.isEmpty
                      ? Center(
                          child: Text(
                            'No sales recorded for this period.',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            ),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: maxY > 0 ? (maxY / 4) : 25,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.grey.shade200,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 42,
                                  interval: maxY > 0 ? (maxY / 4) : 25,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const SizedBox.shrink();
                                    String text = '₱${value.toInt()}';
                                    if (value >= 1000) {
                                      text = '₱${(value / 1000).toStringAsFixed(1)}k';
                                    }
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= data.length) {
                                      return const SizedBox.shrink();
                                    }

                                    // Filter label frequency for 14 or 30 days to avoid overlap
                                    if (selectedDays > 7) {
                                      final skipInterval = selectedDays == 14 ? 2 : 5;
                                      if (index % skipInterval != 0 && index != data.length - 1) {
                                        return const SizedBox.shrink();
                                      }
                                    }

                                    final label = data[index].dayLabel;
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: (data.length - 1).toDouble().clamp(0, 30),
                            minY: 0,
                            maxY: maxY,
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (spot) => isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.grey.shade900,
                                tooltipBorder: BorderSide(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                ),
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final idx = spot.x.toInt();
                                    if (idx >= 0 && idx < data.length) {
                                      final item = data[idx];
                                      return LineTooltipItem(
                                        '${item.dayLabel}\n${Money.format(item.totalSalesCents)}\n${item.transactionCount} sale(s)',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          height: 1.3,
                                        ),
                                      );
                                    }
                                    return null;
                                  }).toList();
                                },
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(data.length, (i) {
                                  return FlSpot(
                                    i.toDouble(),
                                    Money.toDouble(data[i].totalSalesCents),
                                  );
                                }),
                                isCurved: true,
                                curveSmoothness: 0.35,
                                color: AppColors.primary,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: data.length <= 14,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 4,
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                      strokeColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                                      AppColors.primary.withValues(alpha: 0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
