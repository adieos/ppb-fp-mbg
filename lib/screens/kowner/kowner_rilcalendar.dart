import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/report_model.dart';
import '../../services/holiday.dart';
import '../../services/kowner_firestore_service.dart';
import 'kowner_detail_report_screen.dart';

class KownerCalendarScreen extends StatefulWidget {
  const KownerCalendarScreen({super.key});

  @override
  State<KownerCalendarScreen> createState() => _State();
}

class _State extends State<KownerCalendarScreen> {
  final _svc = KownerFirestoreService();
  final _holidaySvc = HolidayService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // holidays for currently visible year
  List<DateTime> _holidays = [];
  int _loadedYear = -1; // track which year is loaded

  @override
  void initState() {
    super.initState();
    _loadHolidays(DateTime.now().year);
  }

  Future<void> _loadHolidays(int year) async {
    if (_loadedYear == year) return; // already loaded
    final holidays = await _holidaySvc.getHolidaysForYear(year);
    if (mounted)
      setState(() {
        _holidays = holidays;
        _loadedYear = year;
      });
  }

  bool _isHoliday(DateTime day) {
    return _holidays.any((h) => isSameDay(h, day));
  }

  List<ReportModel> _reportsForDay(List<ReportModel> reports, DateTime day) {
    return reports.where((r) => isSameDay(r.date, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F2E),
        title: const Text('Kalender', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: _svc.getReports(),
        builder: (context, snap) {
          final reports = snap.data ?? [];
          final selectedReports = _selectedDay != null
              ? _reportsForDay(reports, _selectedDay!)
              : [];

          return Column(
            children: [
              // ── Calendar ─────────────────────────────────
              TableCalendar(
                firstDay: DateTime(2024),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _loadHolidays(
                    focusedDay.year,
                  ); // load holidays when month changes
                },
                eventLoader: (day) => _reportsForDay(reports, day),
                locale: 'id_ID',
                calendarStyle: CalendarStyle(
                  // today
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  // selected day
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFF6C63FF),
                    shape: BoxShape.circle,
                  ),
                  // default day text
                  defaultTextStyle: const TextStyle(color: Colors.white),
                  weekendTextStyle: const TextStyle(color: Color(0xFF8A8FA8)),
                  outsideTextStyle: const TextStyle(color: Color(0xFF3A3D4E)),
                  todayTextStyle: const TextStyle(color: Colors.white),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  // event dot
                  markerDecoration: const BoxDecoration(
                    color: Color(0xFF6C63FF),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Color(0xFF8A8FA8)),
                  weekendStyle: TextStyle(color: Color(0xFF8A8FA8)),
                ),
                // custom day builder to highlight holidays
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (_isHoliday(day)) return _HolidayDay(day: day);
                    return null; // null = use default
                  },
                  outsideBuilder: (context, day, focusedDay) {
                    if (_isHoliday(day))
                      return _HolidayDay(day: day, outside: true);
                    return null;
                  },
                ),
              ),

              // ── Legend ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _LegendDot(
                      color: const Color(0xFF6C63FF),
                      label: 'Ada laporan',
                    ),
                    const SizedBox(width: 16),
                    _LegendDot(
                      color: Colors.redAccent.withOpacity(0.7),
                      label: 'Hari libur',
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF2A2D3E)),

              // ── Selected day reports ───────────────────────
              Expanded(
                child: _selectedDay == null
                    ? const Center(
                        child: Text(
                          'Pilih tanggal untuk melihat laporan',
                          style: TextStyle(color: Color(0xFF8A8FA8)),
                        ),
                      )
                    : selectedReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inbox_outlined,
                              color: Color(0xFF8A8FA8),
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isHoliday(_selectedDay!)
                                  ? 'Hari libur — tidak ada laporan'
                                  : 'Tidak ada laporan',
                              style: const TextStyle(color: Color(0xFF8A8FA8)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: selectedReports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final report = selectedReports[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    KownerDetailReportScreen(report: report),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1F2E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF2A2D3E),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          report.kitchenName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${report.totalBeneficiaries} penerima · ${report.distributionTime}',
                                          style: const TextStyle(
                                            color: Color(0xFF8A8FA8),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _StatusChip(status: report.status),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _HolidayDay extends StatelessWidget {
  final DateTime day;
  final bool outside;
  const _HolidayDay({required this.day, this.outside = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(outside ? 0.1 : 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: outside
                ? Colors.redAccent.withOpacity(0.4)
                : Colors.redAccent,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8A8FA8), fontSize: 12),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case ReportStatus.verified:
        color = Colors.greenAccent;
        label = 'Verified';
        break;
      case ReportStatus.rejected:
        color = Colors.redAccent;
        label = 'Ditolak';
        break;
      case ReportStatus.submitted:
        color = Colors.orange;
        label = 'Pending';
        break;
      default:
        color = Colors.grey;
        label = 'Draft';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
