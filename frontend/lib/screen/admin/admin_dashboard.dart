// lib/screens/admin/admin_dashboard.dart
// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pesa_pay/services/api_services.dart';
import 'package:pesa_pay/widgets/attendance_chart.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _attendanceReport = [];
  List<Map<String, dynamic>> _calendarEvents = [];
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();

  final APIService apiService = APIService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final employees = await apiService.getAllEmployees();
      final pending = await apiService.getPendingOffWeeks();
      final attendance = await apiService.getAttendanceReport();
      final events = await apiService.getCalendarEvents();

      if (mounted) {
        setState(() {
          _employees = List<Map<String, dynamic>>.from(employees);
          _pendingRequests = List<Map<String, dynamic>>.from(pending);
          _attendanceReport = List<Map<String, dynamic>>.from(attendance);
          _calendarEvents = List<Map<String, dynamic>>.from(events);
          _loading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to load data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _approveRequest(int id) async {
    try {
      await apiService.approveOffWeek(id);
      if (mounted) {
        setState(() {
          _pendingRequests.removeWhere((r) => r['id'] == id);
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Request approved")));
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectRequest(int id) async {
    try {
      await apiService.rejectOffWeek(id);
      if (mounted) {
        setState(() {
          _pendingRequests.removeWhere((r) => r['id'] == id);
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Request rejected")));
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _disburseSalaries() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Salary Disbursement"),
        content: const Text(
          "Are you sure you want to disburse salaries to all employees via IPF?\n\n"
          "This action cannot be undone.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final result = await apiService.disburseSalaries();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${result['message']}"),
                    backgroundColor: Colors.green,
                  ),
                );
              } on Exception catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Disbursement failed: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Yes, Disburse"),
          ),
        ],
      ),
    );
  }

  Future<void> _addCalendarEvent() async {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: '2025-08-15');
    final typeCtrl = TextEditingController(text: 'event');
    final descCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Calendar Event"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: "Date (YYYY-MM-DD)",
                ),
              ),
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(labelText: "Type"),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await apiService.addCalendarEvent(
                  title: titleCtrl.text,
                  date: dateCtrl.text,
                  type: typeCtrl.text,
                  description: descCtrl.text,
                );
                _loadData(); // Reload events
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("✅ Event added!")));
              } on Exception catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("❌ Failed: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('is_admin');
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red[100],
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "ADMIN MODE",
              style: TextStyle(fontSize: 10, color: Colors.red),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: const Color.fromARGB(255, 70, 30, 100),
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      "Pesa Pay\nAdmin Portal",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "ADMIN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("All Employees"),
              onTap: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text("Pending Requests"),
              onTap: () {
                _scrollController.animateTo(
                  800.0,
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text("Disburse Salaries"),
              onTap: () {
                _disburseSalaries();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Admin Dashboard",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Manage employees, off-weeks, and salary disbursement.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        onPressed: _disburseSalaries,
                        icon: const Icon(Icons.attach_money, size: 20),
                        label: const Text("Disburse Salaries to All"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        "All Employees",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_employees.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              "No employees registered yet.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ..._employees.map(
                          (emp) => Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.blue,
                              ),
                              title: Text(emp['name']),
                              subtitle: Text(
                                "${emp['department']} • ${emp['email']}",
                              ),
                              trailing: Text(
                                "KES ${emp['salary']?.toStringAsFixed(2)}",
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      const Text(
                        "Attendance Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AttendanceChartWidget(report: _attendanceReport),
                      const SizedBox(height: 24),

                      // Calendar Events with Add Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Calendar Events",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addCalendarEvent,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Add Event"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_calendarEvents.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              "No calendar events yet.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ..._calendarEvents.map(
                          (e) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${e['type'].toUpperCase()} • ${e['date']}",
                                  ),
                                  if (e['description'] != null)
                                    Text(e['description']),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      const Text(
                        "Pending Off-Week Requests",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_pendingRequests.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              "No pending off-week requests.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ..._pendingRequests.map(
                          (req) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Off-Week Request #${req['id']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.hourglass_empty,
                                        color: Colors.orange,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text("Employee: ${req['employee_email']}"),
                                  Text(
                                    "Dates: ${req['start_date']} to ${req['end_date']}",
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _approveRequest(req['id'] as int),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text("Approve"),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _rejectRequest(req['id'] as int),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text("Reject"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
