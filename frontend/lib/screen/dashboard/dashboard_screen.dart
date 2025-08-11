// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pesa_pay/services/api_services.dart';
import 'package:pesa_pay/services/network_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  DateTime? _start, _end;
  String? _pendingOffWeek;
  String _userName = "Employee";
  String _department = "Loading..."; // Will be updated
  double _totalHours = 0.0;
  bool _isClockedIn = false;
  bool _isClocking = false;
  String _timeIn = "";
  String _timeOut = "";
  bool _loading = true;
  bool _isOnline = true;

  final NetworkService _networkService = NetworkService();
  final APIService apiService = APIService();

  @override
  void initState() {
    super.initState();
    _startDateController = TextEditingController();
    _endDateController = TextEditingController();
    _checkConnectionAndLoad();
    _listenToConnection();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
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
          content: Text("⚠️ Failed to load data: $e"),
          backgroundColor: Colors.red,
        ),
      );
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
        }
      }
    });
  }

  String formatDate(DateTime? date) {
    if (date == null) return "Not set";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDate(bool isStart) async {
    if (!_isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No internet connection")));
      return;
    }

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );

    if (selected == null) return;

    if (isStart) {
      _start = selected;
      _startDateController.text = formatDate(_start);
      _end = null;
      _endDateController.text = '';
    } else {
      if (_start != null && selected.isBefore(_start!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("End date cannot be before start date."),
          ),
        );
        return;
      }
      _end = selected;
      _endDateController.text = formatDate(_end);
    }
  }

  void _submitOffWeekRequest() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No internet connection. Please try again later."),
        ),
      );
      return;
    }

    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both start and end dates")),
      );
      return;
    }

    if (_end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End date cannot be before start date.")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? "nicole@gmail.com";

    try {
      await apiService.requestOffWeek(
        email,
        formatDate(_start),
        formatDate(_end),
      );

      setState(() {
        _pendingOffWeek =
            "Off-week from ${formatDate(_start)} to ${formatDate(_end)} is pending approval.";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Off-week request submitted!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to submit: $e")));
    }
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
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to clock out: $e"),
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
              child: Text(
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
            // ✅ Welcome Message
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
                      "Apply for Off Week",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Select your preferred dates. HR will review your request.",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _startDateController,
                      readOnly: true,
                      onTap: () => _selectDate(true),
                      decoration: const InputDecoration(
                        labelText: "Start Date",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _endDateController,
                      readOnly: true,
                      onTap: () => _selectDate(false),
                      decoration: const InputDecoration(
                        labelText: "End Date",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitOffWeekRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Submit Request",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    if (_pendingOffWeek != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hourglass_empty,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _pendingOffWeek!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                trailing: const Text(
                  "24",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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
          ],
        ),
      ),
    );
  }
}
