import 'package:flutter/material.dart';

class FullImageView extends StatelessWidget {
  final String imageUrl;

  const FullImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image View"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.image_not_supported_rounded,
                color: Colors.grey,
                size: 100,
              );
            },
          ),
        ),
      ),
    );
  }
}
