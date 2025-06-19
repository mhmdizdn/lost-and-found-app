import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../models/lost_found_item.dart';
import '../screens/item_details_screen.dart';

class ItemList extends StatelessWidget {
  final List<LostFoundItem> items;
  const ItemList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items yet.'));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: item.photoUrl != null 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(item.photoUrl!), 
                      width: 48, 
                      height: 48, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                    ),
                  )
                : const Icon(Icons.image_not_supported),
            title: Text(item.title, style: GoogleFonts.poppins()),
            subtitle: Text('${item.category} • ${item.location}\n${item.date.toLocal().toString().split(' ')[0]}', style: GoogleFonts.poppins()),
            isThreeLine: true,
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