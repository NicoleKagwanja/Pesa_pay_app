// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pesa_pay/services/api_services.dart';

class ActivityScreen extends StatefulWidget {
  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _events = {};
  List<dynamic> holidays = [];
  bool _loading = true;

  final APIService apiService = APIService();

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    try {
      final List<dynamic> fetched = await apiService.getPublicHolidays();
      final Map<DateTime, List<String>> tempEvents = {};

      for (var h in fetched) {
        final date = DateTime.parse(h['date']);
        tempEvents[date] = [...tempEvents[date] ?? [], h['name']];
      }

      setState(() {
        holidays = fetched;
        _events = tempEvents;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load holidays: $e")));
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Activity Calendar")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2024, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: _getEventsForDay(_selectedDay ?? _focusedDay)
                        .map(
                          (event) => ListTile(
                            leading: Icon(Icons.event, color: Colors.red),
                            title: Text(event),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
