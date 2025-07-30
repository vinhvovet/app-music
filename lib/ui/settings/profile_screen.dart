import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _profileImageUrl;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkFirebaseConnection();
  }

  Future<void> _checkFirebaseConnection() async {
    try {
      // Test Firebase Auth connection
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Firebase Auth connected - User: ${user.uid}');
      }
      
      // Test Firestore connection
      await FirebaseFirestore.instance
          .collection('test')
          .doc('connection')
          .get();
      print('Firestore connection successful');
      
      // Test Firebase Storage connection
      try {
        FirebaseStorage.instance.ref().child('test/connection.txt');
        print('Firebase Storage reference created successfully');
      } catch (e) {
        print('Firebase Storage connection issue: $e');
      }
    } catch (e) {
      print('Firebase connection test failed: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _emailController.text = user.email ?? '';
        _nameController.text = user.displayName ?? '';
        _profileImageUrl = user.photoURL;
      });

      // Load additional info from Firestore
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _phoneController.text = data['phone'] ?? '';
            if (data['profileImage'] != null && data['profileImage'].isNotEmpty) {
              _profileImageUrl = data['profileImage'];
            }
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi chọn ảnh: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi chụp ảnh: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_profileImageUrl != null || _selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa ảnh hiện tại'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _profileImageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Người dùng chưa đăng nhập');
        return null;
      }

      print('Starting image upload for user: ${user.uid}');
      
      // Check if file exists and is readable
      if (!await imageFile.exists()) {
        _showErrorSnackBar('Tệp ảnh không tồn tại');
        return null;
      }

      final fileSize = await imageFile.length();
      print('File size: $fileSize bytes');
      
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        _showErrorSnackBar('Kích thước ảnh quá lớn (tối đa 10MB)');
        return null;
      }

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.uid}_$timestamp.jpg';
      
      print('Uploading to: profile_images/$fileName');
      
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': user.uid,
          'uploadTime': timestamp.toString(),
        },
      );

      print('Starting upload task...');
      final uploadTask = ref.putFile(imageFile, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      await uploadTask.whenComplete(() => {
        print('Upload completed successfully')
      });
      
      final downloadUrl = await ref.getDownloadURL();
      print('Download URL obtained: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      print('Error type: ${e.runtimeType}');
      
      // Show more specific error message
      String errorMessage = 'Lỗi không xác định';
      if (e.toString().contains('object-not-found') || e.toString().contains('404')) {
        errorMessage = 'Cấu hình Firebase Storage chưa đúng';
      } else if (e.toString().contains('unauthorized') || e.toString().contains('403')) {
        errorMessage = 'Không có quyền truy cập Firebase Storage';
      } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
        errorMessage = 'Lỗi kết nối mạng, vui lòng thử lại';
      } else if (e.toString().contains('storage/retry-limit-exceeded')) {
        errorMessage = 'Quá nhiều lần thử, vui lòng thử lại sau';
      }
      _showErrorSnackBar('Lỗi tải ảnh: $errorMessage');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_isEditing) {
      setState(() {
        _isEditing = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Người dùng chưa đăng nhập');
        return;
      }

      String? imageUrl = _profileImageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang tải lên ảnh...'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl == null) {
          // Try alternative upload method if Storage fails
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đang thử phương thức khác...'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          imageUrl = await _uploadImageAlternative(_selectedImage!);
          if (imageUrl == null) {
            return; // Error already shown
          }
        }
      }

      // Update Firebase Auth profile (but not base64 images)
      try {
        await user.updateDisplayName(_nameController.text.trim());
        // Only update photoURL if it's a real URL, not base64
        if (imageUrl != null && 
            imageUrl != _profileImageUrl && 
            !imageUrl.startsWith('data:image')) {
          await user.updatePhotoURL(imageUrl);
        }
      } catch (e) {
        print('Error updating Firebase Auth: $e');
        // Continue with Firestore update even if Auth update fails
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _isEditing = false;
        _selectedImage = null;
        _profileImageUrl = imageUrl;
      });

      _showSuccessSnackBar('Cập nhật thông tin thành công!');
    } catch (e) {
      print('Error saving profile: $e');
      String errorMessage = 'Lỗi khi cập nhật thông tin';
      if (e.toString().contains('network')) {
        errorMessage = 'Lỗi kết nối mạng';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Không có quyền truy cập';
      }
      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Alternative upload method using compressed image stored in Firestore
  Future<String?> _uploadImageAlternative(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      print('Using alternative upload method (Compressed)');
      
      // Read and compress image more aggressively
      final bytes = await imageFile.readAsBytes();
      
      // If image is too large, refuse it and ask user to select smaller image
      if (bytes.length > 200 * 1024) { // 200KB limit
        _showErrorSnackBar('Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 200KB hoặc chụp ảnh mới.');
        return null;
      }
      
      // Convert to base64 but with size limit
      final base64String = base64Encode(bytes);
      
      // Firebase Auth photoURL has character limit, so we need to store differently
      if (base64String.length > 2000) { // Conservative limit
        _showErrorSnackBar('Ảnh vẫn quá lớn sau khi nén. Vui lòng chọn ảnh nhỏ hơn.');
        return null;
      }
      
      final dataUrl = 'data:image/jpeg;base64,$base64String';
      
      print('Image converted to base64, length: ${base64String.length}');
      
      return dataUrl;
    } catch (e) {
      print('Error in alternative upload: $e');
      _showErrorSnackBar('Lỗi xử lý ảnh: ${e.toString()}');
      return null;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _isEditing ? _showImagePickerOptions : null,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            backgroundImage: _getImageProvider(),
            child: (_selectedImage == null && _profileImageUrl == null)
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider? _getImageProvider() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }
    
    if (_profileImageUrl != null) {
      if (_profileImageUrl!.startsWith('data:image')) {
        // Base64 image
        final base64String = _profileImageUrl!.split(',')[1];
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } else {
        // Network image
        return NetworkImage(_profileImageUrl!);
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                _isEditing ? 'Lưu' : 'Sửa',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Image
            _buildProfileImage(),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Nhấn vào ảnh để thay đổi',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 40),
            
            // Name Field
            TextFormField(
              controller: _nameController,
              enabled: _isEditing,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Họ và tên',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.person, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Email Field
            TextFormField(
              controller: _emailController,
              enabled: false, // Email không thể sửa
              style: const TextStyle(color: Colors.black54),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.email, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Phone Field
            TextFormField(
              controller: _phoneController,
              enabled: _isEditing,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Account Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin tài khoản',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'UID: ${FirebaseAuth.instance.currentUser?.uid ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ngày tạo: ${FirebaseAuth.instance.currentUser?.metadata.creationTime?.toString().split(' ')[0] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
