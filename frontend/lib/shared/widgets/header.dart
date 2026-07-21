import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/widgets/app_button.dart';
import '../../features/events/providers/calendar_provider.dart';

class Header extends StatefulWidget {
  final String header;
  final List<String> views;
  final List<String>? filters;
  final String page;
  final bool showSearch;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<List<String>>? onFiltersChanged;
  final String searchHintText;
  final String? headerSubtitle;
  final VoidCallback? onBack;

  const Header({
    super.key,
    required this.header,
    required this.views,
    this.filters,
    required this.page,
    this.showSearch = false,
    this.searchController,
    this.onSearchChanged,
    this.onFiltersChanged,
    this.searchHintText = 'Search events...',
    this.headerSubtitle,
    this.onBack,
  });

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  late String selectedValue;
  late DateTime focusedDate;
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.views.isNotEmpty ? widget.views.first : '';
    focusedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final isSettingsPage = widget.page == "settings";
    final showAccountPill = isSettingsPage || widget.page == "dashboard";
    final showEventsHeader = !showAccountPill;
    final isCalendarPage = widget.page == 'calendar';

    // On the calendar page the CalendarProvider is the single source of truth
    // for the selected view and focused date, so the Header and the calendar
    // body can never drift apart. Other pages keep the Header's own state.
    final calendar = isCalendarPage ? context.watch<CalendarProvider>() : null;
    final effectiveView =
        isCalendarPage ? calendar!.viewMode.label : selectedValue;
    final effectiveFocused =
        isCalendarPage ? calendar!.focusedDate : focusedDate;

    final startOfWeek = effectiveFocused.subtract(
      Duration(days: effectiveFocused.weekday % 7),
    );

    // Day and Week both show the focused week (Sunday-start); Month shows the
    // 12 months of the focused year. The selected item is centered + bolded.
    final weekDates = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );
    final monthDates = List.generate(
      12,
      (index) => DateTime(effectiveFocused.year, index + 1, 1),
    );

    void previousPeriod() {
      if (isCalendarPage) {
        calendar!.previousPeriod();
        return;
      }
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

    void nextPeriod() {
      if (isCalendarPage) {
        calendar!.nextPeriod();
        return;
      }
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

    void goToToday() {
      if (isCalendarPage) {
        calendar!.goToToday();
        return;
      }
      setState(() {
        focusedDate = DateTime.now();
      });
    }

    // Fill the status-bar area with the header's own background (like an
    // AppBar) so screens don't need a top SafeArea and there's no blank band
    // above the header; content stays padded below the notch. Resolves to 0
    // when an ancestor has already consumed the top inset.
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 16, right: 16, top: 8 + topInset, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
            if (widget.onBack != null)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
            if (widget.onBack != null) const SizedBox(width: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCalendarPage
                      ? DateFormat('MMMM yyyy').format(effectiveFocused)
                      : widget.header,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.page == 'calendar') ...[
                  const SizedBox(
                    height: 4,
                  ),
                  TextButton(
                    onPressed: goToToday,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Today'),
                  )
                ]
              ],
            ),
            const Spacer(),
            !showAccountPill
                ? Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    if (widget.views.isNotEmpty)
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
                            horizontal: 8,
                            vertical: 2,
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
                            if (isCalendarPage) {
                              calendar!.setView(
                                CalendarViewMode.fromLabel(value),
                              );
                            } else {
                              setState(() {
                                selectedValue = value;
                              });
                            }
                          }
                          _scrollToSelected();
                        },
                        initialSelection: effectiveView,
                      ),
                    if (widget.showSearch) ...[
                      const SizedBox(height: 4),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 20,
                        icon: Icon(_isSearchOpen ? Icons.close : Icons.search),
                        onPressed: () {
                          setState(() {
                            _isSearchOpen = !_isSearchOpen;
                          });
                          if (!_isSearchOpen) {
                            final hasText =
                                widget.searchController?.text.isNotEmpty ??
                                    false;
                            widget.searchController?.clear();
                            if (hasText) {
                              widget.onSearchChanged?.call('');
                            }
                          }
                        },
                      ),
                    ],
                  ])
                : Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          widget.headerSubtitle ?? "Account",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  )
          ]),
          if (showEventsHeader) ...[
            const SizedBox(height: 2),
            Divider(
              color: Theme.of(context).dividerColor,
              thickness: 1,
            ),
            const SizedBox(height: 2),
            if (_isSearchOpen)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: widget.searchController,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: widget.searchHintText,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: widget.searchController != null &&
                            widget.searchController!.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              widget.searchController?.clear();
                              widget.onSearchChanged?.call('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            isCalendarPage
                ? CalendarHeader(
                    // No ValueKey: keeping the same State (and scroll offset)
                    // across navigation lets the strip glide the highlight to
                    // the next cell instead of rebuilding from the left edge.
                    isMonthView: effectiveView == "Month",
                    dates: effectiveView == "Month" ? monthDates : weekDates,
                    selectedDate: effectiveFocused,
                    hasEvents:
                        (effectiveView == "Week" || effectiveView == "Day")
                            ? (date) => calendar!.eventsOn(date).isNotEmpty
                            : null,
                    onDateSelected: calendar!.goToDate,
                    onPrevious: previousPeriod,
                    onNext: nextPeriod,
                  )
                : EventsListHeader(
                    filters: widget.filters,
                    onFiltersChanged: widget.onFiltersChanged,
                  )
          ]
        ],
      ),
    );
  }
}

