import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

enum RepairPhotoType { before, after }

extension RepairPhotoTypeX on RepairPhotoType {
  String get name {
    return switch (this) {
      RepairPhotoType.before => 'before',
      RepairPhotoType.after => 'after',
    };
  }

  String get label {
    return switch (this) {
      RepairPhotoType.before => 'Tamir Öncesi',
      RepairPhotoType.after => 'Tamir Sonrası',
    };
  }
}

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadRepairPhoto({
    required String trackingCode,
    required RepairPhotoType type,
    required XFile file,
    required void Function(double) onProgress,
  }) async {
    final cleanedCode = trackingCode.trim().toUpperCase();
    final extension = file.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = 'repair_requests/$cleanedCode/${type.name}/$fileName';
    final ref = _storage.ref(path);

    final uploadTask = ref.putFile(File(file.path));
    uploadTask.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> deleteRepairPhoto(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }
}
