import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MLService {
  Interpreter? _yoloInterpreter;
  Interpreter? _blurInterpreter;

  String? _currentYoloModelPath;
  String? _currentBlurModelPath;

  bool get isYoloLoaded => _yoloInterpreter != null;
  bool get isBlurLoaded => _blurInterpreter != null;

  /// Load or switch the YOLOv8 model dynamically
  Future<void> loadYoloModel(String modelPath) async {
    try {
      if (_currentYoloModelPath == modelPath && _yoloInterpreter != null) return;
      
      _yoloInterpreter?.close();
      _yoloInterpreter = await Interpreter.fromAsset(modelPath);
      _currentYoloModelPath = modelPath;
      debugPrint('Loaded YOLO model: $modelPath');
    } catch (e) {
      debugPrint('Error loading YOLO model: $e');
      _yoloInterpreter = null;
    }
  }

  /// Load or switch the Blur Classification model dynamically
  Future<void> loadBlurModel(String modelPath) async {
    try {
      if (_currentBlurModelPath == modelPath && _blurInterpreter != null) return;
      
      _blurInterpreter?.close();
      _blurInterpreter = await Interpreter.fromAsset(modelPath);
      _currentBlurModelPath = modelPath;
      debugPrint('Loaded Blur model: $modelPath');
    } catch (e) {
      debugPrint('Error loading Blur model: $e');
      _blurInterpreter = null;
    }
  }

  /// Mock inference for YOLOv8 (to be replaced with actual tensor mapping)
  Future<double> getMuzzleConfidence(CameraImage image) async {
    if (_yoloInterpreter == null) {
      // Fallback to mock logic if no model is loaded
      return Random().nextDouble();
    }
    
    // TODO: Implement actual YOLOv8 pre-processing and tensor inference here.
    // Example:
    // var input = _preprocessImage(image);
    // var output = List.filled(outputShape, 0).reshape([1, ...]);
    // _yoloInterpreter!.run(input, output);
    // return _parseYoloOutput(output);
    
    return Random().nextDouble();
  }

  /// Mock inference for Blur Classifier
  Future<bool> isImageClear(CameraImage image) async {
    if (_blurInterpreter == null) {
      // Fallback to mock logic
      return Random().nextBool();
    }
    
    // TODO: Implement actual Blur model inference here.
    
    return Random().nextBool();
  }

  /// Calculates brightness (Luma) from YUV420 format
  double calculateBrightness(CameraImage image) {
    if (image.format.group != ImageFormatGroup.yuv420 || image.planes.isEmpty) {
      return 100.0; // Fallback
    }
    
    // Real Luma calculation from Y plane
    final yPlane = image.planes[0].bytes;
    int totalLuma = 0;
    
    // Sample every Nth pixel to save CPU
    const sampleRate = 10; 
    int count = 0;
    for (int i = 0; i < yPlane.length; i += sampleRate) {
      totalLuma += yPlane[i];
      count++;
    }
    
    if (count == 0) return 100.0;
    return totalLuma / count;
  }

  void dispose() {
    _yoloInterpreter?.close();
    _blurInterpreter?.close();
  }
}
