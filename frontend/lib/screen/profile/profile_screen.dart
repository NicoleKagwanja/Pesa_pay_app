// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pesa_pay/services/api_services.dart';
import 'package:pesa_pay/services/network_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final APIService apiService = APIService();
  Map<String, dynamic>? employee;
  Map<String, dynamic>? salaryData;
  Map<String, dynamic>? attendanceData;
  bool _loading = true;
  String? _userEmail;
  bool _isOnline = true;
  bool _isAdmin = false;
  final NetworkService _networkService = NetworkService();

  @override
  void initState() {
    super.initState();
    _checkConnectionAndLoad();
    _listenToConnection();
  }

  Future<void> _checkConnectionAndLoad() async {
    final isConnected = await _networkService.isConnected;
    if (isConnected) {
      _loadUserData();
    } else {
      setState(() {
        _loading = false;
        _isOnline = false;
      });
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

  Future<void> _loadUserData() async {
    setState(() {
      _loading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('user_email');
      _isAdmin = prefs.getBool('is_admin') ?? false;
    });

    if (_userEmail == null) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No user session found. Please log in."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final emp = await apiService.getEmployeeByEmail(_userEmail!);
      final salary = await apiService.calculateSalary(_userEmail!);
      final attendance = await apiService.getAttendance(_userEmail!);

      setState(() {
        employee = emp;
        salaryData = salary;
        attendanceData = attendance;
        _loading = false;
        _isOnline = true;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _simulateBankTransfer() {
    if (!mounted || !_isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No internet connection.")));
      return;
    }

    if (salaryData == null || employee == null) return;

    final String transactionId =
        "TXN${DateTime.now().millisecondsSinceEpoch % 10000000}";
    final String timestamp =
        "${DateTime.now().toLocal().formatDate()} ${DateTime.now().toLocal().formatTime()}";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Bank Transfer Successful",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Your salary has been successfully transferred.",
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              _buildDetail(
                "Amount",
                "KES ${salaryData?['final_salary']?.toStringAsFixed(2)}",
              ),
              _buildDetail("Bank", "${employee?['bank_name']}"),
              _buildDetail(
                "Account",
                "**** ${employee?['account_number']?.substring(employee?['account_number']?.length - 4)}",
              ),
              _buildDetail("Method", "IPF (Inter-Bank Payment Framework)"),
              _buildDetail("Transaction ID", transactionId),
              _buildDetail("Status", "Completed", color: Colors.green),
              _buildDetail("Time", timestamp),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('is_admin');

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Widget _buildDetail(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        elevation: 1,
        actions: [
          if (_isAdmin)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "ADMIN",
                style: TextStyle(fontSize: 10, color: Colors.red),
              ),
            ),
        ],
      ),
      body: !_isOnline
          ? _buildOfflineScreen()
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileContent(),
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
              "Offline Mode",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You're offline. Some data may be outdated.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkConnectionAndLoad,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Employee Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow("Name", employee?['name']),
            _buildDetailRow("Gender", employee?['gender']),
            _buildDetailRow("Department", employee?['department']),
            const SizedBox(height: 24),

            const Text(
              "Salary Information",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetail(
              "Work Days",
              (salaryData?['work_days'] ?? 0).toString(),
            ),
            _buildDetail(
              "Overtime Hours",
              (salaryData?['overtime_hours'] ?? 0).toString(),
            ),
            _buildDetail(
              "Overtime Pay",
              "KES ${salaryData?['overtime_pay']?.toStringAsFixed(2)}",
            ),
            _buildDetail(
              "Holiday Bonus",
              "KES ${salaryData?['holiday_bonus']?.toStringAsFixed(2)}",
            ),
            _buildDetail(
              "Deductions",
              "KES ${salaryData?['deductions']?.toStringAsFixed(2)}",
              color: Colors.red,
            ),
            _buildDetailRow(
              "Final Salary",
              "KES ${salaryData?['final_salary']?.toStringAsFixed(2)}",
              isHighlighted: true,
            ),
            const SizedBox(height: 24),
            const Text(
              "Attendance Record",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              attendanceData?['summary'] ?? "No attendance data",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _simulateBankTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: const Text(
                "Simulate Bank Transfer",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _logout,
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String? value, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Text(
            value ?? "N/A",
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

extension DateTimeFormat on DateTime {
  String formatDate() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '$day ${months[month - 1]}, $year';
  }

  String formatTime() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    final s = second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
