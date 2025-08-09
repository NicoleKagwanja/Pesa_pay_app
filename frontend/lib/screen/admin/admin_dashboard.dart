// screen/admin/admin_dashboard.dart
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final employees = await APIService().getAllEmployees();
      final pending = await APIService().getPendingOffWeeks();

      setState(() {
        _employees = List<Map<String, dynamic>>.from(employees);
        _pendingRequests = List<Map<String, dynamic>>.from(pending);

        _attendanceReport = _employees.map((emp) {
          return {...emp, 'total_hours': 160.0 + (emp['id'] % 10) * 5};
        }).toList();

        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load data: $e")));
    }
  }

  Future<void> _approveRequest(int id) async {
    try {
      await APIService().approveOffWeek(id);
      setState(() {
        _pendingRequests.removeWhere((r) => r['id'] == id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Request approved")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  Future<void> _rejectRequest(int id) async {
    try {
      await APIService().rejectOffWeek(id);
      setState(() {
        _pendingRequests.removeWhere((r) => r['id'] == id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Request rejected")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  void _disburseSalaries() {
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
                final result = await APIService().disburseSalaries();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${result['message']}"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
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

  void _logout() async {
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
              title: const Text("Employees"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text("Pending Requests"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text("Disburse Salaries"),
              onTap: _disburseSalaries,
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
                                              _approveRequest(req['id']),
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
                                              _rejectRequest(req['id']),
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
