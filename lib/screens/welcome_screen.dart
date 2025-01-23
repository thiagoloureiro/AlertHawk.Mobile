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
            color: monitor.paused
                ? Colors.grey
                : monitor.status
                    ? Colors.green
                    : Colors.red,
            size: 12,
          ),
        ),
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
                style: GoogleFonts.robotoMono(),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search...',
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
                    style: GoogleFonts.robotoMono(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    items: ['All', 'Online', 'Offline'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: GoogleFonts.robotoMono(
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
            style: GoogleFonts.robotoMono(
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
                    style: GoogleFonts.robotoMono(),
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
              title: Text('Select Groups', style: GoogleFonts.robotoMono()),
              content: Container(
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
                                  style: GoogleFonts.robotoMono()),
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
                                  style: GoogleFonts.robotoMono()),
                            ),
                          ],
                        ),
                        ...sortedGroups.map((group) {
                          return CheckboxListTile(
                            title: Text(group.name,
                                style: GoogleFonts.robotoMono()),
                            value: group.isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                group.isSelected = value ?? false;
                              });
                            },
                          );
                        }).toList(),
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
                  child: Text('Save', style: GoogleFonts.robotoMono()),
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
                        style: GoogleFonts.robotoMono(),
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
                    style: GoogleFonts.robotoMono(),
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
                    style: GoogleFonts.robotoMono(),
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
                    style: GoogleFonts.robotoMono(),
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
                    style: GoogleFonts.robotoMono(),
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
                        style: GoogleFonts.robotoMono(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        '↓$downCount',
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
                            '$pausedCount',
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
                          style: GoogleFonts.robotoMono(),
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
                              style: GoogleFonts.robotoMono(),
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
                                    style: GoogleFonts.robotoMono(
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
