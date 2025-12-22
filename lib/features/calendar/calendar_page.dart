import 'package:flutter/material.dart';

import '../auto_orders/models.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static final DateTime _anchorSunday = DateTime(2025, 11, 16);
  static const _weekdayLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final currentWeekStart = _weekStart(today);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Previous month',
                              onPressed: _goToPrevMonth,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            IconButton(
                              tooltip: 'Next month',
                              onPressed: _goToNextMonth,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _Legend(),
                    const SizedBox(height: 12),
                    _MonthGrid(
                      month: _visibleMonth,
                      currentWeekStart: currentWeekStart,
                      today: today,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToPrevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    });
  }

  static DateTime _weekStart(DateTime date) {
    final weekday = date.weekday % 7;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: weekday));
  }

  static _CycleInfo _cycleForDate(DateTime date) {
    final anchor = DateTime(
      _anchorSunday.year,
      _anchorSunday.month,
      _anchorSunday.day,
    );
    final weeksDelta = date.difference(anchor).inDays ~/ 7;
    final cycleIndex = ((weeksDelta % 4) + 4) % 4;
    switch (cycleIndex) {
      case 0:
        return const _CycleInfo(value: 1, color: CycleColor.red);
      case 1:
        return const _CycleInfo(value: 2, color: CycleColor.green);
      case 2:
        return const _CycleInfo(value: 3, color: CycleColor.blue);
      case 3:
      default:
        return const _CycleInfo(value: 4, color: CycleColor.yellow);
    }
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.currentWeekStart,
    required this.today,
  });

  final DateTime month;
  final DateTime currentWeekStart;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final gridStart = firstDay.subtract(Duration(days: firstWeekday));
    final days = List<DateTime>.generate(
      rows * 7,
      (index) => gridStart.add(Duration(days: index)),
    );

    return Column(
      children: [
        const _WeekdayHeader(labels: _CalendarPageState._weekdayLabels),
        const SizedBox(height: 6),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 0.9,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final isInMonth = day.month == month.month;
            final weekStart = _CalendarPageState._weekStart(day);
            final cycle = _CalendarPageState._cycleForDate(weekStart);
            final isCurrentWeek = weekStart == currentWeekStart;
            return _DayCell(
              date: day,
              cycle: cycle,
              isCurrentWeek: isCurrentWeek,
              isInMonth: isInMonth,
              today: today,
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.cycle,
    required this.isCurrentWeek,
    required this.isInMonth,
    required this.today,
  });

  final DateTime date;
  final _CycleInfo cycle;
  final bool isCurrentWeek;
  final bool isInMonth;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final baseColor = _cycleColor(cycle.color);
    final bgColor = baseColor.withValues(alpha: isInMonth ? 0.25 : 0.12);
    final isToday = DateUtils.isSameDay(date, today); // 👈 新增

    // 📌 外框颜色逻辑：today 优先，并使用 cycle 颜色
    final borderColor = isToday
        ? baseColor.withValues(alpha: 0.9)
        : (isCurrentWeek
              ? baseColor.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.08));

    final borderWidth = isToday ? 5.0 : (isCurrentWeek ? 1.5 : 1.0);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Center(
        child: Text(
          '${date.day}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isInMonth
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).disabledColor,
          ),
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: const [
        _LegendItem(label: 'Cycle 1', color: Colors.red),
        _LegendItem(label: 'Cycle 2', color: Colors.green),
        _LegendItem(label: 'Cycle 3', color: Colors.blue),
        _LegendItem(label: 'Cycle 4', color: Colors.orange),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _CycleInfo {
  const _CycleInfo({required this.value, required this.color});

  final int value;
  final CycleColor color;
}

Color _cycleColor(CycleColor color) {
  switch (color) {
    case CycleColor.red:
      return Colors.red;
    case CycleColor.green:
      return Colors.green;
    case CycleColor.blue:
      return Colors.blue;
    case CycleColor.yellow:
      return Colors.orange;
  }
}
