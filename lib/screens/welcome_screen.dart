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
import '../widgets/theme_selector_modal.dart';
import '../models/environment.dart';
import 'monitor_detail_screen.dart';
import 'alerts_screen.dart';
import '../config/app_config.dart';
import 'agents_screen.dart';
import 'package:flutter_new_badger/flutter_new_badger.dart';
import '../models/monitor_group_selection.dart';
import 'cluster_metrics_screen.dart';
import 'clusters_dashboard_screen.dart';
import 'cluster_events_screen.dart';
import 'application_metrics_screen.dart';
import 'volume_metrics_screen.dart';
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
    IconData monitorIcon;
    String monitorType;
    String? targetInfo;

    switch (monitor.monitorTypeId) {
      case 1:
        monitorIcon = Icons.public;
        monitorType = 'HTTP';
        targetInfo = monitor.checkTarget;
        break;
      case 3:
        monitorIcon = Icons.lan;
        monitorType = 'TCP';
        targetInfo = null;
        break;
      case 4:
        monitorIcon = Icons.dns;
        monitorType = 'K8s';
        targetInfo = null;
        break;
      default:
        monitorIcon = Icons.monitor;
        monitorType = 'Unknown';
        targetInfo = monitor.checkTarget;
    }

    final statusColor = monitor.paused
        ? Colors.orange
        : monitor.status
            ? const Color(0xFF22C55E)
            : const Color(0xFFEF4444);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MonitorDetailScreen(monitor: monitor),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: statusColor,
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          monitorIcon,
                          color: statusColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monitor.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (targetInfo != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                targetInfo,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(isDark ? 0.8 : 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          monitorType,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildUptimeChip(
                          '1h', monitor.monitorStatusDashboard.uptime1Hr),
                      const SizedBox(width: 8),
                      _buildUptimeChip(
                          '24h', monitor.monitorStatusDashboard.uptime24Hrs),
                      const SizedBox(width: 8),
                      _buildUptimeChip(
                          '7d', monitor.monitorStatusDashboard.uptime7Days),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUptimeChip(String label, double uptime) {
    final color = uptime >= 99.9
        ? const Color(0xFF22C55E)
        : uptime >= 95
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${uptime.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search monitors...',
                    hintStyle: GoogleFonts.inter(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _showGroupSelectionDialog,
                tooltip: 'Filter by groups',
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurface,
                ),
                icon: const Icon(Icons.filter_list_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              ...['All', 'Online', 'Offline', 'Paused'].map((value) {
                final isSelected = _statusFilter == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _statusFilter = value;
                        });
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(
          count,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
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
                  (_statusFilter == 'Online' &&
                      !monitor.paused &&
                      monitor.status) ||
                  (_statusFilter == 'Offline' &&
                      !monitor.paused &&
                      !monitor.status) ||
                  (_statusFilter == 'Paused' && monitor.paused);

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
          builder: (dialogContext) {
            final media = MediaQuery.of(context);
            return StatefulBuilder(
              builder: (context, setDialogState) => Dialog(
                insetPadding: EdgeInsets.only(
                  left: media.size.width * 0.03,
                  right: media.size.width * 0.03,
                  top: media.size.height * 0.05,
                  bottom: 0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: media.size.width * 0.94,
                    maxHeight: media.size.height * 0.88,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Select Groups',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  for (var group in sortedGroups) {
                                    group.isSelected = false;
                                  }
                                });
                              },
                              child: Text(
                                'Clear All',
                                style: GoogleFonts.inter(),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  for (var group in sortedGroups) {
                                    group.isSelected = true;
                                  }
                                });
                              },
                              child: Text(
                                'Select All',
                                style: GoogleFonts.inter(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Scrollbar(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: sortedGroups.length,
                            itemBuilder: (context, index) {
                              final group = sortedGroups[index];
                              return CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 2,
                                ),
                                visualDensity: VisualDensity.compact,
                                title: Text(
                                  group.name,
                                  style: GoogleFonts.inter(fontSize: 15),
                                ),
                                value: group.isSelected,
                                onChanged: (bool? value) {
                                  setDialogState(() {
                                    group.isSelected = value ?? false;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 8,
                          bottom: 8 + media.padding.bottom,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(),
                              ),
                            ),
                            FilledButton(
                              onPressed: () {
                                final selectedGroupIds = sortedGroups
                                    .where((group) => group.isSelected)
                                    .map((group) => group.id.toString())
                                    .toList();
                                prefs.setStringList(
                                    'selected_groups', selectedGroupIds);

                                Navigator.pop(dialogContext);

                                setState(() {
                                  _monitorGroups = _fetchMonitorGroups();
                                });
                              },
                              child: Text(
                                'Save',
                                style: GoogleFonts.inter(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
              case 'clusters_dashboard':
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ClustersDashboardScreen()),
                );
                break;
              case 'cluster_events':
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ClusterEventsScreen()),
                );
                break;
              case 'application_metrics':
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ApplicationMetricsScreen()),
                );
                break;
              case 'volume_metrics':
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const VolumeMetricsScreen()),
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
              value: 'clusters_dashboard',
              child: Row(
                children: [
                  const Icon(Icons.dashboard_rounded),
                  const SizedBox(width: 8),
                  Text(
                    'Clusters Dashboard',
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'cluster_events',
              child: Row(
                children: [
                  const Icon(Icons.event_note),
                  const SizedBox(width: 8),
                  Text(
                    'Cluster Events',
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
              value: 'volume_metrics',
              child: Row(
                children: [
                  const Icon(Icons.storage),
                  const SizedBox(width: 8),
                  Text(
                    'Volume Metrics',
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
            if (!snapshot.hasData) {
              return Text(
                'Monitors',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              );
            }
            // Counts in title are always overall (unfiltered)
            final groups = snapshot.data!;
            int upCount = 0, downCount = 0, pausedCount = 0;
            for (var g in groups) {
              for (var m in g.monitors) {
                if (m.paused) {
                  pausedCount++;
                } else if (m.status) {
                  upCount++;
                } else {
                  downCount++;
                }
              }
            }
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _summaryItem(Icons.check_circle_rounded, '$upCount',
                      const Color(0xFF22C55E)),
                  const SizedBox(width: 20),
                  _summaryItem(Icons.cancel_rounded, '$downCount',
                      const Color(0xFFEF4444)),
                  const SizedBox(width: 20),
                  _summaryItem(Icons.pause_circle_rounded, '$pausedCount',
                      const Color(0xFFF59E0B)),
                ],
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Select theme',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => showThemeSelectorModal(context),
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 56,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No monitors found',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: filteredGroups.length,
                          itemBuilder: (context, index) {
                            final group = filteredGroups[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 20, 16, 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withOpacity(0.6),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          group.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
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
