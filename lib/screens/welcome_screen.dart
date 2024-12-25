import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/monitor_status.dart';
import '../models/monitor_group.dart';
import '../services/auth_service.dart';
import 'about_screen.dart';
import 'login_screen.dart';
import '../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/environment.dart';
import 'monitor_detail_screen.dart';
import 'alerts_screen.dart';
import '../config/app_config.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late Future<MonitorStatus> _monitorStatus;
  late Future<List<MonitorGroup>> _monitorGroups;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';
  Environment _selectedEnvironment = Environment.production;

  @override
  void initState() {
    super.initState();
    _monitorStatus = _fetchMonitorStatus();
    _monitorGroups = _fetchMonitorGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<MonitorGroup>> _fetchMonitorGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse(
          '${AppConfig.monitoringApiUrl}/api/MonitorGroup/monitorDashboardGroupListByUser/${_selectedEnvironment.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) {
        try {
          return MonitorGroup.fromJson(json);
        } catch (e) {
          print('Error parsing group: $e');
          print('Group JSON: $json');
          rethrow;
        }
      }).toList();
    } else {
      throw Exception('Failed to load monitor groups');
    }
  }

  Future<MonitorStatus> _fetchMonitorStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse(
          '${AppConfig.monitoringApiUrl}/api/Monitor/monitorStatusDashboard/${_selectedEnvironment.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return MonitorStatus.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load monitor status');
    }
  }

  Widget _buildMonitorCard(Monitor monitor) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MonitorDetailScreen(monitor: monitor),
            ),
          );
        },
        child: ListTile(
          title: Text(
            monitor.name,
            style: GoogleFonts.robotoMono(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                '1h: ${monitor.monitorStatusDashboard.uptime1Hr}%',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Text(
                ' | ',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.5),
                ),
              ),
              Text(
                '24h: ${monitor.monitorStatusDashboard.uptime24Hrs}%',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Text(
                ' | ',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.5),
                ),
              ),
              Text(
                '7d: ${monitor.monitorStatusDashboard.uptime7Days}%',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          leading: Icon(
            Icons.circle,
            color: monitor.status ? Colors.green : Colors.red,
            size: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.robotoMono(),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search monitors...',
                hintStyle: GoogleFonts.robotoMono(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _statusFilter,
                  isExpanded: true,
                  style: GoogleFonts.robotoMono(),
                  items: ['All', 'Online', 'Offline'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: GoogleFonts.robotoMono(),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _statusFilter = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MonitorGroup> _filterGroups(List<MonitorGroup> groups) {
    return groups
        .map((group) {
          return MonitorGroup(
            id: group.id,
            name: group.name,
            monitors: group.monitors.where((monitor) {
              final matchesSearch = _searchQuery.isEmpty ||
                  monitor.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());

              final matchesStatus = _statusFilter == 'All' ||
                  (_statusFilter == 'Online' && monitor.status) ||
                  (_statusFilter == 'Offline' && !monitor.status);

              return matchesSearch && matchesStatus;
            }).toList(),
            avgUptime1Hr: group.avgUptime1Hr,
            avgUptime24Hrs: group.avgUptime24Hrs,
            avgUptime7Days: group.avgUptime7Days,
          );
        })
        .where((group) => group.monitors.isNotEmpty)
        .toList();
  }

  void _showEnvironmentSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Environment',
            style: GoogleFonts.robotoMono(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: Environment.values.map((env) {
              return ListTile(
                title: Text(
                  env.name,
                  style: GoogleFonts.robotoMono(),
                ),
                leading: Radio<Environment>(
                  value: env,
                  groupValue: _selectedEnvironment,
                  onChanged: (Environment? value) {
                    if (value != null) {
                      setState(() {
                        _selectedEnvironment = value;
                        _monitorStatus = _fetchMonitorStatus();
                        _monitorGroups = _fetchMonitorGroups();
                      });
                      Navigator.of(context).pop();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'about':
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
                break;
              case 'environment':
                _showEnvironmentSelector();
                break;
              case 'logout':
                await AuthService(
                  await SharedPreferences.getInstance(),
                  navigatorKey,
                ).logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
                break;
              case 'alerts':
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'environment',
              child: Row(
                children: [
                  const Icon(Icons.computer),
                  const SizedBox(width: 8),
                  Text(
                    _selectedEnvironment.name,
                    style: GoogleFonts.robotoMono(),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'alerts',
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'Alerts',
                    style: GoogleFonts.robotoMono(),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'about',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('About'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
        title: FutureBuilder<MonitorStatus>(
          future: _monitorStatus,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Text(
                  'Loading...',
                  style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error',
                  style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
                ),
              );
            }

            final status = snapshot.data!;
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '↑${status.monitorUp}',
                    style: GoogleFonts.robotoMono(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '↓${status.monitorDown}',
                    style: GoogleFonts.robotoMono(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '⏸',
                        style: GoogleFonts.robotoMono(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${status.monitorPaused}',
                        style: GoogleFonts.robotoMono(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _monitorStatus = _fetchMonitorStatus();
            _monitorGroups = _fetchMonitorGroups();
          });
        },
        child: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: FutureBuilder<List<MonitorGroup>>(
                future: _monitorGroups,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading monitors',
                        style: GoogleFonts.robotoMono(color: Colors.red),
                      ),
                    );
                  }

                  final filteredGroups = _filterGroups(snapshot.data!);

                  if (filteredGroups.isEmpty) {
                    return Center(
                      child: Text(
                        'No monitors found',
                        style: GoogleFonts.robotoMono(),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredGroups.length,
                    itemBuilder: (context, groupIndex) {
                      final group = filteredGroups[groupIndex];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              group.name,
                              style: GoogleFonts.robotoMono(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...group.monitors.map(_buildMonitorCard).toList(),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
