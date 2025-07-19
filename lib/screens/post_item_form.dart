import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import '../models/lost_found_item.dart';
import '../services/firebase_service.dart';
import 'map_picker_screen.dart';

class PostItemForm extends StatefulWidget {
  final bool isEditing;
  final LostFoundItem? existingItem;
  final bool isAdmin; // <-- add this

  const PostItemForm({
    super.key,
    this.isEditing = false,
    this.existingItem,
    this.isAdmin = false, // <-- default to false
  });

  @override
  State<PostItemForm> createState() => _PostItemFormState();
}

class _PostItemFormState extends State<PostItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Electronics';
  bool _isLost = true;
  File? _selectedImage;
  String? _selectedImageBase64;
  LatLng? _selectedLocation;
  String _locationText = 'No location selected';
  bool _isApproved = false; // <-- add this

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingItem != null) {
      _initializeWithExistingData();
    }
  }

  void _initializeWithExistingData() {
    final item = widget.existingItem!;
    _titleController.text = item.title;
    _descriptionController.text = item.description;
    _selectedCategory = item.category;
    _isLost = item.isLost;
    _selectedImageBase64 = item.photoUrl;
    _selectedLocation = item.coordinates;
    _locationText = item.location;
    _isApproved = item.isApproved; // <-- add this
  }

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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      
      // Check file size (limit to 800KB to stay within Firestore's 1MB limit)
      if (bytes.length > 800 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image is too large. Please select a smaller image (max 800KB).'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedImage = File(image.path);
        _selectedImageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _locationText = '${place.street}, ${place.locality}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );
    
    if (result != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(result.latitude, result.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _selectedLocation = result;
            _locationText = '${place.street}, ${place.locality}';
          });
        }
      } catch (e) {
        setState(() {
          _selectedLocation = result;
          _locationText = 'Location: ${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location')),
        );
        return;
      }

      final item = LostFoundItem(
        id: widget.isEditing ? widget.existingItem!.id : null,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        location: _locationText,
        photoUrl: _selectedImageBase64,  // Use Base64 string directly
        date: widget.isEditing ? widget.existingItem!.date : DateTime.now(),
        isLost: _isLost,
        coordinates: _selectedLocation,
        reporterId: widget.isEditing ? widget.existingItem!.reporterId : '', // Will be set by FirebaseService for new items
        isApproved: widget.isAdmin ? _isApproved : (widget.isEditing ? widget.existingItem!.isApproved : false),
      );

      try {
        if (widget.isEditing) {
          await FirebaseService.updateItem(widget.existingItem!.id!, item);
          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate successful edit
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item updated successfully!')),
            );
          }
        } else {
          await FirebaseService.addItem(item);
          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate successful add
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item posted successfully!')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error ${widget.isEditing ? 'updating' : 'posting'} item: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Item' : 'Post Item', 
          style: GoogleFonts.poppins()
        ),
        backgroundColor: Colors.deepPurple[100],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Lost/Found toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text('Type:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: Text('Lost', style: GoogleFonts.poppins()),
                        selected: _isLost,
                        onSelected: (selected) => setState(() => _isLost = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('Found', style: GoogleFonts.poppins()),
                        selected: !_isLost,
                        onSelected: (selected) => setState(() => _isLost = false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category, style: GoogleFonts.poppins()));
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),
              
              // Photo section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_selectedImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImage!, height: 200, fit: BoxFit.cover),
                        )
                      else if (_selectedImageBase64 != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(_selectedImageBase64!), 
                            height: 200, 
                            fit: BoxFit.cover
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image, size: 64, color: Colors.grey),
                        ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: Text('Select Photo', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Location section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Location', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_locationText, style: GoogleFonts.poppins()),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              label: Text('Current Location', style: GoogleFonts.poppins()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openMapPicker,
                              icon: const Icon(Icons.map),
                              label: Text('Pin Location', style: GoogleFonts.poppins()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.isAdmin) ...[
                Row(
                  children: [
                    Text('Approval Status:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Switch(
                      value: _isApproved,
                      onChanged: (val) => setState(() => _isApproved = val),
                      activeColor: Colors.green,
                    ),
                    Text(_isApproved ? 'Approved' : 'Pending', style: GoogleFonts.poppins()),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.isEditing ? 'Update Item' : 'Post Item', 
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 