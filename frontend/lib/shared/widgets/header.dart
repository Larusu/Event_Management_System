import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Header extends StatefulWidget {
  final String header;
  final List<String> views;
  final List<String>? filters;
  final String page;

  const Header(
      {super.key,
      required this.header,
      required this.views,
      this.filters,
      required this.page});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  late String selectedValue;
  late DateTime focusedDate;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.views.isNotEmpty ? widget.views.first : '';
    focusedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final isSettingsPage = widget.page == "settings";

    final startOfWeek = focusedDate.subtract(
      Duration(days: focusedDate.weekday % 7),
    );
    final month = focusedDate.month;

    final monthlyDates = List.generate(
      DateTime(focusedDate.year, focusedDate.month + 1, 0).day,
      (index) => index + 1,
    );
    final weeklyDates = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)).day,
    );
    final dailyDates = [focusedDate.day];

    void _previousPeriod() {
      setState(() {
        if (selectedValue == 'Week') {
          focusedDate = focusedDate.subtract(
            const Duration(days: 7),
          );
        } else if (selectedValue == 'Month') {
          focusedDate = DateTime(
            focusedDate.year,
            focusedDate.month - 1,
          );
        } else {
          focusedDate = focusedDate.subtract(
            const Duration(days: 1),
          );
        }
      });
    }

    void _nextPeriod() {
      setState(() {
        if (selectedValue == 'Week') {
          focusedDate = focusedDate.add(
            const Duration(days: 7),
          );
        } else if (selectedValue == 'Month') {
          focusedDate = DateTime(
            focusedDate.year,
            focusedDate.month + 1,
          );
        } else {
          focusedDate = focusedDate.add(
            const Duration(days: 1),
          );
        }
      });
    }

    void _goToToday() {
      setState(() {
        focusedDate = DateTime.now();
      });
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.header,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.page == 'calendar') ...[
                  const SizedBox(
                    height: 4,
                  ),
                  TextButton(
                    onPressed: _goToToday,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      side: BorderSide(
                        color: Colors.grey.shade400,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Today'),
                  )
                ]
              ],
            ),
            const Spacer(),
            !isSettingsPage
                ? Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    DropdownMenu<String>(
                      dropdownMenuEntries: widget.views
                          .map(
                            (view) => DropdownMenuEntry<String>(
                              value: view,
                              label: view,
                            ),
                          )
                          .toList(),
                      menuStyle: MenuStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onSelected: (value) {
                        if (value != null) {
                          setState(() {
                            selectedValue = value;
                          });
                        }
                        _scrollToToday();
                      },
                      initialSelection: selectedValue,
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        // Handle filter action
                      },
                    ),
                  ])
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text("Account"), // TODO: Implement account role
                  )
          ]),
          if (!isSettingsPage) ...[
            const SizedBox(height: 4),
            Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
            const SizedBox(height: 4),
            widget.page == 'calendar'
                ? CalendarHeader(
                    key: ValueKey(
                        '${selectedValue}-${focusedDate.year}-${focusedDate.month}-${focusedDate.day}'),
                    month: month,
                    dates: selectedValue == "Month"
                        ? monthlyDates
                        : selectedValue == "Week"
                            ? weeklyDates
                            : dailyDates,
                    onPrevious: _previousPeriod,
                    onNext: _nextPeriod,
                  )
                : EventsListHeader(filters: widget.filters)
          ]
        ],
      ),
    );
  }
}

// EVENTS LIST PAGE
class EventsListHeader extends StatefulWidget {
  final List<String>? filters;

  const EventsListHeader({
    super.key,
    required this.filters,
  });

  @override
  State<EventsListHeader> createState() => _EventsListHeaderState();
}

class _EventsListHeaderState extends State<EventsListHeader> {
  final List<String> selectedFilters = <String>[];

  // TODO: Implement modal as reusable widget
  void _showFilterDialog() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      builder: (context) {
        final filters = widget.filters ?? [];

        List<String> tempSelected = [...selectedFilters];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 5,
                    children: filters.map((filter) {
                      final isSelected = tempSelected.contains(filter);

                      return ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        selectedColor: Theme.of(context).primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              tempSelected.add(filter);
                            } else {
                              tempSelected.remove(filter);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, tempSelected);
                        },
                        child: const Text('Apply'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          tempSelected.clear();
                          Navigator.pop(context, tempSelected);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedFilters
          ..clear()
          ..addAll(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (selectedFilters.isNotEmpty)
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 8,
                  children: selectedFilters.map((filter) {
                    return Chip(
                      label: Text(filter),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () {
                        setState(() {
                          selectedFilters.remove(filter);
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.filter_alt_outlined),
          onPressed: _showFilterDialog,
        ),
      ],
    );
  }
}

// CALENDAR PAGE
class CalendarHeader extends StatefulWidget {
  final int month;
  final List<int> dates;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const CalendarHeader(
      {super.key,
      required this.month,
      required this.dates,
      required this.onPrevious,
      required this.onNext});

  @override
  State<CalendarHeader> createState() => _CalendarHeaderState();
}

class _CalendarHeaderState extends State<CalendarHeader> {
  final year = DateTime.now().year;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToToday();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CalendarHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollToToday();
  }

  @override
  Widget build(BuildContext context) {
    final isDayView = widget.dates.length == 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(DateFormat('MMMM').format(DateTime(year, widget.month))),
        const SizedBox(width: 4),
        IconButton(
          onPressed: widget.onPrevious,
          icon: Icon(Icons.arrow_left),
          padding: EdgeInsets.all(4),
        ),
        isDayView
            ? Expanded(
                child: Center(
                  child: Builder(
                    builder: (context) {
                      final date = widget.dates.first;
                      final fullDate = DateTime(year, widget.month, date);
                      final now = DateTime.now();

                      final isToday = date == now.day &&
                          widget.month == now.month &&
                          year == now.year;

                      return Container(
                        key: isToday ? _todayKey : null,
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('E').format(fullDate),
                              style: TextStyle(
                                color: isToday ? Colors.white : null,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              date.toString(),
                              style: TextStyle(
                                color: isToday ? Colors.white : null,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              )
            : Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: 40,
                    children: widget.dates.asMap().entries.map((entry) {
                      final date = entry.value;
                      final fullDate = DateTime(year, widget.month, date);
                      final now = DateTime.now();

                      final isToday = fullDate.year == now.year &&
                          fullDate.month == now.month &&
                          fullDate.day == now.day;

                      return Container(
                        key: isToday ? _todayKey : null,
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('E').format(fullDate),
                              style: TextStyle(
                                color: isToday ? Colors.white : null,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              date.toString(),
                              style: TextStyle(
                                color: isToday ? Colors.white : null,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
        IconButton(onPressed: widget.onNext, icon: Icon(Icons.arrow_right)),
      ],
    );
  }
}

// METHODS
final GlobalKey _todayKey = GlobalKey();

void _scrollToToday() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_todayKey.currentContext != null) {
      Scrollable.ensureVisible(
        _todayKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        alignment: 0,
      );
    }
  });
}
