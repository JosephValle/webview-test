import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

enum Mode { time, date }

class _ChartScreenState extends State<ChartScreen> {
  Mode _mode = Mode.date;
  late List<DateTime> _dates;
  late List<int> _values;

  @override
  void initState() {
    super.initState();
    _dates = generateTenRandomDateTimesWithinAMonthOfNow();
    _values = generate10RandomNumbers();
    _dates.sort();
  }

  /// Generate 10 random DateTimes within ~30 days of "now".
  List<DateTime> generateTenRandomDateTimesWithinAMonthOfNow({int count = 10}) {
    final List<DateTime> dates = [];
    final DateTime now = DateTime.now();
    final Random random = Random();
    for (int i = 0; i < count; i++) {
      final int randomDay = random.nextInt(30) + 1;
      final int randomHour = random.nextInt(24);
      final int randomMinute = random.nextInt(60);
      final int randomSecond = random.nextInt(60);
      dates.add(
        DateTime(
          now.year,
          now.month,
          randomDay,
          randomHour,
          randomMinute,
          randomSecond,
        ),
      );
    }
    dates.sort();
    return dates;
  }

  /// Generate 10 random integer values (positive or negative).
  List<int> generate10RandomNumbers({int maxVal = 50, int count = 10}) {
    final List<int> numbers = [];
    final Random random = Random();
    for (int i = 0; i < count; i++) {
      final int multiplier = random.nextBool() ? 1 : -1;
      numbers.add(random.nextInt(maxVal) * multiplier);
    }
    return numbers;
  }

  /// For date mode, we roughly divide the range into 7 intervals for bottom titles.
  double _getXIntervalForDate() {
    final double totalRange = (_dates.last.millisecondsSinceEpoch -
            _dates.first.millisecondsSinceEpoch)
        .toDouble();
    // Let's choose to have 7 intervals across the entire date range
    return totalRange / 7;
  }

