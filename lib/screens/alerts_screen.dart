import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pushy_flutter/pushy_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/monitor_alert.dart';
import '../models/environment.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AlertsScreen extends StatefulWidget {
  final int? monitorId;

  const AlertsScreen({super.key, this.monitorId});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late Future<List<MonitorAlert>> _alerts;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedDays = 7;

  final List<int> _dayOptions = [1, 7, 30, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    _alerts = _fetchAlerts();

    // Clear iOS app badge number when alerts are loaded
    Pushy.clearBadge();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<MonitorAlert>> _fetchAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final url = widget.monitorId != null
        ? '${AppConfig.monitoringApiUrl}/api/MonitorAlert/monitorAlerts/${widget.monitorId}/$_selectedDays'
        : '${AppConfig.monitoringApiUrl}/api/MonitorAlert/monitorAlerts/0/$_selectedDays';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => MonitorAlert.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load alerts');
    }
  }

  List<MonitorAlert> _filterAlerts(List<MonitorAlert> alerts) {
    if (_searchQuery.isEmpty) return alerts;
    return alerts
        .where((alert) => alert.monitorName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
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
                  child: DropdownButton<int>(
                    value: _selectedDays,
                    isExpanded: true,
                    style: GoogleFonts.robotoMono(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    items: _dayOptions.map((days) {
                      return DropdownMenuItem<int>(
                        value: days,
                        child: Text(
                          '$days days',
                          style: GoogleFonts.robotoMono(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedDays = newValue;
                          _alerts = _fetchAlerts();
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alerts',
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
        child: Column(
          children: [
            _buildFilters(),
            // Alerts list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _alerts = _fetchAlerts();
                  });
                },
                child: FutureBuilder<List<MonitorAlert>>(
                  future: _alerts,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error loading alerts',
                              style: GoogleFonts.robotoMono(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () {
                                setState(() {
                                  _alerts = _fetchAlerts();
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    final filteredAlerts = _filterAlerts(snapshot.data!);

                    if (filteredAlerts.isEmpty) {
                      return Center(
                        child: Text(
                          'No alerts found',
                          style: GoogleFonts.robotoMono(),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredAlerts.length,
                      itemBuilder: (context, index) {
                        final alert = filteredAlerts[index];
                        final env = Environment.values.firstWhere(
                          (e) => e.id == alert.environment,
                          orElse: () => Environment.production,
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(
                              alert.monitorName,
                              style: GoogleFonts.robotoMono(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('yyyy-MM-dd HH:mm:ss')
                                      .format(alert.localTimeStamp),
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Environment: ${env.name}',
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 12,
                                  ),
                                ),
                                if (!alert.status && alert.periodOffline > 0)
                                  Text(
                                    'Offline for: ${alert.periodOffline} minutes',
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                Text(
                                  alert.message,
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
