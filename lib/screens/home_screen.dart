import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lost_found_item.dart';
import '../services/firebase_service.dart';
import '../widgets/item_list.dart';
import '../widgets/my_posts_list.dart';
import 'post_item_form.dart';
import 'profile_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String _searchQuery = '';
  String? _filterCategory;
  DateTime? _filterDate;
  GoogleMapController? _mapController;
  late TabController _tabController;

  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Books',
    'Sports Equipment',
    'Jewelry',
    'Documents',
    'Keys',
    'Bags',
    'Other',
  ];

  final List<String> _filterOptions = [
    'All',
    'Lost',
    'Found',
    'Electronics',
    'Clothing',
    'Books',
    'Sports Equipment',
    'Jewelry',
    'Documents',
    'Keys',
    'Bags',
    'Other',
  ];

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

  // Filter logic
  List<LostFoundItem> _filterItems(List<LostFoundItem> items) {
    return items.where((item) {
      // Search query filter
      if (_searchQuery.isNotEmpty &&
          !item.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !item.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // Category filter
      if (_filterCategory != null && item.category != _filterCategory) {
        return false;
      }

      // Date filter
      if (_filterDate != null &&
          !_isSameDay(item.date, _filterDate!)) {
        return false;
      }

      return true;
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? tempFilterCategory = _filterCategory;
        DateTime? tempFilterDate = _filterDate;

        return AlertDialog(
          title: Text('Filter Items', style: GoogleFonts.poppins()),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Filter
                  DropdownButtonFormField<String>(
                    value: tempFilterCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ..._categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        tempFilterCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Date Filter
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tempFilterDate == null
                              ? 'No date filter'
                              : 'Date: ${tempFilterDate!.toLocal().toString().split(' ')[0]}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: tempFilterDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setState(() {
                              tempFilterDate = picked;
                            });
                          }
                        },
                        child: const Text('Pick Date'),
                      ),
                      if (tempFilterDate != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              tempFilterDate = null;
                            });
                          },
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _filterCategory = tempFilterCategory;
                  _filterDate = tempFilterDate;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    // Prevent back button from logging out
    // Instead, show a dialog asking if user wants to exit the app
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit App', style: GoogleFonts.poppins()),
        content: Text('Do you want to exit the Lost & Found app?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Exit', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
    
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Lost & Found', style: GoogleFonts.poppins()),
          backgroundColor: Colors.deepPurple[100],
          automaticallyImplyLeading: false, // Remove back button from app bar
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _openFilterDialog,
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
        body: _selectedIndex == 0 ? _buildHomeTab() : _buildProfileTab(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
        floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostItemForm()),
          ),
          child: const Icon(Icons.add),
        ) : null,
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All Items'),
              Tab(text: 'My Posts'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllItemsTab(),
              _buildMyPostsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllItemsTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search items...',
              hintStyle: GoogleFonts.poppins(),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        // Items list
        Expanded(
          child: StreamBuilder<List<LostFoundItem>>(
            stream: FirebaseService.getItemsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final items = snapshot.data ?? [];
              final filteredItems = _filterItems(items);
              return ItemList(items: filteredItems);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyPostsTab() {
    return StreamBuilder<List<LostFoundItem>>(
      stream: FirebaseService.getUserItemsStream(),
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
                Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Your reported items will appear here',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PostItemForm()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Report Item'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All your posts (approved & pending). You can edit or delete any of your items here.',
                      style: GoogleFonts.poppins(
                        color: Colors.blue[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MyPostsList(items: items),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return const ProfileScreen();
  }
} 