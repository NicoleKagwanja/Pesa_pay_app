// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, unused_field
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pesa_pay/services/api_services.dart';
import 'package:pesa_pay/services/network_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late TextEditingController _reasonController;
  DateTime? _start, _end;
  String? _pendingOffWeek;
  String _userName = "Employee";
  String _department = "Loading...";
  double _totalHours = 0.0;
  int _daysPresent = 0;
  bool _isClockedIn = false;
  bool _isClocking = false;
  String _timeIn = "";
  String _timeOut = "";
  bool _loading = true;
  bool _isOnline = true;

  DateTime _calendarMonth = DateTime.now();
  List<Map<String, dynamic>> _attendanceRecords = [];

  final NetworkService _networkService = NetworkService();
  final APIService apiService = APIService();

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _checkConnectionAndLoad();
    _listenToConnection();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectionAndLoad() async {
    final isConnected = await _networkService.isConnected;
    if (isConnected) {
      setState(() {
        _isOnline = true;
        _loading = true;
      });
      await _loadUserData();
      await _loadAttendanceRecords();
    } else {
      setState(() {
        _isOnline = false;
        _loading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? 'nicole@gmail.com';

    try {
      final profile = await apiService.getEmployeeByEmail(email);
      final summary = await apiService.getAttendanceSummary(email);

      if (mounted) {
        setState(() {
          _userName = profile['name']?.split(' ').first ?? "User";
          _department = profile['department'] ?? "Unknown";
          _totalHours = (summary['total_hours'] as num?)?.toDouble() ?? 0.0;
          _daysPresent = (summary['days_present'] as int?) ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Failed to load data: $e");
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadAttendanceRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? 'nicole@gmail.com';

    try {
      final records = await apiService.getAttendanceRecords(email);
      if (mounted) {
        setState(() {
          _attendanceRecords = List<Map<String, dynamic>>.from(records);
        });
      }
    } catch (e) {
      debugPrint("Failed to load attendance records: $e");
    }
  }

  void _listenToConnection() {
    _networkService.onConnectivityChanged.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOnline = isConnected;
        });

        if (isConnected) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Back online!")));
          _loadUserData();
          _loadAttendanceRecords();
        }
      }
    });
  }

  bool _hasAttendanceOnDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _attendanceRecords.any(
      (record) =>
          record['date'] == dateStr ||
          (record['time_in'] != null &&
              record['date']?.contains(dateStr) == true),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _calendarMonth = DateTime(
        _calendarMonth.year,
        _calendarMonth.month + offset,
        1,
      );
    });
  }

  Widget _buildAttendanceCalendar() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_calendarMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeMonth(-1),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () =>
                          _calendarMonth.isBefore(
                            DateTime(now.year, now.month + 1, 1),
                          )
                          ? null
                          : () => _changeMonth(1),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays
                  .map(
                    (day) => SizedBox(
                      width: 40,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final dayNumber = index - (firstWeekday - 1);
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox();
                }

                final date = DateTime(
                  _calendarMonth.year,
                  _calendarMonth.month,
                  dayNumber,
                );
                final hasAttendance = _hasAttendanceOnDate(date);
                final isToday =
                    DateFormat('yyyy-MM-dd').format(date) ==
                    DateFormat('yyyy-MM-dd').format(now);
                final isFuture = date.isAfter(
                  DateTime(now.year, now.month, now.day),
                );

                return Container(
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.blue[100]
                        : hasAttendance
                        ? Colors.green[100]
                        : isFuture
                        ? Colors.grey[100]
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday
                          ? Colors.blue
                          : hasAttendance
                          ? Colors.green
                          : Colors.transparent,
                      width: isToday || hasAttendance ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        color: isFuture
                            ? Colors.grey
                            : (hasAttendance
                                  ? Colors.green[800]
                                  : Colors.black87),
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Legend
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Present'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.blue, 'Today'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.grey, 'No Record'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Future<void> _clockIn() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No internet connection")));
      return;
    }

    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? 'nicole@gmail.com';

    setState(() {
      _isClocking = true;
      _timeIn = timeStr;
      _isClockedIn = true;
    });

    try {
      await apiService.logAttendance(email: email, timeIn: _timeIn);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Clocked In at $_timeIn")));
      _loadAttendanceRecords();
    } on Exception catch (e) {
      setState(() => _isClockedIn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to clock in: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isClocking = false);
    }
  }

  Future<void> _clockOut() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No internet connection")));
      return;
    }

    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? 'nicole@gmail.com';

    setState(() {
      _isClocking = true;
      _timeOut = timeStr;
    });

    try {
      final result = await apiService.logAttendance(
        email: email,
        timeOut: _timeOut,
      );
      final hours = (result['total_hours'] as num?)?.toDouble() ?? 0.0;

      setState(() {
        _totalHours += hours;
        _isClockedIn = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Clocked Out at $_timeOut | +${hours.toStringAsFixed(1)} hrs",
          ),
        ),
      );
      _loadAttendanceRecords();
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to clock out: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isClocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        elevation: 1,
        actions: [
          if (!_isOnline)
            IconButton(
              icon: const Icon(Icons.wifi_off, color: Colors.red),
              tooltip: "Offline mode",
              onPressed: () {},
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 42, 94, 107),
              ),
              child: const Text(
                "Pesa Pay\nEmployee Portal",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Activity Calendar"),
              onTap: () => Navigator.pushNamed(context, '/activity'),
            ),
          ],
        ),
      ),
      body: !_isOnline
          ? _buildOfflineScreen()
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildOnlineContent(),
    );
  }

  Widget _buildOfflineScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "No Internet Connection",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You are currently offline. Some features may not be available.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkConnectionAndLoad,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry Connection"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $_userName!",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              "Department: $_department",
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              "Manage your schedule and attendance.",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Daily Attendance",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isClockedIn ? null : _clockIn,
                            child: _isClocking && !_isClockedIn
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text("Time In"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isClockedIn ? _clockOut : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: _isClocking && _isClockedIn
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text("Time Out"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Status: ${_isClockedIn ? 'Clocked In' : 'Clocked Out'}",
                      style: TextStyle(
                        color: _isClockedIn ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_timeIn.isNotEmpty)
                      Text(
                        "Time In: $_timeIn",
                        style: const TextStyle(fontSize: 14),
                      ),
                    if (_timeOut.isNotEmpty)
                      Text(
                        "Time Out: $_timeOut",
                        style: const TextStyle(fontSize: 14),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      "Total Hours Worked: ${_totalHours.toStringAsFixed(2)} hrs",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Attendance Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text("Total Hours This Month"),
                trailing: Text(
                  "${_totalHours.toStringAsFixed(2)} hrs",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Days Present"),
                trailing: Text(
                  "$_daysPresent",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Salary Status Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Current Salary Status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      "Your salary will be adjusted based on attendance and approved off-weeks.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/profile'),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text("View Profile & Salary"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(211, 0, 0, 0),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            //Activity Calendar at Bottom
            const Text(
              "Activity Calendar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildAttendanceCalendar(),
          ],
        ),
      ),
    );
  }
}
