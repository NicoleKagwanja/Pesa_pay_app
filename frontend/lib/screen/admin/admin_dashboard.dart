// ignore_for_file: use_build_context_synchronously, unused_local_variable, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pesa_pay/services/api_services.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final APIService apiService = APIService();
  bool _loading = true;
  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic>? _overview;
  List<dynamic> _sharedEvents = [];

  final _eventTitleController = TextEditingController();
  final _eventDescController = TextEditingController();
  DateTime _selectedEventDate = DateTime.now();
  String _selectedEventType = 'general';
  bool _addingEvent = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminEmail = prefs.getString('user_email') ?? '';
      final employees = await apiService.getAdminEmployees();
      final overview = await apiService.getAdminAttendanceOverview();
      final events = await apiService.getSharedEvents(
        month: DateFormat('yyyy-MM').format(DateTime.now()),
      );

      if (mounted) {
        setState(() {
          _employees = List<Map<String, dynamic>>.from(employees);
          _overview = overview;
          _sharedEvents = events;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load admin  $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addSharedEvent() async {
    if (_eventTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an event title")),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final adminEmail = prefs.getString('user_email') ?? '';

      await apiService.createSharedEvent(
        adminEmail: adminEmail,
        title: _eventTitleController.text.trim(),
        description: _eventDescController.text.trim(),
        eventDate: _selectedEventDate,
        eventType: _selectedEventType,
      );

      if (mounted) {
        setState(() {
          _addingEvent = false;
          _eventTitleController.clear();
          _eventDescController.clear();
        });
        _loadAdminData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event added successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add event: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Add Calendar Event",
            onPressed: () => setState(() => _addingEvent = !_addingEvent),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: _loadAdminData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addingEvent
          ? _buildAddEventForm()
          : _buildMainContent(),
    );
  }

  Widget _buildAddEventForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _addingEvent = false),
              ),
              const Text(
                "Add Calendar Event",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _eventTitleController,
            decoration: const InputDecoration(
              labelText: "Event Title *",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _eventDescController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Description",
              hintText: "Optional details about this event",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 16),

          ListTile(
            title: const Text("Event Date"),
            subtitle: Text(
              DateFormat('EEEE, MMMM d, yyyy').format(_selectedEventDate),
            ),
            leading: const Icon(Icons.calendar_today),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedEventDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _selectedEventDate = picked);
              }
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedEventType,
            decoration: const InputDecoration(
              labelText: "Event Type",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: ['general', 'holiday', 'meeting', 'deadline', 'announcement']
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedEventType = value);
            },
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _addingEvent = false),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _addSharedEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                  ),
                  child: const Text(
                    "Add Event",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Employees"),
              Tab(icon: Icon(Icons.analytics), text: "Overview"),
              Tab(icon: Icon(Icons.event), text: "Calendar"),
            ],
            isScrollable: true,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildEmployeesTab(),
                _buildOverviewTab(),
                _buildCalendarTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesTab() {
    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final emp = _employees[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Text(
                  (emp['name'] ?? 'E')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
              title: Text(emp['name'] ?? emp['email']),
              subtitle: Text(
                "${emp['department'] ?? 'Unknown'} • ${emp['email']}",
              ),
              trailing: IconButton(
                icon: const Icon(Icons.bar_chart),
                tooltip: "View Attendance",
                onPressed: () => _showEmployeeAttendance(emp['email']),
              ),
              onTap: () => _showEmployeeAttendance(emp['email']),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_overview == null) return const Center(child: Text("No overview data"));

    final employees = _overview!['employees'] as List? ?? [];
    final presentCount = _overview!['present_count'] ?? 0;
    final totalCount = _overview!['total_employees'] ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Total",
                  totalCount.toString(),
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Present",
                  presentCount.toString(),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Absent",
                  (totalCount - presentCount).toString(),
                  Colors.orange,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];
              final status = emp['today_status'] ?? 'unknown';
              final statusColor = status == 'present'
                  ? Colors.green
                  : status == 'clocked_in'
                  ? Colors.blue
                  : status == 'absent'
                  ? Colors.red
                  : Colors.grey;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(emp['name'] ?? emp['email']),
                  subtitle: Text(
                    "${emp['month_hours']} hrs this month • ${emp['month_days']} days",
                    style: TextStyle(fontSize: 12),
                  ),
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        status.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      if (emp['time_in'] != null)
                        Text(
                          "In: ${emp['time_in']}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  onTap: () => _showEmployeeAttendance(emp['email']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.event, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                "Shared Calendar Events",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        if (_sharedEvents.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No events scheduled",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _addingEvent = true),
                    icon: const Icon(Icons.add),
                    label: const Text("Add First Event"),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _sharedEvents.length,
              itemBuilder: (context, index) {
                final event = _sharedEvents[index];
                final eventType = event['event_type'] ?? 'general';
                final typeColor = eventType == 'holiday'
                    ? Colors.red
                    : eventType == 'meeting'
                    ? Colors.blue
                    : eventType == 'deadline'
                    ? Colors.orange
                    : Colors.purple;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        eventType == 'holiday'
                            ? Icons.beach_access
                            : eventType == 'meeting'
                            ? Icons.meeting_room
                            : eventType == 'deadline'
                            ? Icons.flag
                            : Icons.announcement,
                        color: typeColor,
                        size: 20,
                      ),
                    ),
                    title: Text(event['title']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event['description'] != null)
                          Text(
                            event['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'EEEE, MMM d',
                              ).format(DateTime.parse(event['event_date'])),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text("Edit")),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') {
                          _confirmDeleteEvent(event['id']);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showEmployeeAttendance(String email) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Viewing attendance for $email")));
  }

  Future<void> _confirmDeleteEvent(int eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Event"),
        content: const Text("Are you sure you want to delete this event?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final adminEmail = prefs.getString('user_email') ?? '';
        await apiService.deleteSharedEvent(eventId, adminEmail);
        _loadAdminData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _eventTitleController.dispose();
    _eventDescController.dispose();
    super.dispose();
  }
}
