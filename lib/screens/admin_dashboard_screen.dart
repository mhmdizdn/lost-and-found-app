import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../services/admin_service.dart';
import '../models/lost_found_item.dart';
import 'post_item_form.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red[100],
      ),
      body: StreamBuilder<List<LostFoundItem>>(
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
              child: Text(
                'No items found',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildDashboardItemCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildDashboardItemCard(LostFoundItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
        title: Text(item.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        subtitle: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.visibility, color: Colors.blue),
              onPressed: () => _showItemDetails(item),
              tooltip: 'View',
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _editItem(item),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteItem(item),
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () => _showItemDetails(item),
      ),
    );
  }

  void _showItemDetails(LostFoundItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Item Details', style: GoogleFonts.poppins()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Title: ${item.title}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Description: ${item.description}', style: GoogleFonts.poppins()),
              const SizedBox(height: 8),
              Text('Category: ${item.category}', style: GoogleFonts.poppins()),
              const SizedBox(height: 8),
              Text('Location: ${item.location}', style: GoogleFonts.poppins()),
              const SizedBox(height: 8),
              Text('Status: ${item.isLost ? "LOST" : "FOUND"}', style: GoogleFonts.poppins()),
              const SizedBox(height: 8),
              Text('Approved: ${item.isApproved ? "Yes" : "No"}', style: GoogleFonts.poppins()),
              if (item.isLost) ...[
                const SizedBox(height: 8),
                Text('Found: ${item.isFound ? "Yes" : "No"}', style: GoogleFonts.poppins()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _editItem(LostFoundItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostItemForm(
          isEditing: true,
          existingItem: item,
          isAdmin: true,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item updated successfully', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteItem(LostFoundItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to delete "${item.title}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed == true && item.id != null) {
      try {
        await AdminService.adminDeleteItem(item.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.title} deleted successfully', style: GoogleFonts.poppins()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting item: $e', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
