import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(const LostAndFoundApp());
}

class LostAndFoundApp extends StatelessWidget {
  const LostAndFoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lost and Found',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Lost & Found', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: Text('Login', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: Text('Register', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login', style: GoogleFonts.poppins())),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Login Form (mock)', style: GoogleFonts.poppins()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              child: Text('Login', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
              child: Text('No account? Register', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register', style: GoogleFonts.poppins())),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Register Form (mock)', style: GoogleFonts.poppins()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              child: Text('Register', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: Text('Already have an account? Login', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}

// Item model
class LostFoundItem {
  final String title;
  final String description;
  final String category;
  final String location;
  final File? photo;
  final DateTime date;
  final bool isLost;
  bool isApproved;
  final LatLng? coordinates;

  LostFoundItem({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.photo,
    required this.date,
    required this.isLost,
    this.isApproved = false,
    this.coordinates,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<LostFoundItem> _items = [];

  String _searchQuery = '';
  String? _filterCategory;
  DateTime? _filterDate;

  void _addItem(LostFoundItem item) {
    setState(() {
      _items.add(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item posted! Pending admin approval.', style: GoogleFonts.poppins())),
    );
  }

  List<LostFoundItem> _filterItems(List<LostFoundItem> items) {
    return items.where((item) {
      final matchesQuery = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _filterCategory == null || item.category == _filterCategory;
      final matchesDate = _filterDate == null ||
          (item.date.year == _filterDate!.year && item.date.month == _filterDate!.month && item.date.day == _filterDate!.day);
      return matchesQuery && matchesCategory && matchesDate;
    }).toList();
  }

  List<LostFoundItem> get _allItems => _filterItems(_items);
  List<LostFoundItem> get _lostItems => _filterItems(_items.where((item) => item.isLost).toList());
  List<LostFoundItem> get _foundItems => _filterItems(_items.where((item) => !item.isLost).toList());

  List<Widget> get _widgetOptions => [
    ItemList(items: _allItems),
    ItemList(items: _lostItems),
    ItemList(items: _foundItems),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openPostItemForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostItemForm(),
      ),
    );
    if (result is LostFoundItem) {
      _addItem(result);
    }
  }

  void _openFilterDialog() async {
    final categories = ['Phone', 'Keys', 'Wallet', 'Pet', 'Bag', 'Other'];
    String? selectedCategory = _filterCategory;
    DateTime? selectedDate = _filterDate;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: [null, ...categories].map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat ?? 'All Categories'),
                )).toList(),
                onChanged: (value) => selectedCategory = value,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(selectedDate != null ? selectedDate!.toLocal().toString().split(' ')[0] : 'Any'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                selectedCategory = null;
                selectedDate = null;
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _filterCategory = selectedCategory;
                  _filterDate = selectedDate;
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by keyword...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.all(8),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All'),
          BottomNavigationBarItem(icon: Icon(Icons.search_off), label: 'Lost'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Found'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openPostItemForm,
        child: const Icon(Icons.add),
        tooltip: 'Post Item',
      ),
    );
  }
}

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
            leading: item.photo != null ? Image.file(item.photo!, width: 48, height: 48, fit: BoxFit.cover) : const Icon(Icons.image_not_supported),
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

class ItemDetailsScreen extends StatelessWidget {
  final LostFoundItem item;
  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title, style: GoogleFonts.poppins())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (item.photo != null)
              Image.file(item.photo!, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  label: Text(item.isLost ? 'Lost' : 'Found', style: GoogleFonts.poppins(color: item.isLost ? Colors.red : Colors.green)),
                  backgroundColor: item.isLost ? Colors.red[100] : Colors.green[100],
                ),
                const SizedBox(width: 12),
                Chip(label: Text(item.category, style: GoogleFonts.poppins())),
                const SizedBox(width: 12),
                Icon(item.isApproved ? Icons.verified : Icons.hourglass_empty, color: item.isApproved ? Colors.green : Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text(item.isApproved ? 'Approved' : 'Pending', style: GoogleFonts.poppins(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Description', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(item.description, style: GoogleFonts.poppins()),
            const SizedBox(height: 12),
            Text('Location: ${item.location}', style: GoogleFonts.poppins()),
            Text('Date: ${item.date.toLocal().toString().split(' ')[0]}', style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Map View', style: GoogleFonts.poppins()),
                    content: item.coordinates != null
                      ? SizedBox(
                          width: 400,
                          height: 200,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: item.coordinates!,
                              zoom: 16,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('item_location'),
                                position: item.coordinates!,
                              ),
                            },
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            liteModeEnabled: true,
                          ),
                        )
                      : Image.network(
                          'https://maps.googleapis.com/maps/api/staticmap?center=3.139,101.6869&zoom=15&size=400x200&key=AIzaSyC_YZZYJ5urvYDmr8Kbtgq7JG11S5eOnBI',
                          fit: BoxFit.cover,
                        ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: Text('Show Map', style: GoogleFonts.poppins()),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(item: item),
                  ),
                );
              },
              icon: const Icon(Icons.message),
              label: const Text('Contact Poster (mock)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Report Item', style: GoogleFonts.poppins()),
                    content: Text('Are you sure you want to report this item as inappropriate or fake?', style: GoogleFonts.poppins()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: GoogleFonts.poppins()),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Item reported. Admin will review.', style: GoogleFonts.poppins())),
                          );
                        },
                        child: Text('Report', style: GoogleFonts.poppins(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.report),
              label: const Text('Report Item'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final LostFoundItem item;
  const ChatScreen({super.key, required this.item});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<String> _messages = [
    'Hi, I am interested in this item.',
    'Is it still available?',
  ];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(text);
        _controller.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message sent', style: GoogleFonts.poppins())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat', style: GoogleFonts.poppins())),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isMe = index % 2 == 1;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.deepPurple[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_messages[index], style: GoogleFonts.poppins()),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.poppins(),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostItemForm extends StatefulWidget {
  const PostItemForm({super.key});

  @override
  State<PostItemForm> createState() => _PostItemFormState();
}

class _PostItemFormState extends State<PostItemForm> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _category = 'Phone';
  String _location = '';
  File? _photo;
  DateTime _date = DateTime.now();
  bool _isLost = true;
  LatLng? _coordinates;
  String? _address;

  final List<String> _categories = ['Phone', 'Keys', 'Wallet', 'Pet', 'Bag', 'Other'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photo = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateAddress() async {
    if (_coordinates != null) {
      final placemarks = await placemarkFromCoordinates(_coordinates!.latitude, _coordinates!.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = [
            place.street,
            place.locality,
            place.administrativeArea,
            place.country
          ].where((e) => e != null && (e as String).isNotEmpty).join(', ');
        });
      }
    } else {
      setState(() {
        _address = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post Lost/Found Item', style: GoogleFonts.poppins())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Lost'),
                    selected: _isLost,
                    onSelected: (selected) {
                      setState(() {
                        _isLost = true;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Found'),
                    selected: !_isLost,
                    onSelected: (selected) {
                      setState(() {
                        _isLost = false;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.isEmpty ? 'Enter a title' : null,
                onSaved: (value) => _title = value ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Enter a description' : null,
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (value) => setState(() => _category = value ?? 'Phone'),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo),
                    label: const Text('Add Photo'),
                  ),
                  const SizedBox(width: 12),
                  _photo != null ? Image.file(_photo!, width: 48, height: 48, fit: BoxFit.cover) : const SizedBox(),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(_date.toLocal().toString().split(' ')[0]),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _date = picked;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapPickerScreen(initialPosition: _coordinates),
                        ),
                      );
                      if (picked is LatLng) {
                        setState(() {
                          _coordinates = picked;
                        });
                        await _updateAddress();
                      }
                    },
                    icon: const Icon(Icons.map),
                    label: Text('Pin Location', style: GoogleFonts.poppins()),
                  ),
                  const SizedBox(width: 12),
                  _coordinates != null
                      ? Text('Pinned: (${_coordinates!.latitude.toStringAsFixed(4)}, ${_coordinates!.longitude.toStringAsFixed(4)})', style: GoogleFonts.poppins(fontSize: 12))
                      : Text('No location pinned', style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
              if (_address != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, bottom: 8),
                  child: Text('Address: $_address', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    final item = LostFoundItem(
                      title: _title,
                      description: _description,
                      category: _category,
                      photo: _photo,
                      date: _date,
                      isLost: _isLost,
                      coordinates: _coordinates,
                      location: _address ?? '',
                      );
                    Navigator.pop(context, item);
                  }
                },
                child: Text('Submit', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  const MapPickerScreen({super.key, this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _pickedPosition;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _pickedPosition = widget.initialPosition ?? const LatLng(3.139, 101.6869); // Default: Kuala Lumpur
  }

  Future<void> _locateMe() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);
    setState(() {
      _pickedPosition = latLng;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pick Location', style: GoogleFonts.poppins())),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _pickedPosition!,
          zoom: 15,
        ),
        onMapCreated: (controller) => _mapController = controller,
        onTap: (pos) {
          setState(() {
            _pickedPosition = pos;
          });
        },
        markers: {
          Marker(
            markerId: const MarkerId('picked'),
            position: _pickedPosition!,
          ),
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _locateMe,
            label: const Text('Locate Me'),
            icon: const Icon(Icons.my_location),
            heroTag: 'locateMe',
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: () => Navigator.pop(context, _pickedPosition),
            label: const Text('Select'),
            icon: const Icon(Icons.check),
            heroTag: 'select',
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile', style: GoogleFonts.poppins())),
      body: Center(child: Text('User Profile (mock)', style: GoogleFonts.poppins())),
    );
  }
}
