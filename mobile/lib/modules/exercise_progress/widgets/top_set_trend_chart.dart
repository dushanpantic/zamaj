import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/date_formatter.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';

/// A line chart of an exercise's top-set weight over time.
///
/// Every colour, spacing, and label style is pulled from the design tokens; the
/// x-axis is evenly spaced by session index (chronological), with each point's
/// real date on the bottom axis. Tapping a point reveals its source workout day
/// plus weight × reps. The whole chart is wrapped in a [Semantics] node carrying
/// a one-line spoken summary so screen readers aren't handed a bare canvas.
class TopSetTrendChart extends StatelessWidget {
  const TopSetTrendChart({
    super.key,
    required this.series,
    required this.displayName,
  });

  final ExerciseProgressSeries series;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final points = series.points;
    final lastIndex = points.length - 1;

    final weights = points.map((p) => p.topSetWeightKg).toList();
    final maxWeight = weights.reduce(math.max);
    final minWeight = weights.reduce(math.min);
    final pad = math.max(_gridStep, (maxWeight - minWeight) * _padFraction);
    final minY = math.max(0.0, _floorToGrid(minWeight - pad));
    final maxY = _ceilToGrid(maxWeight + pad);
    final yInterval = _yInterval(minY, maxY);
    final xInterval = points.length <= _maxXLabels
        ? 1.0
        : (lastIndex / (_maxXLabels - 1)).ceilToDouble();

    final labelStyle = AppTypography.standard.numeric.copyWith(
      color: colors.onSurfaceMuted,
    );

    return Semantics(
      label: _summary(points),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            right: AppSpacing.md,
          ),
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: lastIndex.toDouble(),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colors.outline,
                    strokeWidth: AppStroke.hairline,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: colors.outline,
                    width: AppStroke.hairline,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      reservedSize: _yAxisWidth,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          WeightFormatter.formatKg(value),
                          style: labelStyle,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: xInterval,
                      reservedSize: _xAxisHeight,
                      getTitlesWidget: (value, meta) {
                        final i = value.round();
                        if (i < 0 || i >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final date = points[i].date;
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${date.month}/${date.day}',
                            style: labelStyle,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colors.surfaceElevated,
                    getTooltipItems: (touchedSpots) => [
                      for (final spot in touchedSpots)
                        _tooltipItem(points[spot.spotIndex], colors),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].topSetWeightKg),
                    ],
                    isCurved: false,
                    color: colors.primary,
                    barWidth: AppStroke.emphasis,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: AppSpacing.xs,
                            color: colors.primary,
                            strokeColor: colors.primary,
                            strokeWidth: AppStroke.hairline,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  LineTooltipItem _tooltipItem(ProgressPoint point, AppColors colors) {
    final value =
        '${WeightFormatter.formatKg(point.topSetWeightKg)} kg × ${point.reps}';
    return LineTooltipItem(
      '${point.sourceWorkoutDayName}\n$value',
      AppTypography.standard.bodySmall.copyWith(color: colors.onSurface),
    );
  }

  String _summary(List<ProgressPoint> points) {
    final latest = points.last;
    final weight = WeightFormatter.formatKg(latest.topSetWeightKg);
    return '$displayName: ${points.length} sessions, latest top set '
        '$weight kg on ${DateFormatter.isoDate(latest.date)}.';
  }

  static const double _aspectRatio = 1.6;
  static const double _padFraction = 0.15;
  static const double _gridStep = 2.5;
  static const double _yAxisWidth = AppSpacing.xxl + AppSpacing.sm;
  static const double _xAxisHeight = AppSpacing.xl;
  static const int _maxXLabels = 5;

  static double _floorToGrid(double v) =>
      (v / _gridStep).floorToDouble() * _gridStep;
  static double _ceilToGrid(double v) =>
      (v / _gridStep).ceilToDouble() * _gridStep;

  /// A clean weight step that keeps the axis to roughly four gridlines and lands
  /// on the 2.5 kg grid so labels read as whole/half kilos.
  static double _yInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 0) return _gridStep;
    final raw = range / 4;
    return math.max(_gridStep, (raw / _gridStep).ceilToDouble() * _gridStep);
  }
}
