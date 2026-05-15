import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../core/config/app_config.dart';

class MuzzleUploadTask extends HiveObject {
  final String id; // cattleId or claimId
  final AppMode mode;
  final String collectorOrFarmerId;
  final double latitude;
  final double longitude;
  final int timestamp;
  final String? breed;
  final String? sex;
  final String? claimType;
  final String shotsJson; // JSON encoded list of maps
  String status; // 'queued', 'uploading', 'uploaded', 'failed'

  MuzzleUploadTask({
    required this.id,
    required this.mode,
    required this.collectorOrFarmerId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.breed,
    this.sex,
    this.claimType,
    required this.shotsJson,
    this.status = 'queued',
  });

  List<Map<String, dynamic>> get shots =>
      List<Map<String, dynamic>>.from(jsonDecode(shotsJson));
}

class MuzzleUploadTaskAdapter extends TypeAdapter<MuzzleUploadTask> {
  @override
  final int typeId = 0;

  @override
  MuzzleUploadTask read(BinaryReader reader) {
    return MuzzleUploadTask(
      id: reader.readString(),
      mode: reader.read(),
      collectorOrFarmerId: reader.readString(),
      latitude: reader.readDouble(),
      longitude: reader.readDouble(),
      timestamp: reader.readInt(),
      breed: reader.readString(),
      sex: reader.readString(),
      claimType: reader.readString(),
      shotsJson: reader.readString(),
      status: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, MuzzleUploadTask obj) {
    writer.writeString(obj.id);
    writer.write(obj.mode);
    writer.writeString(obj.collectorOrFarmerId);
    writer.writeDouble(obj.latitude);
    writer.writeDouble(obj.longitude);
    writer.writeInt(obj.timestamp);
    writer.writeString(obj.breed ?? '');
    writer.writeString(obj.sex ?? '');
    writer.writeString(obj.claimType ?? '');
    writer.writeString(obj.shotsJson);
    writer.writeString(obj.status);
  }
}

class AppModeAdapter extends TypeAdapter<AppMode> {
  @override
  final int typeId = 1;

  @override
  AppMode read(BinaryReader reader) {
    final index = reader.readInt();
    return AppMode.values[index];
  }

  @override
  void write(BinaryWriter writer, AppMode obj) {
    writer.writeInt(obj.index);
  }
}