// EVENTS LIST PAGE
class EventsListHeader extends StatefulWidget {
  final List<String>? filters;
  final ValueChanged<List<String>>? onFiltersChanged;

  const EventsListHeader({
    super.key,
    required this.filters,
    this.onFiltersChanged,
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
                    spacing: 10,
                    runSpacing: 10,
                    children: filters.map((filter) {
                      final isSelected = tempSelected.contains(filter);

                      return ChoiceChip(
                        label: Text(filter.toLowerCase()),
                        selected: isSelected,
                        selectedColor: Theme.of(context).primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
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
                  SizedBox(
                    height: 15,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Apply',
                          onPressed: () {
                            Navigator.pop(context, tempSelected);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          label: 'Clear',
                          onPressed: () {
                            tempSelected.clear();
                            Navigator.pop(context, tempSelected);
                          },
                        ),
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
      widget.onFiltersChanged?.call(selectedFilters);
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
                      visualDensity: VisualDensity.compact,
                      label: Text(filter, style: const TextStyle(fontSize: 12)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 12),
                      onDeleted: () {
                        setState(() {
                          selectedFilters.remove(filter);
                        });
                        widget.onFiltersChanged?.call(selectedFilters);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        IconButton(
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          icon: const Icon(Icons.filter_alt_outlined),
          onPressed: _showFilterDialog,
        ),
      ],
    );
  }
}

// CALENDAR PAGE
//
// A horizontally scrollable strip. Day and Week show the focused week's days
// (weekday + day number); Month shows the 12 months of the focused year
// (month name). The [selectedDate]'s cell is bolded/filled and auto-centered.
class CalendarHeader extends StatefulWidget {
  final List<DateTime> dates;
  final DateTime selectedDate;
  final bool isMonthView;

  /// When non-null, cells whose date returns true get an event dot (Day + Week
  /// views; both load the whole focused week, so per-day dots have data).
  final bool Function(DateTime)? hasEvents;

  /// Called when a strip cell is tapped.
  final void Function(DateTime)? onDateSelected;

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const CalendarHeader({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.isMonthView,
    this.hasEvents,
    this.onDateSelected,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  State<CalendarHeader> createState() => _CalendarHeaderState();
}

class _CalendarHeaderState extends State<CalendarHeader> {
  static const Color _eventDotColor = Color(0xFF4C7F9F);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToSelected();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CalendarHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollToSelected();
  }

  bool _isSelected(DateTime date) {
    final sel = widget.selectedDate;
    if (widget.isMonthView) {
      return date.year == sel.year && date.month == sel.month;
    }
    return date.year == sel.year &&
        date.month == sel.month &&
        date.day == sel.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    if (widget.isMonthView) {
      return date.year == now.year && date.month == now.month;
    }
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _cell(DateTime date) {
    final isSelected = _isSelected(date);
    // The focused cell is filled; today (when not focused) stays bold so it
    // remains findable after navigating away.
    final isBold = isSelected || _isToday(date);
    final labelColor = isSelected ? Colors.white : null;
    final weight = isBold ? FontWeight.bold : FontWeight.normal;
    final showDot =
        !widget.isMonthView && (widget.hasEvents?.call(date) ?? false);

    final cell = Container(
      key: isSelected ? _selectedKey : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: widget.isMonthView
          ? Text(
              DateFormat('MMM').format(date),
              style: TextStyle(color: labelColor, fontWeight: weight),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('E').format(date),
                  style: TextStyle(color: labelColor, fontWeight: weight),
                ),
                Text(
                  date.day.toString(),
                  style: TextStyle(color: labelColor, fontWeight: weight),
                ),
                const SizedBox(height: 2),
                // Always reserve the dot's space so cell heights stay uniform.
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !showDot
                        ? Colors.transparent
                        : isSelected
                            ? Colors.white
                            : _eventDotColor,
                  ),
                ),
              ],
            ),
    );

    if (widget.onDateSelected == null) return cell;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onDateSelected!(date),
      child: cell,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(DateFormat('MMMM').format(widget.selectedDate)),
        const SizedBox(width: 4),
        IconButton(
          onPressed: widget.onPrevious,
          icon: const Icon(Icons.arrow_left),
          padding: const EdgeInsets.all(4),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 40,
              children: widget.dates.map(_cell).toList(),
            ),
          ),
        ),
        IconButton(
          onPressed: widget.onNext,
          icon: const Icon(Icons.arrow_right),
        ),
      ],
    );
  }
}

// METHODS
final GlobalKey _selectedKey = GlobalKey();

void _scrollToSelected() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final context = _selectedKey.currentContext;
    if (context == null) return;

    // Bail if the target (or its scroll viewport) isn't laid out yet. This
    // happens when the calendar strip is built offstage inside MainShell's
    // IndexedStack: calling ensureVisible then throws "RenderBox was not laid
    // out". The auto-center is best-effort, so skipping it is safe.
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final position = Scrollable.maybeOf(context)?.position;
    if (position == null ||
        !position.hasViewportDimension ||
        !position.hasContentDimensions) {
      return;
    }

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      alignment: 0.5, // center the focused cell
    );
  });
}
