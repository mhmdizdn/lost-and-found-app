import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lost_found_item.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
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
    _tabController = TabController(length: 4, vsync: this); // Changed to 4 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Filter logic for public items (excluding user's own posts)
  List<LostFoundItem> _filterPublicItems(List<LostFoundItem> items) {
    final currentUser = AuthService.currentUser;
    final currentUserId = currentUser?.uid;
    
    return items.where((item) {
      // Exclude user's own posts from public view
      if (currentUserId != null && item.reporterId == currentUserId) {
        return false;
      }
      
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

  // Filter logic for user's own posts
  List<LostFoundItem> _filterUserItems(List<LostFoundItem> items) {
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

  // Filter logic for active user posts (not completed)
  List<LostFoundItem> _filterActiveUserItems(List<LostFoundItem> items) {
    return items.where((item) {
      // Only show items that are not completed
      if (item.isFound || item.isReturned) {
        return false;
      }
      
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

  // Filter logic for completed user posts
  List<LostFoundItem> _filterCompletedUserItems(List<LostFoundItem> items) {
    return items.where((item) {
      // Only show items that are completed
      if (!item.isFound && !item.isReturned) {
        return false;
      }
      
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
              Tab(
                icon: Icon(Icons.search_off),
                text: 'Lost Items',
              ),
              Tab(
                icon: Icon(Icons.search),
                text: 'Found Items',
              ),
              Tab(
                icon: Icon(Icons.person),
                text: 'My Posts',
              ),
              Tab(
                icon: Icon(Icons.check_circle),
                text: 'Completed',
              ),
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
              _buildLostItemsTab(),
              _buildFoundItemsTab(),
              _buildMyPostsTab(),
              _buildCompletedTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLostItemsTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search lost items...',
              hintStyle: GoogleFonts.poppins(),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        // Lost items list (excluding user's own posts)
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
              // Filter to show only lost items and exclude user's own posts
              final lostItems = items.where((item) => item.isLost).toList();
              final filteredItems = _filterPublicItems(lostItems);
              
              if (filteredItems.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No lost items found',
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
              
              return ItemList(items: filteredItems);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFoundItemsTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search found items...',
              hintStyle: GoogleFonts.poppins(),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        // Found items list (excluding user's own posts and returned items)
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
              // Filter to show only found items that haven't been returned and exclude user's own posts
              final foundItems = items.where((item) => !item.isLost && !item.isReturned).toList();
              final filteredItems = _filterPublicItems(foundItems);
              
              if (filteredItems.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No found items available',
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
        final filteredItems = _filterActiveUserItems(items); // Only show active items

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

        if (filteredItems.isEmpty && (_searchQuery.isNotEmpty || _filterCategory != null || _filterDate != null)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No active posts match your filters',
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

        if (filteredItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
                const SizedBox(height: 16),
                Text(
                  'All your posts are completed!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Check the "Completed" tab to see your resolved items',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                  ),
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
                      'Your active posts (approved & pending). You can edit, delete, or mark as completed.',
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
              child: MyPostsList(items: filteredItems),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompletedTab() {
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
        final filteredItems = _filterCompletedUserItems(items); // Only show completed items

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
                  'Completed items will appear here',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        if (filteredItems.isEmpty && (_searchQuery.isNotEmpty || _filterCategory != null || _filterDate != null)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No completed posts match your filters',
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

        if (filteredItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: 64, color: Colors.orange[400]),
                const SizedBox(height: 16),
                Text(
                  'No completed items yet',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Items will appear here once you mark them as found or returned',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                  ),
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
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your completed items. These are items you\'ve marked as found or returned to their owners.',
                      style: GoogleFonts.poppins(
                        color: Colors.green[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MyPostsList(items: filteredItems),
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