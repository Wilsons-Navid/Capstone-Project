import 'package:flutter/material.dart';

class CaseDetailsPage extends StatelessWidget {
  final String caseId;
  
  const CaseDetailsPage({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Text('Case Details Page - ID: $caseId'),
      ),
    );
  }
}