import 'package:flutter/material.dart';
import 'package:pesa_pay/services/api_services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final APIService apiService = APIService();

  Map<String, dynamic>? employee;
  Map<String, dynamic>? salaryData;
  Map<String, dynamic>? attendanceData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    const String email = "nicole@gmail.com"; // This will come from login later

    try {
      final emp = await apiService.getEmployeeByEmail(email);
      final salary = await apiService.calculateSalary(email);
      final attendance = await apiService.getAttendance(email);

      setState(() {
        employee = emp;
        salaryData = salary;
        attendanceData = attendance;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _simulateBankTransfer() {
    if (salaryData == null || employee == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Bank Transfer Initiated"),
        content: Text(
          "✅ KES ${salaryData?['final_salary']?.toStringAsFixed(2)} will be transferred to:\n\n"
          "🏦 Bank: ${employee?['bank_name']}\n"
          "🔢 Account: ${employee?['account_number']}\n\n"
          "Transfer processed via IPF (Inter-Bank Payment Framework).",
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), elevation: 1),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Employee Info
                    const Text(
                      "Employee Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow("Name", employee?['name']),
                    _buildDetailRow("Gender", employee?['gender']),
                    _buildDetailRow("Department", employee?['department']),
                    const SizedBox(height: 24),

                    // Salary Section
                    const Text(
                      "Salary Information",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      "Base Salary",
                      "KES ${employee?['salary']?.toStringAsFixed(2)}",
                    ),
                    _buildDetailRow(
                      "Overtime Pay",
                      "KES ${salaryData?['overtime_pay']?.toStringAsFixed(2)}",
                    ),
                    _buildDetailRow(
                      "Final Salary",
                      "KES ${salaryData?['final_salary']?.toStringAsFixed(2)}",
                      isHighlighted: true,
                    ),
                    const SizedBox(height: 24),

                    // Attendance Section
                    const Text(
                      "Attendance Record",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      attendanceData?['summary'] ?? "No attendance data",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Buttons
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
