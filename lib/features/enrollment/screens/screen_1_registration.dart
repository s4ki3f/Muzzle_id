import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'screen_2_camera.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final TextEditingController _collectorIdController = TextEditingController(text: '12345');
  String? _selectedBreed;
  String? _selectedSex;

  final List<String> _breeds = ['Deshi', 'Holstein', 'Sahiwal'];
  final List<String> _sexes = ['Bull', 'Cow', 'Calf'];

  Future<void> _startSequence() async {
    if (_collectorIdController.text.isEmpty || _selectedBreed == null || _selectedSex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Generate Cattle ID
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    // Get sequence from a separate Hive box or assume 001 for now
    var prefs = await Hive.openBox('prefs');
    int seq = (prefs.get('seq_$dateStr') ?? 0) + 1;
    await prefs.put('seq_$dateStr', seq);
    
    final seqStr = seq.toString().padLeft(3, '0');
    final cattleId = 'COL_${_collectorIdController.text}_${dateStr}_$seqStr';

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          cattleId: cattleId,
          collectorId: _collectorIdController.text,
          breed: _selectedBreed,
          sex: _selectedSex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _collectorIdController,
              decoration: const InputDecoration(
                labelText: 'Collector ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Breed',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedBreed,
              items: _breeds.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (val) => setState(() => _selectedBreed = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Sex',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedSex,
              items: _sexes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _selectedSex = val),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _startSequence,
              child: const Text('Next', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
