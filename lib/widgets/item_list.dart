import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../models/lost_found_item.dart';
import '../screens/item_details_screen.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';

class ItemList extends StatelessWidget {
  final List<LostFoundItem> items;

  const ItemList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Try adjusting your search or filters',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final item = items[index];
        final currentUserId = AuthService.currentUser?.uid;
        final isOwner = item.reporterId == currentUserId;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(),
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
                    if (isOwner) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'YOUR POST',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Reporter information
                FutureBuilder<Map<String, dynamic>?>(
                  future: AdminService.getReporterInfo(item.reporterId),
                  builder: (context, snapshot) {
                    final reporterData = snapshot.data;
                    final reporterName = reporterData?['name'] ?? 'Loading...';
                    return Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Reported by: $reporterName',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  item.isLost ? const Icon(Icons.search_off, color: Colors.red) : const Icon(Icons.search, color: Colors.green),
                  const SizedBox(height: 4),
                  Icon(item.isApproved ? Icons.verified : Icons.hourglass_empty, color: item.isApproved ? Colors.green : Colors.orange, size: 18),
                ],
              ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailsScreen(item: item),
                ),
              );
            },
          ),
        );
      },
    );
  }


} 