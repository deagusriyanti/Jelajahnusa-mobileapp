import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jelajah_nusa/screens/pick_location_screen.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:jelajah_nusa/main.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _image;
  String? _base64Image;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  double? _latitude;
  double? _longitude;
  String currentDate = "";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentDate = "${now.day}/${now.month}/${now.year}";
  }

  String getProvinceCategory(String province) {
    switch (province.toLowerCase()) {
      case 'aceh':
        return 'Aceh';
      case 'sumatera utara':
        return 'Sumatera Utara';
      case 'sumatera barat':
        return 'Sumatera Barat';
      case 'riau':
        return 'Riau';
      case 'kepulauan riau':
        return 'Kepulauan Riau';
      case 'jambi':
        return 'Jambi';
      case 'sumatera selatan':
        return 'Sumatera Selatan';
      case 'bengkulu':
        return 'Bengkulu';
      case 'bangka belitung':
      case 'kepulauan bangka belitung':
        return 'Bangka Belitung';
      case 'lampung':
        return 'Lampung';
      case 'dki jakarta':
      case 'jakarta':
        return 'DKI Jakarta';
      case 'banten':
        return 'Banten';
      case 'jawa barat':
        return 'Jawa Barat';
      case 'jawa tengah':
        return 'Jawa Tengah';
      case 'daerah istimewa yogyakarta':
      case 'yogyakarta':
        return 'DI Yogyakarta';
      case 'jawa timur':
        return 'Jawa Timur';
      case 'kalimantan barat':
        return 'Kalimantan Barat';
      case 'kalimantan tengah':
        return 'Kalimantan Tengah';
      case 'kalimantan selatan':
        return 'Kalimantan Selatan';
      case 'kalimantan timur':
        return 'Kalimantan Timur';
      case 'kalimantan utara':
        return 'Kalimantan Utara';
      case 'sulawesi utara':
        return 'Sulawesi Utara';
      case 'gorontalo':
        return 'Gorontalo';
      case 'sulawesi tengah':
        return 'Sulawesi Tengah';
      case 'sulawesi barat':
        return 'Sulawesi Barat';
      case 'sulawesi selatan':
        return 'Sulawesi Selatan';
      case 'sulawesi tenggara':
        return 'Sulawesi Tenggara';
      case 'bali':
        return 'Bali';
      case 'nusa tenggara barat':
        return 'Nusa Tenggara Barat';
      case 'nusa tenggara timur':
        return 'Nusa Tenggara Timur';
      case 'maluku':
        return 'Maluku';
      case 'maluku utara':
        return 'Maluku Utara';
      case 'papua':
        return 'Papua';
      case 'papua selatan':
        return 'Papua Selatan';
      case 'papua tengah':
        return 'Papua Tengah';
      case 'papua pegunungan':
        return 'Papua Pegunungan';
      case 'papua barat':
        return 'Papua Barat';
      case 'papua barat daya':
        return 'Papua Barat Daya';
      default:
        return province.isEmpty ? 'Lainnya' : province;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        await _compressAndEncodeImage();
      }
    } catch (e) {
      _showMessage('Failed to pick image: $e');
    }
  }

  Future<void> _compressAndEncodeImage() async {
    if (_image == null) return;
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        _image!.path,
        quality: 50,
      );
      if (compressedImage == null) return;
      setState(() {
        _base64Image = base64Encode(compressedImage);
      });
    } catch (e) {
      _showMessage('Failed to compress image: $e');
    }
  }

  Future<void> _submitPost() async {
    if (_base64Image == null ||
        _titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      _showMessage('Please complete all fields.');
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showMessage('Silakan pilih lokasi terlebih dahulu');
      return;
    }
    setState(() => _isUploading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isUploading = false);
      _showMessage('User not found.');
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      final username =
          userData?['username'] ?? user.displayName ?? 'Unknown User';
      final userPhotoBase64 = userData?['photoBase64'];
      final userPhotoUrl = userData?['photoUrl'] ?? user.photoURL;
      String category = "Lainnya";
      final placemarks = await placemarkFromCoordinates(
        _latitude!,
        _longitude!,
      );

      if (placemarks.isNotEmpty) {
        category = getProvinceCategory(
          placemarks.first.administrativeArea ?? '',
        );
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'uid': user.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fullName': username,
        'userPhotoBase64': userPhotoBase64,
        'userPhotoUrl': userPhotoUrl,
        'category': category,
        'date': currentDate,
        'image': _base64Image,
        'latitude': _latitude,
        'longitude': _longitude,
        'likes': 0,
        'likedBy': [],
        'createdAt': Timestamp.now(),
      });

      await showBasicNotification(
        'Jelajah Nusa',
        'Postingan wisata berhasil ditambahkan.',
      );
      if (!mounted) return;
      Navigator.pop(context);
      _showMessage('Post uploaded successfully!');
    } catch (e) {
      debugPrint(e.toString());
      _showMessage('Failed to upload post: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.teal),
                title: Text(
                  'Take a picture',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
                title: Text(
                  'Choose from gallery',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        inputFormatters: maxLength != null
            ? [LengthLimitingTextInputFormatter(maxLength)]
            : null,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.teal),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  GestureDetector(
                    onTap: () async {
                      final LatLng? pickedLocation = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PickLocationScreen(),
                        ),
                      );

                      if (pickedLocation != null) {
                        setState(() {
                          _latitude = pickedLocation.latitude;
                          _longitude = pickedLocation.longitude;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(
                            "Add",
                            style: TextStyle(
                              fontSize: 22,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 35,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 280,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          fontSize: 20,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(
                                    _image!,
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 45,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                hint: 'Caption',
                controller: _titleController,
                maxLength: 30,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                hint: 'Description',
                controller: _descriptionController,
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.teal),
                    const SizedBox(width: 12),
                    Text(
                      currentDate,
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
              SizedBox(
                height: 70,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF79B7B5),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Post',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
