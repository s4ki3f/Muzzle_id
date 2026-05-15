import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/upload_task.dart';
import '../../../core/config/app_config.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  return SyncManager();
});

class SyncManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  Box<MuzzleUploadTask> get _queue => Hive.box<MuzzleUploadTask>('uploadQueue');

  SyncManager() {
    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        processQueue();
      }
    });
  }

  Future<void> addToQueue(MuzzleUploadTask task) async {
    await _queue.put(task.id, task);
    
    // Attempt to write initial metadata to Firestore
    try {
      await _writeMetadata(task);
    } catch (e) {
      // Offline, will retry later
    }
    
    processQueue();
  }

  Future<void> processQueue() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.mobile) && 
        !connectivityResult.contains(ConnectivityResult.wifi)) {
      return;
    }

    final tasks = _queue.values.where((t) => t.status == 'queued' || t.status == 'failed').toList();
    
    for (var task in tasks) {
      task.status = 'uploading';
      await task.save();

      try {
        await _uploadShots(task);
        await _writeMetadata(task, finalUpload: true);
        
        task.status = 'uploaded';
        await task.save();
      } catch (e) {
        task.status = 'failed';
        await task.save();
      }
    }
  }

  Future<void> _uploadShots(MuzzleUploadTask task) async {
    for (var shot in task.shots) {
      final String filePath = shot['filePath'];
      final String filename = filePath.split('/').last;
      final File file = File(filePath);
      if (!await file.exists()) continue;

      final basePath = task.mode == AppMode.collector ? 'muzzleid-raw' : 'muzzleid-claims';
      final ref = _storage.ref().child('$basePath/${task.id}/$filename');
      
      await ref.putFile(file);
    }
  }

  Future<void> _writeMetadata(MuzzleUploadTask task, {bool finalUpload = false}) async {
    final docRef = task.mode == AppMode.collector 
        ? _firestore.collection('cattle').doc(task.id)
        : _firestore.collection('claims').doc(task.id);
        
    final data = {
      if (task.mode == AppMode.collector) 'collectorId': task.collectorOrFarmerId,
      if (task.mode == AppMode.farmerClaim) 'farmerId': task.collectorOrFarmerId,
      if (task.mode == AppMode.farmerClaim) 'cattleId': task.id,
      if (task.mode == AppMode.farmerClaim && task.claimType != null) 'claimType': task.claimType,
      'timestamp': task.timestamp,
      'gps': {
        'lat': task.latitude,
        'lng': task.longitude,
      },
      if (task.mode == AppMode.collector) 'breed': task.breed,
      if (task.mode == AppMode.collector) 'sex': task.sex,
      'submissionStatus': finalUpload ? 'uploaded' : 'queued',
      'shots': task.shots.map((s) {
        final Map<String, dynamic> output = {
          'type': s['type'],
          'filename': s['filePath'].split('/').last,
          'blurScore': s['blurScore'] ?? 1.0,
        };
        if (task.mode == AppMode.collector) {
          output['brightness'] = s['brightness'] ?? 100.0;
        }
        return output;
      }).toList(),
    };
    
    await docRef.set(data, SetOptions(merge: true));

    if (finalUpload && task.mode == AppMode.collector) {
      final collectorRef = _firestore.collection('collectors').doc(task.collectorOrFarmerId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(collectorRef);
        if (!snapshot.exists) {
          transaction.set(collectorRef, {'totalSubmissions': 1, 'acceptedSubmissions': 0});
        } else {
          final total = (snapshot.data()?['totalSubmissions'] ?? 0) + 1;
          transaction.update(collectorRef, {'totalSubmissions': total});
        }
      });
    }
  }
}
