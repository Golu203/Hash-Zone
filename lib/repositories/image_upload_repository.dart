import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cloudinary_image.dart';
import '../services/cloudinary_service.dart';

enum UploadStatus { idle, uploading, success, error }

class ImageFileData {
  final Uint8List bytes;
  final String filename;

  ImageFileData({required this.bytes, required this.filename});
}

class ImageUploadTask {
  final String id;
  final Uint8List bytes;
  final String filename;
  UploadStatus status;
  double progress;
  CloudinaryImage? cloudinaryImage;
  String? errorMessage;
  bool isCover;
  int displayOrder;

  ImageUploadTask({
    required this.id,
    required this.bytes,
    required this.filename,
    this.status = UploadStatus.idle,
    this.progress = 0.0,
    this.cloudinaryImage,
    this.errorMessage,
    this.isCover = false,
    this.displayOrder = 1,
  });

  ImageUploadTask copyWith({
    UploadStatus? status,
    double? progress,
    CloudinaryImage? cloudinaryImage,
    String? errorMessage,
    bool? isCover,
    int? displayOrder,
  }) {
    return ImageUploadTask(
      id: id,
      bytes: bytes,
      filename: filename,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      cloudinaryImage: cloudinaryImage ?? this.cloudinaryImage,
      errorMessage: errorMessage ?? this.errorMessage,
      isCover: isCover ?? this.isCover,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}

class ImageUploadRepository extends ChangeNotifier {
  final CloudinaryService _cloudinaryService;

  List<ImageUploadTask> _tasks = [];

  ImageUploadRepository(this._cloudinaryService);

  List<ImageUploadTask> get tasks => List.unmodifiable(_tasks);

  bool get isUploadingAny => _tasks.any((t) => t.status == UploadStatus.uploading);

  bool get hasErrors => _tasks.any((t) => t.status == UploadStatus.error);

  bool get allUploadsSuccessful =>
      _tasks.isNotEmpty && _tasks.every((t) => t.status == UploadStatus.success);

  /// Initializes repository with existing CloudinaryImages when editing an existing product
  void initExistingImages(List<CloudinaryImage> existingImages) {
    _tasks = existingImages.asMap().entries.map((entry) {
      final idx = entry.key;
      final img = entry.value;
      return ImageUploadTask(
        id: 'existing_${idx}_${img.publicId}',
        bytes: Uint8List(0),
        filename: img.publicId,
        status: UploadStatus.success,
        progress: 1.0,
        cloudinaryImage: img,
        isCover: img.isCover,
        displayOrder: img.displayOrder,
      );
    }).toList();
    notifyListeners();
  }

  /// Adds new byte files to upload task list
  void addFiles(List<ImageFileData> files) {
    int nextOrder = _tasks.length + 1;
    for (final file in files) {
      final isFirstOverall = _tasks.isEmpty && nextOrder == 1;
      final task = ImageUploadTask(
        id: '${DateTime.now().microsecondsSinceEpoch}_${file.filename}',
        bytes: file.bytes,
        filename: file.filename,
        status: UploadStatus.idle,
        progress: 0.0,
        isCover: isFirstOverall,
        displayOrder: nextOrder++,
      );
      _tasks.add(task);
    }
    notifyListeners();
  }

  /// Uploads single task to Cloudinary
  Future<void> uploadTask(
    ImageUploadTask task, {
    required String cloudName,
    required String uploadPreset,
    required String folder,
  }) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    _tasks[index].status = UploadStatus.uploading;
    _tasks[index].progress = 0.05;
    _tasks[index].errorMessage = null;
    notifyListeners();

    try {
      final result = await _cloudinaryService.uploadImage(
        bytes: task.bytes,
        filename: task.filename,
        cloudName: cloudName,
        uploadPreset: uploadPreset,
        folder: folder,
        onProgress: (p) {
          final i = _tasks.indexWhere((t) => t.id == task.id);
          if (i != -1) {
            _tasks[i].progress = p;
            notifyListeners();
          }
        },
      );

      final i = _tasks.indexWhere((t) => t.id == task.id);
      if (i != -1) {
        _tasks[i].status = UploadStatus.success;
        _tasks[i].progress = 1.0;
        _tasks[i].cloudinaryImage = result.copyWith(
          isCover: _tasks[i].isCover,
          displayOrder: _tasks[i].displayOrder,
        );
        notifyListeners();
      }
    } catch (e) {
      final i = _tasks.indexWhere((t) => t.id == task.id);
      if (i != -1) {
        _tasks[i].status = UploadStatus.error;
        _tasks[i].errorMessage = e.toString();
        notifyListeners();
      }
    }
  }

  /// Starts uploading all pending/idle or errored tasks
  Future<void> uploadAll({
    required String cloudName,
    required String uploadPreset,
    required String folder,
  }) async {
    final pending = _tasks.where((t) => t.status == UploadStatus.idle || t.status == UploadStatus.error).toList();
    for (final task in pending) {
      await uploadTask(task, cloudName: cloudName, uploadPreset: uploadPreset, folder: folder);
    }
  }

  /// Retries a failed task
  Future<void> retryTask(
    String id, {
    required String cloudName,
    required String uploadPreset,
    required String folder,
  }) async {
    final task = _tasks.firstWhere((t) => t.id == id);
    await uploadTask(task, cloudName: cloudName, uploadPreset: uploadPreset, folder: folder);
  }

  /// Removes an image task
  void removeTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    // If cover image was removed, assign cover to first task
    if (_tasks.isNotEmpty && !_tasks.any((t) => t.isCover)) {
      _tasks.first.isCover = true;
    }
    _reindexDisplayOrders();
    notifyListeners();
  }

  /// Sets cover image
  void setCoverImage(String id) {
    for (int i = 0; i < _tasks.length; i++) {
      _tasks[i].isCover = (_tasks[i].id == id);
      if (_tasks[i].cloudinaryImage != null) {
        _tasks[i].cloudinaryImage = _tasks[i].cloudinaryImage!.copyWith(isCover: _tasks[i].isCover);
      }
    }
    notifyListeners();
  }

  /// Reorders tasks
  void reorderTasks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, item);
    _reindexDisplayOrders();
    notifyListeners();
  }

  void _reindexDisplayOrders() {
    for (int i = 0; i < _tasks.length; i++) {
      _tasks[i].displayOrder = i + 1;
      if (_tasks[i].cloudinaryImage != null) {
        _tasks[i].cloudinaryImage = _tasks[i].cloudinaryImage!.copyWith(displayOrder: i + 1);
      }
    }
  }

  /// Returns final List of CloudinaryImages ready for Firestore
  List<CloudinaryImage> getFinalCloudinaryImages() {
    _reindexDisplayOrders();
    return _tasks
        .where((t) => t.status == UploadStatus.success && t.cloudinaryImage != null)
        .map((t) => t.cloudinaryImage!.copyWith(isCover: t.isCover, displayOrder: t.displayOrder))
        .toList();
  }

  void clear() {
    _tasks.clear();
    notifyListeners();
  }
}

// Riverpod Provider
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) => CloudinaryService());

final imageUploadRepositoryProvider = ChangeNotifierProvider<ImageUploadRepository>((ref) {
  return ImageUploadRepository(ref.watch(cloudinaryServiceProvider));
});