  /// Builds the line chart for date mode
  Widget _buildLineChart() {
    // We need a list of spots based on the actual DateTime range.
    final spots = _dates.asMap().entries.map((e) {
      final xVal = e.value.millisecondsSinceEpoch.toDouble();
      final yVal = _values[e.key].toDouble();
      return FlSpot(xVal, yVal);
    }).toList();

    // Determine minX and maxX
    final minX = _dates.first.millisecondsSinceEpoch.toDouble();
    final maxX = _dates.last.millisecondsSinceEpoch.toDouble();
    final minY = _values.reduce(min).toDouble();
    final maxY = _values.reduce(max).toDouble();

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
                  spot.x.toInt(),
                );
                final DateFormat formatter = DateFormat('MM/dd/yyyy hh:mm a');
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(2)} on ${formatter.format(dt)}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        minX: minX,
        maxX: maxX,
        minY: minY < 0 ? (minY * 1.1).floorToDouble() : 0,
        maxY: maxY > 0 ? (maxY * 1.1).ceilToDouble() : 0,
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              minIncluded: false,
              maxIncluded: false,
              interval: _getXIntervalForDate(),
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                // Convert x-axis ms to DateTime
                final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MM/dd').format(dt),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              maxIncluded: false,
              minIncluded: minX == 0,
              showTitles: true,
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Colors.blue,
            barWidth: 2,
          ),
        ],
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) {
            // Show a thicker line at y=0
            if (value == 0) {
              return const FlLine(color: Colors.black, strokeWidth: 2);
            }
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [2, 4],
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [2, 4],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    // 1) Aggregate data by hour of day (ignoring date portion).
    //    We just count how many submissions occur in each hour
    //    AND we'll also keep the actual values so we can compute the average.
    final Map<int, List<int>> hourToValues = {};
    for (int i = 0; i < _dates.length; i++) {
      final hour = _dates[i].hour;
      hourToValues.putIfAbsent(hour, () => []);
      hourToValues[hour]!.add(_values[i]);
    }

    // 2) Flatten all hour values to find global min/max
    //    (Used to color bars based on avg.)
    final allValues = hourToValues.values.expand((list) => list).toList();
    final int globalMin = allValues.isEmpty ? 0 : allValues.reduce(min);
    final int globalMax = allValues.isEmpty ? 0 : allValues.reduce(max);

    // Helper to map an hour's average → Color, from Red (min) → Yellow (mid) → Green (max)
    Color getBarColorFromAverage({
      required double avg,
      required int globalMin,
      required int globalMax,
    }) {
      // If all values are the same, default to yellow (or handle as desired).
      if (globalMin == globalMax) {
        return Colors.amber;
      }

      // Convert avg to fraction in [0..1].
      double fraction = (avg - globalMin) / (globalMax - globalMin);
      fraction = fraction.clamp(0.0, 1.0);

      // Red → Yellow for first half, Yellow → Green for second half
      if (fraction < 0.5) {
        return Color.lerp(Colors.red, Colors.amber, fraction * 2)!;
      } else {
        return Color.lerp(Colors.amber, Colors.green, (fraction - 0.5) * 2)!;
      }
    }

    // 3) Create BarChartGroupData for each hour in 0..23
    final barGroups = <BarChartGroupData>[];
    for (int hour = 0; hour < 24; hour++) {
      final values = hourToValues[hour] ?? [];
      final count = values.length;       // how many submissions this hour
      final double toY = count.toDouble();

      // Compute the average of the hour’s values
      double avg = 0;
      if (values.isNotEmpty) {
        avg = values.reduce((a, b) => a + b) / values.length;
      }

      // Determine the color for this bar, based on the hour's average
      final rodColor = getBarColorFromAverage(
        avg: avg,
        globalMin: globalMin,
        globalMax: globalMax,
      );

      barGroups.add(
        BarChartGroupData(
          x: hour,
          barRods: [
            BarChartRodData(
              toY: toY,
              color: rodColor,
              width: 16,
              borderSide:  BorderSide(
                color: Colors.black.withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              // thin gray outline for border
            ),
          ],
        ),
      );
    }

    // Helper to convert an hour (0..23) into a label like "11am - 12pm"
    String hourRangeLabel(int hour) {
      final int nextHour = (hour + 1) % 24;

      final startHour12 = (hour % 12 == 0) ? 12 : (hour % 12);
      final startAmPm = (hour < 12) ? 'am' : 'pm';

      final endHour12 = (nextHour % 12 == 0) ? 12 : (nextHour % 12);
      final endAmPm = (nextHour < 12) ? 'am' : 'pm';

      return '$startHour12$startAmPm - $endHour12$endAmPm';
    }

    // 4) Build the BarChart
    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final hour = group.x.toInt();
              final values = hourToValues[hour] ?? [];

              if (values.isEmpty) {
                // No submissions
                return BarTooltipItem(
                  '${hourRangeLabel(hour)}\n0 Submission',
                  const TextStyle(color: Colors.white),
                );
              } else if (values.length == 1) {
                // Only one submission
                return BarTooltipItem(
                  '${hourRangeLabel(hour)}\n'
                      '1 Submission\n'
                      'Value: ${values.first}',
                  const TextStyle(color: Colors.white),
                );
              } else {
                // Multiple submissions
                final count = values.length;
                final avg = values.reduce((a, b) => a + b) / values.length;
                final high = values.reduce(max);
                final low = values.reduce(min);

                return BarTooltipItem(
                  '${hourRangeLabel(hour)}\n'
                      '$count Submissions\n'
                      'Average: ${avg.toStringAsFixed(1)}\n'
                      'High: $high\n'
                      'Low: $low',
                  const TextStyle(color: Colors.white),
                );
              }
            },
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
              minIncluded: true,
              maxIncluded: false,
              showTitles: true,
              reservedSize: 40,
              // Use the highest count to choose an interval or just leave it default
              interval: hourToValues.values
                  .map((list) => list.length)
                  .fold(0, max)
                  .toDouble(),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              // step every 6 hours so you hit 0, 6, 12, 18
              interval: 6,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                // We'll only label 6, 12, 18
                if (hour == 6) {
                  return const Text('6am', style: TextStyle(fontSize: 10));
                } else if (hour == 12) {
                  return const Text('12pm', style: TextStyle(fontSize: 10));
                } else if (hour == 18) {
                  return const Text('6pm', style: TextStyle(fontSize: 10));
                }
                // Return an empty widget otherwise
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) {
            // Draw a thicker line at y=0
            if (value == 0) {
              return const FlLine(color: Colors.black, strokeWidth: 2);
            }
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [2, 4],
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [2, 4],
            );
          },
        ),
        // Our actual bar data
        barGroups: barGroups,

        // minY always 0, maxY is the largest count across all hours * 1.1
        minY: 0,
        maxY: hourToValues.values.map((list) => list.length).fold(0, max) * 1.1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort the data whenever we rebuild
    if (_mode == Mode.date) {
      _dates.sort();
    } else {
      // Sort by hour/minute if in time mode
      _dates.sort(
        (a, b) => a.hour.compareTo(b.hour) == 0
            ? a.minute.compareTo(b.minute)
            : a.hour.compareTo(b.hour),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chart Example')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Date Mode'),
                  Switch(
                    value: _mode == Mode.time,
                    onChanged: (bool value) {
                      setState(() {
                        _mode = value ? Mode.time : Mode.date;
                      });
                    },
                  ),
                  const Text('Time Mode'),
                ],
              ),
            ),

            // Chart area
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                    _mode == Mode.date ? _buildLineChart() : _buildBarChart(),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
