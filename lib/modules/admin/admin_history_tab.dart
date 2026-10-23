import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'models/distress_signal.dart';
import 'services/distress_sync_service.dart';

class AdminHistoryTab extends StatefulWidget {
  const AdminHistoryTab({super.key});

  @override
  State<AdminHistoryTab> createState() => _AdminHistoryTabState();
}

class _AdminHistoryTabState extends State<AdminHistoryTab> {
  final TextEditingController _searchController = TextEditingController();
  List<EmergencyHistoryRecord> _records = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _records = DistressSyncService.historyRecordsNotifier.value;
    _isLoading = _records.isEmpty;
    DistressSyncService.historyRecordsNotifier.addListener(_onHistoryUpdated);
    _loadHistory();
  }

  void _onHistoryUpdated() {
    if (mounted) {
      setState(() {
        _records = DistressSyncService.historyRecordsNotifier.value;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    DistressSyncService.historyRecordsNotifier.removeListener(_onHistoryUpdated);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    await DistressSyncService.refresh();
    if (mounted) {
      setState(() {
        _records = DistressSyncService.historyRecordsNotifier.value;
        _isLoading = false;
      });
    }
  }

  void _showClearHistoryDialog() {
    final dark = isGlassDark(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? const Color(0xFF1B1D28) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: kGoogleRed, size: 24),
            const SizedBox(width: 8),
            Text(
              'Clear History?',
              style: TextStyle(
                color: dark ? Colors.white : const Color(0xFF16181F),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to clear all emergency records? This action cannot be undone.',
          style: TextStyle(
            color: dark ? Colors.white70 : Colors.black87,
            fontSize: 13.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: dark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await DistressSyncService.clearHistory();
              if (mounted) {
                setState(() {
                  _records = [];
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF2E7D32),
                    content: Text(
                      'Emergency history cleared successfully.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kGoogleRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'CLEAR HISTORY',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<EmergencyHistoryRecord> get _filteredRecords {
    return _records.where((rec) {
      final matchesSearch = _searchQuery.isEmpty ||
          rec.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          rec.completeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          rec.program.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          rec.roomName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _selectedStatusFilter == 'ALL' ||
          rec.status.toUpperCase().contains(_selectedStatusFilter.toUpperCase());

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Color _getStatusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('ACTIVE')) return const Color(0xFFE50914);
    if (s.contains('DISPATCH')) return const Color(0xFFFF9100);
    return const Color(0xFF2E7D32);
  }

  void _showRecordDetails(EmergencyHistoryRecord record) {
    final dark = isGlassDark(context);
    final statusColor = _getStatusColor(record.status);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: dark ? const Color(0xF2141622) : Colors.white.withValues(alpha: 0.95),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.receipt_long, color: statusColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Log: ${record.id}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: dark ? Colors.white : const Color(0xFF16181F),
                                ),
                              ),
                              Text(
                                'Source: fast_stud_record table',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: dark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            record.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: dark ? Colors.white12 : Colors.black12, height: 1),
                    const SizedBox(height: 14),

                    // Required Student Information
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF1E2130) : const Color(0xFFF3F4F8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _buildField(
                            label: 'Student Complete Name',
                            value: record.completeName,
                            icon: Icons.person,
                            dark: dark,
                          ),
                          const Divider(height: 16),
                          _buildField(
                            label: 'Student ID',
                            value: record.studentId,
                            icon: Icons.badge,
                            dark: dark,
                          ),
                          const Divider(height: 16),
                          _buildField(
                            label: 'Program',
                            value: record.program,
                            icon: Icons.school,
                            dark: dark,
                          ),
                          const Divider(height: 16),
                          _buildField(
                            label: 'Year Level',
                            value: record.yearLevel,
                            icon: Icons.grade,
                            dark: dark,
                          ),
                          const Divider(height: 16),
                          _buildField(
                            label: 'user_reqtime',
                            value: record.userReqTime,
                            icon: Icons.access_time_filled,
                            dark: dark,
                            highlightValue: true,
                          ),
                          const Divider(height: 16),
                          _buildField(
                            label: 'Location / Room',
                            value: '${record.roomName} (${record.floor == 0 ? "Ground Floor" : "Second Floor"})',
                            icon: Icons.location_on,
                            dark: dark,
                          ),
                          if (record.responderNotes != null) ...[
                            const Divider(height: 16),
                            _buildField(
                              label: 'Responder Notes',
                              value: record.responderNotes!,
                              icon: Icons.notes,
                              dark: dark,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGoogleRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('CLOSE LOG', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    required IconData icon,
    required bool dark,
    bool highlightValue = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: kGoogleRed),
        const SizedBox(width: 10),
        SizedBox(
          width: 135,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: highlightValue
                  ? const Color(0xFFE50914)
                  : (dark ? Colors.white : const Color(0xFF16181F)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = isGlassDark(context);
    final displayedRecords = _filteredRecords;

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: kGoogleRed,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // Header
          Row(
            children: [
              Text(
                'Distress History',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: dark ? Colors.white : const Color(0xFF16181F),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: dark ? Colors.white70 : Colors.black54,
                ),
                tooltip: 'Clear History',
                onPressed: _showClearHistoryDialog,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: kGoogleRed),
                tooltip: 'Refresh Records',
                onPressed: _loadHistory,
              ),
            ],
          ),

          // Search Bar
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: dark ? const Color(0xCC161824) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TextStyle(
                fontSize: 13,
                color: dark ? Colors.white : const Color(0xFF16181F),
              ),
              decoration: InputDecoration(
                hintText: 'Search by Student ID, Name, Program...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: dark ? Colors.white38 : Colors.black38,
                ),
                prefixIcon: const Icon(Icons.search, size: 20, color: kGoogleRed),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', dark),
                const SizedBox(width: 6),
                _buildFilterChip('ACTIVE', dark),
                const SizedBox(width: 6),
                _buildFilterChip('DISPATCHED', dark),
                const SizedBox(width: 6),
                _buildFilterChip('RESOLVED', dark),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Records List
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: kGoogleRed),
              ),
            )
          else if (displayedRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 48,
                      color: dark ? Colors.white30 : Colors.black26,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No emergency records found matching "$_searchQuery"',
                      style: TextStyle(
                        fontSize: 13,
                        color: dark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedRecords.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final rec = displayedRecords[index];
                final statusColor = _getStatusColor(rec.status);

                return Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: dark ? const Color(0xB3141620) : Colors.white.withValues(alpha: 0.88),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showRecordDetails(rec),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Complete Name + Status Badge
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.person, color: statusColor, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Student Complete Name
                                    Text(
                                      rec.completeName,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: dark ? Colors.white : const Color(0xFF16181F),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    // Student ID
                                    Text(
                                      'Student ID: ${rec.studentId}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: dark ? Colors.white70 : const Color(0xFF555B6E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  rec.status,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(height: 1, color: dark ? Colors.white10 : Colors.black12),
                          const SizedBox(height: 10),

                          // Program and Year Level
                          Row(
                            children: [
                              Icon(Icons.school, size: 14, color: dark ? Colors.white60 : Colors.black54),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${rec.program} • ${rec.yearLevel}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: dark ? Colors.white70 : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Location & user_reqtime
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: kGoogleRed),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  rec.roomName,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: dark ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.access_time, size: 13, color: kGoogleRed),
                              const SizedBox(width: 4),
                              Text(
                                rec.userReqTime,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE50914),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool dark) {
    final isSelected = _selectedStatusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? kGoogleRed
              : (dark ? const Color(0xCC1A1C28) : Colors.white.withValues(alpha: 0.85)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? kGoogleRed
                : (dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : (dark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
