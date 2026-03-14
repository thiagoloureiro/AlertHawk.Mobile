import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_selector_modal.dart';
import '../services/metrics_service.dart';
import '../models/cluster_event.dart';

class ClusterEventsScreen extends StatefulWidget {
  const ClusterEventsScreen({super.key});

  @override
  State<ClusterEventsScreen> createState() => _ClusterEventsScreenState();
}

class _ClusterEventsScreenState extends State<ClusterEventsScreen> {
  List<String> _clusters = [];
  String? _selectedCluster;
  List<String> _namespaces = [];
  String? _selectedNamespace; // null = All
  List<ClusterEvent> _events = [];
  bool _isLoadingClusters = false;
  bool _isLoadingEvents = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _selectedMinutes = 1440;
  final ScrollController _scrollController = ScrollController();

  List<ClusterEvent> get _filteredEvents =>
      _selectedNamespace == null
          ? _events
          : _events.where((e) => e.namespace == _selectedNamespace).toList();

  static const List<int> _minutesOptions = [60, 360, 720, 1440, 4320, 10080];
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadClusters();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _selectedCluster == null) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadClusters() async {
    setState(() {
      _isLoadingClusters = true;
      _errorMessage = null;
    });

    try {
      final clusters = await MetricsService.getClusters();
      setState(() {
        _clusters = clusters;
        if (clusters.isNotEmpty && _selectedCluster == null) {
          _selectedCluster = clusters.first;
          _loadNamespaces();
          _loadEvents();
        }
        _isLoadingClusters = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingClusters = false;
      });
    }
  }

  Future<void> _loadNamespaces() async {
    if (_selectedCluster == null) return;
    try {
      final namespaces = await MetricsService.getNamespaces(
        clusterName: _selectedCluster!,
      );
      if (mounted) {
        setState(() {
          _namespaces = namespaces..sort();
          if (_selectedNamespace != null &&
              !_namespaces.contains(_selectedNamespace)) {
            _selectedNamespace = null;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _namespaces = []);
      }
    }
  }

  Future<void> _loadEvents() async {
    if (_selectedCluster == null) return;

    setState(() {
      _isLoadingEvents = true;
      _errorMessage = null;
      _events = [];
      _hasMore = true;
    });

    try {
      final events = await MetricsService.getEvents(
        clusterName: _selectedCluster!,
        minutes: _selectedMinutes,
        limit: _pageSize,
        offset: 0,
        namespace: _selectedNamespace,
      );
      setState(() {
        _events = events;
        _hasMore = events.length >= _pageSize;
        _isLoadingEvents = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load events: ${e.toString()}';
        _isLoadingEvents = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_selectedCluster == null || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final more = await MetricsService.getEvents(
        clusterName: _selectedCluster!,
        minutes: _selectedMinutes,
        limit: _pageSize,
        offset: _events.length,
        namespace: _selectedNamespace,
      );
      setState(() {
        _events = [..._events, ...more];
        _hasMore = more.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load more: ${e.toString()}';
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cluster Events',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Select theme',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => showThemeSelectorModal(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadClusters();
          if (_selectedCluster != null) {
            await _loadEvents();
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Cluster',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _isLoadingClusters
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<String>(
                                  initialValue: _selectedCluster,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  style: GoogleFonts.inter(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  dropdownColor: isDarkMode
                                      ? Theme.of(context).colorScheme.surface
                                      : Colors.white,
                                  items: _clusters.map((cluster) {
                                    return DropdownMenuItem<String>(
                                      value: cluster,
                                      child: Text(
                                        cluster,
                                        style: GoogleFonts.inter(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCluster = value;
                                      _selectedNamespace = null;
                                    });
                                    _loadNamespaces();
                                    _loadEvents();
                                  },
                                ),
                          if (_selectedCluster != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Namespace',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String?>(
                              initialValue: _selectedNamespace,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              style: GoogleFonts.inter(
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              dropdownColor: isDarkMode
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.white,
                              items: [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text(
                                    'All',
                                    style: GoogleFonts.inter(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                ..._namespaces.map((ns) {
                                  return DropdownMenuItem<String?>(
                                    value: ns,
                                    child: Text(
                                      ns,
                                      style: GoogleFonts.inter(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedNamespace = value);
                                _loadEvents();
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Time Range:',
                                style: GoogleFonts.inter(),
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<int>(
                                value: _selectedMinutes,
                                style: GoogleFonts.inter(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                dropdownColor: isDarkMode
                                    ? Theme.of(context).colorScheme.surface
                                    : Colors.white,
                                items: _minutesOptions.map((minutes) {
                                  final hours = minutes ~/ 60;
                                  final label = hours >= 24
                                      ? '${hours ~/ 24} days'
                                      : '$hours hours';
                                  return DropdownMenuItem<int>(
                                    value: minutes,
                                    child: Text(
                                      label,
                                      style: GoogleFonts.inter(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedMinutes = value;
                                    });
                                    _loadEvents();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.red.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(color: Colors.red.shade900),
                        ),
                      ),
                    ),
                  ],
                  if (_isLoadingEvents) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (!_isLoadingEvents && _events.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${_events.length} events (scroll for more)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!_isLoadingEvents &&
                      !_isLoadingClusters &&
                      _events.isEmpty &&
                      _selectedCluster != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'No events in the selected time range',
                        style: GoogleFonts.inter(
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
            if (!_isLoadingEvents && _events.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList.builder(
                  itemCount: _events.length + (_hasMore || _isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _events.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: _isLoadingMore
                              ? const CircularProgressIndicator()
                              : Text(
                                  'Loading more...',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade700,
                                  ),
                                ),
                        ),
                      );
                    }
                    return _buildEventCard(_events[index], isDarkMode);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(ClusterEvent event, bool isDarkMode) {
    final isWarning = event.eventType == 'Warning';
    final typeColor = isWarning ? Colors.orange : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.reason,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              event.eventType,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: typeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.message,
                        style: GoogleFonts.inter(fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _chip(
                            Icons.schedule,
                            DateFormat('MMM d, HH:mm:ss').format(event.timestamp),
                            isDarkMode,
                          ),
                          _chip(
                            Icons.folder,
                            event.namespace,
                            isDarkMode,
                          ),
                          _chip(
                            Icons.category,
                            '${event.involvedObjectKind}: ${event.involvedObjectName}',
                            isDarkMode,
                          ),
                          if (event.sourceComponent.isNotEmpty)
                            _chip(
                              Icons.source,
                              event.sourceComponent,
                              isDarkMode,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDarkMode
                  ? Colors.grey.shade400
                  : Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
