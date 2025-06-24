import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pashu_seva/Services/CloudinaryService.dart';
import 'package:pashu_seva/Services/LocationService.dart';
import 'package:pashu_seva/Services/RequestService.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  File? _imageFile;
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _submitRequest() async {
    if (_imageFile == null || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take photo and enter description')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("It might take few minutes to submit request..."),
          ],
        ),
      ),
    );

    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();

      final cloudinaryService = CloudinaryService();
      final imageUrl = await cloudinaryService.uploadImage(_imageFile!);

      final requestService = RequestService();
      await requestService.createRequest(
        imageUrl,
        position.latitude,
        position.longitude,
        description: _descriptionController.text.trim(),
      );

      await requestService.sendPushNotificationToVolunteers(
        "New Animal Help Request",
        "A new animal needs help near you!",
      );

      Navigator.pop(context); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully')),
      );

      Navigator.pop(context); // Go back to previous screen
    } catch (e) {
      Navigator.pop(context); // Close the dialog
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit request')),
      );
    }
  }

  bool _canSubmit() {
    return _imageFile != null && _descriptionController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Help Request')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: _imageFile != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                      )
                          : Icon(Icons.pets, size: 80, color: Colors.green.shade300),
                    ),
                    if (_imageFile != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: _removeImage,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.green,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Describe the situation:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 7,
                onChanged: (_) { setState(() {}); },
                decoration: InputDecoration(
                  hintText: "Eg. Injured cow near temple, unable to stand",
                  filled: true,
                  fillColor: Colors.green.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _canSubmit() ? _submitRequest : null,
                child: const Text('Submit Request', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
