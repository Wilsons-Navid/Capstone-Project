import 'package:flutter/material.dart';

class EducationDetailPage extends StatelessWidget {
  final String contentId;
  
  const EducationDetailPage({super.key, required this.contentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Education Content'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Text('Education Detail Page - ID: $contentId'),
      ),
    );
  }
}