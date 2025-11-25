import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pushy_flutter/pushy_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/monitor_group.dart';
import '../services/auth_service.dart';
import 'about_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import '../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/environment.dart';
import 'monitor_detail_screen.dart';
import 'alerts_screen.dart';
import '../config/app_config.dart';
import 'agents_screen.dart';
import 'package:flutter_new_badger/flutter_new_badger.dart';
import '../models/monitor_group_selection.dart';
import 'cluster_metrics_screen.dart';
import 'application_metrics_screen.dart';
import 'dart:io';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late Future<List<MonitorGroup>> _monitorGroups;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';
  Environment _selectedEnvironment = Environment.production;

  @override
  void initState() {
    super.initState();
    _monitorGroups = _fetchMonitorGroups();

    // Clear iOS app badge number when welcome_page is loaded
    Pushy.clearBadge();
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
          rethrow;
        }
      }).toList();
    } else {
      throw Exception('Failed to load monitor groups');
    }
  }

  Widget _buildMonitorCard(Monitor monitor) {
    // Get the appropriate icon based on monitor type
    IconData monitorIcon;
    String monitorType;
    String?
        targetInfo; // Make it nullable since we won't show it for TCP and K8s

    switch (monitor.monitorTypeId) {
      case 1:
        monitorIcon = Icons.public;
        monitorType = 'HTTP';
        targetInfo = monitor.checkTarget;
        break;
      case 3:
        monitorIcon = Icons.lan;
        monitorType = 'TCP';
        // Remove target info for TCP monitors
        targetInfo = null;
        break;
      case 4:
        monitorIcon = Icons.dns;
        monitorType = 'K8s';
        // Remove target info for Kubernetes monitors
        targetInfo = null;
        break;
      default:
        monitorIcon = Icons.monitor;
        monitorType = 'Unknown';
        targetInfo = monitor.checkTarget;
    }

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
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    monitorIcon,
                    color: monitor.paused
                        ? Colors.grey
                        : monitor.status
                            ? Colors.green
                            : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      monitor.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      monitorType,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              if (targetInfo != null) ...[
                const SizedBox(height: 8),
                Text(
                  targetInfo,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildUptimeChip(
                      '1h', monitor.monitorStatusDashboard.uptime1Hr),
                  _buildUptimeChip(
                      '24h', monitor.monitorStatusDashboard.uptime24Hrs),
                  _buildUptimeChip(
                      '7d', monitor.monitorStatusDashboard.uptime7Days),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUptimeChip(String label, double uptime) {
    final color = uptime >= 99.9
        ? Colors.green
        : uptime >= 95
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${uptime.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: GoogleFonts.inter(),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: SizedBox(
              height: 48,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    isExpanded: true,
                    style: GoogleFonts.inter(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    dropdownColor: isDarkMode 
                        ? Theme.of(context).colorScheme.surface 
                        : Colors.white,
                    items: ['All', 'Online', 'Offline'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: GoogleFonts.inter(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
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
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showGroupSelectionDialog,
            tooltip: 'Filter Groups',
          ),
        ],
      ),
    );
  }

  Future<List<MonitorGroup>> _filterGroups(List<MonitorGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedGroups = prefs.getStringList('selected_groups') ?? [];

    // First filter by selected groups if any are selected
    var filteredGroups = selectedGroups.isEmpty
        ? groups
        : groups
            .where((group) => selectedGroups.contains(group.id.toString()))
            .toList();

    // Then sort the groups alphabetically by name
    filteredGroups
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return filteredGroups
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
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: Environment.values.map((env) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedEnvironment = env;
                    _monitorGroups = _fetchMonitorGroups();
                  });
                  Navigator.of(context).pop();
                },
                child: ListTile(
                  title: Text(
                    env.name,
                    style: GoogleFonts.inter(),
                  ),
                  leading: Radio<Environment>(
                    value: env,
                    groupValue: _selectedEnvironment,
                    onChanged: (Environment? value) {
                      if (value != null) {
                        setState(() {
                          _selectedEnvironment = value;
                          _monitorGroups = _fetchMonitorGroups();
                        });
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<bool> _hasUnreadAlerts() async {
    if (Platform.isIOS) {
      final prefs = await SharedPreferences.getInstance();
      final hasNotificationFlag =
          prefs.getString('notification')?.isNotEmpty ?? false;
      final badgeCount = await FlutterNewBadger.getBadge() ?? 0;

      return hasNotificationFlag || badgeCount > 0;
    }
    return false;
  }

  void _showGroupSelectionDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final savedSelections = prefs.getStringList('selected_groups') ?? [];

    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.monitoringApiUrl}/api/MonitorGroup/monitorGroupListByUser'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final groups = jsonData
            .map((json) => MonitorGroupSelection.fromJson(json))
            .toList();

        // Set initial selection state from saved preferences
        for (var group in groups) {
          group.isSelected = savedSelections.contains(group.id.toString());
        }

        // Sort the groups alphabetically
        final sortedGroups = groups.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        await showDialog(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text('Select Groups', style: GoogleFonts.inter()),
              content: SizedBox(
                width: 400,
                height: 400,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  for (var group in sortedGroups) {
                                    group.isSelected = false;
                                  }
                                });
                              },
                              child: Text('Clear All',
                                  style: GoogleFonts.inter()),
                            ),
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  for (var group in sortedGroups) {
                                    group.isSelected = true;
                                  }
                                });
                              },
                              child: Text('Select All',
                                  style: GoogleFonts.inter()),
                            ),
                          ],
                        ),
                        ...sortedGroups.map((group) {
                          return CheckboxListTile(
                            title: Text(group.name,
                                style: GoogleFonts.inter()),
                            value: group.isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                group.isSelected = value ?? false;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final selectedGroupIds = sortedGroups
                        .where((group) => group.isSelected)
                        .map((group) => group.id.toString())
                        .toList();
                    prefs.setStringList('selected_groups', selectedGroupIds);

                    Navigator.pop(dialogContext);

                    // Use the outer setState to refresh the main screen
                    setState(() {
                      _monitorGroups = _fetchMonitorGroups();
                    });
                  },
                  child: Text('Save', style: GoogleFonts.inter()),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error loading groups, check your internet connection.')),
        );
      }
    }
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
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token');
                await prefs.remove('user_email');
                await prefs.remove('deviceToken');
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
                // Clear notification flag and badge count
                Pushy.clearBadge(); // Still clear the visual badge

                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AlertsScreen()),
                  );
                }
                break;
              case 'agents':
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AgentsScreen()),
                );
                break;
              case 'settings':
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                break;
              case 'cluster_metrics':
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ClusterMetricsScreen()),
                );
                break;
              case 'application_metrics':
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ApplicationMetricsScreen()),
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
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'alerts',
              child: FutureBuilder<bool>(
                future: _hasUnreadAlerts(),
                builder: (context, snapshot) {
                  final hasAlerts = snapshot.data ?? false;
                  return Row(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: hasAlerts ? Colors.red : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Alerts',
                        style: GoogleFonts.inter(),
                      ),
                    ],
                  );
                },
              ),
            ),
            PopupMenuItem(
              value: 'agents',
              child: Row(
                children: [
                  const Icon(Icons.list),
                  const SizedBox(width: 8),
                  Text(
                    'Agents',
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'cluster_metrics',
              child: Row(
                children: [
                  const Icon(Icons.analytics),
                  const SizedBox(width: 8),
                  Text(
                    'Cluster Metrics',
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'application_metrics',
              child: Row(
                children: [
                  const Icon(Icons.apps),
                  const SizedBox(width: 8),
                  Text(
                    'Application Metrics',
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'about',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text(
                    'About',
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Icons.settings),
                  const SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
            ),
          ],
        ),
        title: FutureBuilder<List<MonitorGroup>>(
          future: _monitorGroups,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Text(
                  'Loading...',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return FutureBuilder<List<MonitorGroup>>(
              future: _filterGroups(snapshot.data!),
              builder: (context, filteredSnapshot) {
                if (!filteredSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Count monitors by status
                int upCount = 0;
                int downCount = 0;
                int pausedCount = 0;

                for (var group in filteredSnapshot.data!) {
                  for (var monitor in group.monitors) {
                    if (monitor.paused) {
                      pausedCount++;
                    } else if (monitor.status) {
                      upCount++;
                    } else {
                      downCount++;
                    }
                  }
                }

                return Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '↑$upCount',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        '↓$downCount',
                        style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$pausedCount',
                            style: GoogleFonts.inter(
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
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
                          style: GoogleFonts.inter(),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return FutureBuilder<List<MonitorGroup>>(
                      future: _filterGroups(snapshot.data!),
                      builder: (context, filteredSnapshot) {
                        if (!filteredSnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final filteredGroups = filteredSnapshot.data!;
                        if (filteredGroups.isEmpty) {
                          return Center(
                            child: Text(
                              'No monitors found',
                              style: GoogleFonts.inter(),
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredGroups.length,
                          itemBuilder: (context, index) {
                            final group = filteredGroups[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    group.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...group.monitors.map(_buildMonitorCard),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
