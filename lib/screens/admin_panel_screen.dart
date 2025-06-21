import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../services/admin_service.dart';
import '../models/lost_found_item.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red[100],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Approval'),
            Tab(text: 'All Items'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildAllItemsTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return StreamBuilder<List<LostFoundItem>>(
      stream: AdminService.getPendingItemsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
                const SizedBox(height: 16),
                Text(
                  'No pending items',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'All items have been reviewed',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildPendingItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildAllItemsTab() {
    return StreamBuilder<List<LostFoundItem>>(
      stream: AdminService.getAllItemsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No items found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildAllItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildPendingItemCard(LostFoundItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item image
                if (item.photoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(item.photoUrl!),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.image, color: Colors.grey[400], size: 32),
                  ),
                const SizedBox(width: 16),
                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.isLost ? Colors.red[100] : Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.isLost ? 'LOST' : 'FOUND',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: item.isLost ? Colors.red[800] : Colors.green[800],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.category,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location: ${item.location}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: AdminService.getReporterInfo(item.reporterId),
                        builder: (context, snapshot) {
                          final reporterData = snapshot.data;
                          final reporterName = reporterData?['name'] ?? 'Unknown User';
                          return Text(
                            'Reported by: $reporterName',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveItem(item),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectItem(item),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllItemCard(LostFoundItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        leading: item.photoUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(item.photoUrl!),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image, color: Colors.grey[400]),
              ),
        title: Text(
          item.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.isLost ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.isLost ? 'LOST' : 'FOUND',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: item.isLost ? Colors.red[800] : Colors.green[800],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.isApproved ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.isApproved ? 'APPROVED' : 'PENDING',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: item.isApproved ? Colors.green[800] : Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: FutureBuilder<Map<String, dynamic>?>(
          future: AdminService.getReporterInfo(item.reporterId),
          builder: (context, snapshot) {
            final reporterData = snapshot.data;
            final reporterName = reporterData?['name'] ?? 'Unknown';
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.isApproved ? Icons.verified : Icons.hourglass_empty,
                  color: item.isApproved ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 2),
                Text(
                  reporterName,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _approveItem(LostFoundItem item) async {
    try {
      if (item.id != null) {
        await AdminService.approveItem(item.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.title} approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectItem(LostFoundItem item) async {
    final bool? shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Item', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to reject "${item.title}"? This will permanently delete the item.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reject', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldReject == true && item.id != null) {
      try {
        await AdminService.rejectItem(item.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.title} rejected and deleted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
} 