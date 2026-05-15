import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/config/app_config.dart';
import '../../sync/models/upload_task.dart';
import '../../sync/services/sync_manager.dart';
import 'screen_1_registration.dart';

class SubmissionScreen extends ConsumerStatefulWidget {
  final String cattleId;
  final String collectorId;
  final String? breed;
  final String? sex;
  final List<Map<String, dynamic>> shots;

  const SubmissionScreen({
    super.key,
    required this.cattleId,
    required this.collectorId,
    this.breed,
    this.sex,
    required this.shots,
  });

  @override
  ConsumerState<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends ConsumerState<SubmissionScreen> {
  bool _isQueueing = true;
  String _statusMessage = 'Preparing...';

  @override
  void initState() {
    super.initState();
    _queueSubmission();
  }

  Future<void> _queueSubmission() async {
    try {
      // Get GPS
      setState(() => _statusMessage = 'Getting GPS...');
      double lat = 0.0;
      double lng = 0.0;
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
        lat = pos.latitude;
        lng = pos.longitude;
      }

      setState(() => _statusMessage = 'Saving locally...');
      
      final task = MuzzleUploadTask(
        id: widget.cattleId,
        mode: AppConfig.currentMode,
        collectorOrFarmerId: widget.collectorId,
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        breed: widget.breed,
        sex: widget.sex,
        shotsJson: jsonEncode(widget.shots),
      );

      final syncManager = ref.read(syncManagerProvider);
      await syncManager.addToQueue(task);

      if (!mounted) return;
      setState(() {
        _isQueueing = false;
        _statusMessage = 'Queued for upload ✓';
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Error: $e';
        _isQueueing = false;
      });
    }
  }

  void _resetApp() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission'),
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false, // No back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isQueueing) const CircularProgressIndicator()
              else const Icon(Icons.check_circle, color: Colors.green, size: 80),
              
              const SizedBox(height: 24),
              
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
              
              Text(
                'Cattle ID: ${widget.cattleId}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 48),

              if (!_isQueueing)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  onPressed: _resetApp,
                  child: const Text('New Registration', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
