import 'package:flutter/material.dart';

class IncidentDetailsPage extends StatelessWidget {
  final String incidentId;
  
  const IncidentDetailsPage({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Text('Incident Details Page - ID: $incidentId'),
      ),
    );
  }
}