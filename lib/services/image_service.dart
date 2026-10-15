import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ProcessedImageResult {
  final String originalPath;
  final String thumbnailPath;
  final int fileSizeBytes;

  const ProcessedImageResult({
    required this.originalPath,
    required this.thumbnailPath,
    required this.fileSizeBytes,
  });
}

/// خدمة معالجة وضغط وتخزين صور الأجهزة محلياً وفق القرار الهندسي Decision 02 & Decision 07
class ImageService {
  final Uuid _uuid = const Uuid();

  /// معالجة صورة جهاز جديدة: ضغط ذكي + توليد Thumbnail سريع + حفظ في مسار التطبيق المحمي
  Future<ProcessedImageResult> processAndSaveDeviceImage({
    required File sourceImageFile,
    required int deviceId,
    String imageType = 'intake',
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'device_images', 'device_$deviceId'));
    final thumbsDir = Directory(p.join(appDir.path, 'device_images', 'thumbnails'));

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    if (!await thumbsDir.exists()) {
      await thumbsDir.create(recursive: true);
    }

    final rawBytes = await sourceImageFile.readAsBytes();
    final decodedImage = img.decodeImage(rawBytes);

    if (decodedImage == null) {
      throw Exception('تعذر فك ترميز صورة الجهاز الملتقطة.');
    }

    // 1. تصحيح الاتجاه وفق بيانات EXIF
    final orientedImage = img.bakeOrientation(decodedImage);

    // 2. تغيير الحجم للصورة الأصلية إن كانت ضخمة جداً (حد أقصى 1920px) مع الحفاظ على التناسب
    img.Image resizedOriginal = orientedImage;
    if (orientedImage.width > 1920 || orientedImage.height > 1920) {
      resizedOriginal = img.copyResize(
        orientedImage,
        width: orientedImage.width > orientedImage.height ? 1920 : null,
        height: orientedImage.height >= orientedImage.width ? 1920 : null,
        interpolation: img.Interpolation.linear,
      );
    }

    // 3. ضغط الصورة الأصلية بصيغة JPEG بجودة 85%
    final compressedBytes = img.encodeJpg(resizedOriginal, quality: 85);
    final fileId = _uuid.v4();
    final originalPath = p.join(imagesDir.path, '${imageType}_$fileId.jpg');
    final savedOriginalFile = File(originalPath);
    await savedOriginalFile.writeAsBytes(compressedBytes);

    // 4. توليد الصورة المصغرة (Thumbnail 300x300) لتسريع عرض القوائم
    final thumbnail = img.copyResizeCropSquare(orientedImage, size: 300);
    final thumbBytes = img.encodeJpg(thumbnail, quality: 75);
    final thumbnailPath = p.join(thumbsDir.path, 'thumb_$fileId.jpg');
    final savedThumbFile = File(thumbnailPath);
    await savedThumbFile.writeAsBytes(thumbBytes);

    return ProcessedImageResult(
      originalPath: originalPath,
      thumbnailPath: thumbnailPath,
      fileSizeBytes: compressedBytes.length,
    );
  }

  /// حذف صور الجهاز عند حذف السجل
  Future<void> deleteDeviceImages(List<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // تجاهل أخطاء الملفات المحذوفة مسبقاً
      }
    }
  }
}
