// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pesa_pay/services/api_services.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final APIService apiService = APIService();
  bool _loading = true;
  Map<String, dynamic>? _currentSalary;
  List<dynamic> _salaryHistory = [];
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  double _hourlyRate = 500.0;

  @override
  void initState() {
    super.initState();
    _loadSalaryData();
  }

  Future<void> _loadSalaryData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';

    try {
      final salary = await apiService.calculateSalary(
        email: email,
        month: _selectedMonth,
        hourlyRate: _hourlyRate,
      );

      final history = await apiService.getSalaryHistory(email);

      if (mounted) {
        setState(() {
          _currentSalary = salary;
          _salaryHistory = history['history'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load salary: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Salary Overview"), elevation: 1),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Monthly Salary",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Based on your attendance hours",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedMonth,
                        decoration: const InputDecoration(
                          labelText: "Select Month",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        items: _generateMonthOptions().map((month) {
                          return DropdownMenuItem(
                            value: month,
                            child: Text(
                              DateFormat(
                                'MMMM yyyy',
                              ).format(DateTime.parse('$month-01')),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedMonth = value;
                              _loading = true;
                            });
                            _loadSalaryData();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_currentSalary != null) _buildSalaryCard(),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hourly Rate (KES)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixText: "KES ",
                              border: OutlineInputBorder(),
                              hintText: "Enter hourly rate",
                            ),
                            controller: TextEditingController(
                              text: _hourlyRate.toString(),
                            ),
                            onChanged: (value) {
                              final rate = double.tryParse(value);
                              if (rate != null) {
                                _hourlyRate = rate;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _loadSalaryData,
                          child: const Text("Recalculate"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Default: KES 500/hour. Adjust based on your contract.",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Payment History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryCard() {
    final salary = _currentSalary!;
    final netSalary = salary['net_salary']?.toStringAsFixed(2) ?? '0.00';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF0066CC), Color(0xFF004499)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                "Net Salary",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "KES $netSalary",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBreakdownItem(
                    "Hours",
                    "${salary['total_hours']?.toStringAsFixed(1) ?? '0'} hrs",
                    Colors.white70,
                  ),
                  _buildBreakdownItem(
                    "Gross",
                    "KES ${salary['gross_salary']?.toStringAsFixed(2) ?? '0'}",
                    Colors.white70,
                  ),
                  _buildBreakdownItem(
                    "Deductions",
                    "-KES ${salary['deductions']?.toStringAsFixed(2) ?? '0'}",
                    Colors.red[200],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String value, Color? valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (_salaryHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            "No salary history available",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _salaryHistory.length,
      itemBuilder: (context, index) {
        final item = _salaryHistory[index];
        final month = item['month'] ?? '';
        final netSalary = item['net_salary']?.toStringAsFixed(2) ?? '0.00';
        final hours = item['total_hours']?.toStringAsFixed(1) ?? '0';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                DateFormat('MMM').format(DateTime.parse('$month-01')),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            title: Text(
              DateFormat('MMMM yyyy').format(DateTime.parse('$month-01')),
            ),
            subtitle: Text("$hours hours worked"),
            trailing: Text(
              "KES $netSalary",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  List<String> _generateMonthOptions() {
    final options = <String>[];
    final now = DateTime.now();

    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      options.add(DateFormat('yyyy-MM').format(date));
    }

    return options;
  }
}
