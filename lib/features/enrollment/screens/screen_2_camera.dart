import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/config/app_config.dart';
import '../../../ml/ml_service.dart';
import 'screen_3_submission.dart';

class CameraScreen extends StatefulWidget {
  final String cattleId;
  final String collectorId;
  final String? breed;
  final String? sex;

  const CameraScreen({
    super.key,
    required this.cattleId,
    required this.collectorId,
    this.breed,
    this.sex,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final MLService _mlService = MLService();
  
  int _currentShotIndex = 0;
  bool _isProcessing = false;
  bool _isTorchOn = false;

  // Quality gates
  bool _gateMuzzle = false;
  bool _gateBlur = false;
  bool _gateBrightness = false;
  
  int _rejectionCount = 0;
  String? _tipMessage;

  final List<Map<String, dynamic>> _completedShots = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    await _controller?.initialize();
    if (!mounted) return;

    _controller?.startImageStream(_processCameraImage);
    setState(() {});
  }

  void _toggleTorch() async {
    if (_controller == null) return;
    _isTorchOn = !_isTorchOn;
    await _controller?.setFlashMode(_isTorchOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final conf = await _mlService.getMuzzleConfidence(image);
      final clear = await _mlService.isImageClear(image);
      final brightness = _mlService.calculateBrightness(image);

      final muzzleOk = conf > AppConfig.yoloConfidenceThreshold;
      final blurOk = clear;
      
      final minB = _isTorchOn ? 30.0 : AppConfig.minBrightness;
      final maxB = _isTorchOn ? double.infinity : AppConfig.maxBrightness;
      final brightnessOk = brightness >= minB && brightness <= maxB;

      if (mounted) {
        setState(() {
          _gateMuzzle = muzzleOk;
          _gateBlur = blurOk;
          _gateBrightness = brightnessOk;
        });
      }
    } finally {
      // Delay slightly to prevent burning CPU
      await Future.delayed(const Duration(milliseconds: 200));
      _isProcessing = false;
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    // Simulate real gates
    final allGreen = _gateMuzzle && _gateBlur && _gateBrightness;
    
    if (!allGreen) {
      _rejectionCount++;
      if (_rejectionCount >= 3) {
        setState(() {
          _tipMessage = 'Keep camera steady and ensure light';
        });
      }
      return;
    }

    _rejectionCount = 0;
    setState(() => _tipMessage = null);

    try {
      final XFile file = await _controller!.takePicture();
      final currentShotType = AppConfig.shotSequence[_currentShotIndex];
      
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${dir.path}/${widget.cattleId}_${currentShotType}_$timestamp.jpg';
      await File(file.path).copy(newPath);

      _completedShots.add({
        'type': currentShotType,
        'filePath': newPath,
        'blurScore': 1.0, // Mock
        'brightness': 100.0, // Mock
      });

      if (_currentShotIndex < AppConfig.shotSequence.length - 1) {
        setState(() {
          _currentShotIndex++;
        });
      } else {
        // All shots done
        _controller?.stopImageStream();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SubmissionScreen(
              cattleId: widget.cattleId,
              collectorId: widget.collectorId,
              breed: widget.breed,
              sex: widget.sex,
              shots: _completedShots,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentShot = AppConfig.shotSequence[_currentShotIndex];
    final allGreen = _gateMuzzle && _gateBlur && _gateBrightness;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          CameraPreview(_controller!),
          
          // Oval Overlay
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54, width: 4),
                borderRadius: BorderRadius.circular(1000), // Makes it an oval
              ),
            ),
          ),
          
          // Top Info
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentShot,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 32),
                  onPressed: _toggleTorch,
                )
              ],
            ),
          ),

          // Corrective Tips
          if (_tipMessage != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.redAccent.withValues(alpha: 0.8),
                child: Text(
                  _tipMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Quality Gates Indicators
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GateIndicator(isGreen: _gateMuzzle),
                const SizedBox(width: 20),
                _GateIndicator(isGreen: _gateBlur),
                const SizedBox(width: 20),
                _GateIndicator(isGreen: _gateBrightness),
              ],
            ),
          ),

          // Shutter Button
          if (allGreen)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.teal, width: 4),
                    ),
                  ),
                ),
              ),
            ),

          // Thumbnail Strip
          if (_completedShots.isNotEmpty)
            Positioned(
              bottom: 40,
              left: 20,
              child: SizedBox(
                height: 60,
                width: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _completedShots.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        image: DecorationImage(
                          image: FileImage(File(_completedShots[index]['filePath'])),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
        ],
      ),
    );
  }
}

class _GateIndicator extends StatelessWidget {
  final bool isGreen;
  const _GateIndicator({required this.isGreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isGreen ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}
