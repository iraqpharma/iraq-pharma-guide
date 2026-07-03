import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AvatarResult { success, permissionDenied, permissionPermanentlyDenied, cancelled, error }

class AvatarUploadResult {
  final AvatarResult status;
  final String? url;
  final String? errorMessage;
  const AvatarUploadResult._(this.status, {this.url, this.errorMessage});

  factory AvatarUploadResult.success(String url) =>
      AvatarUploadResult._(AvatarResult.success, url: url);
  factory AvatarUploadResult.permissionDenied() =>
      AvatarUploadResult._(AvatarResult.permissionDenied);
  factory AvatarUploadResult.permissionPermanent() =>
      AvatarUploadResult._(AvatarResult.permissionPermanentlyDenied);
  factory AvatarUploadResult.cancelled() =>
      AvatarUploadResult._(AvatarResult.cancelled);
  factory AvatarUploadResult.error(String msg) =>
      AvatarUploadResult._(AvatarResult.error, errorMessage: msg);
}

class AvatarService {
  AvatarService._();
  static final AvatarService instance = AvatarService._();

  final _client = Supabase.instance.client;
  final _picker = ImagePicker();

  /// طلب إذن المعرض ثم فتحه واختيار الصورة ورفعها
  Future<AvatarUploadResult> pickAndUpload() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return AvatarUploadResult.error('المستخدم غير مسجّل');

    // ── 1. طلب الإذن أولاً ────────────────────────────────────────────────
    final permission = Platform.isAndroid
        ? (await _androidPhotoPermission())
        : Permission.photos;

    final status = await permission.request();

    if (status.isPermanentlyDenied) {
      return AvatarUploadResult.permissionPermanent();
    }
    if (!status.isGranted) {
      return AvatarUploadResult.permissionDenied();
    }

    // ── 2. فتح المعرض ─────────────────────────────────────────────────────
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null) return AvatarUploadResult.cancelled();

    // ── 3. رفع الصورة إلى Supabase Storage ───────────────────────────────
    try {
      final bytes = await File(file.path).readAsBytes();
      final ext   = file.path.split('.').last.toLowerCase().replaceAll('jpg', 'jpeg');
      final path  = 'avatars/$uid.$ext';

      await _client.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true,
        ),
      );

      // كسر الكاش بإضافة timestamp
      final baseUrl = _client.storage.from('avatars').getPublicUrl(path);
      final url = '$baseUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      // ── 4. تحديث جدول profiles ───────────────────────────────────────────
      await _client
          .from('profiles')
          .upsert({'id': uid, 'avatar_url': url}, onConflict: 'id');

      return AvatarUploadResult.success(url);
    } on StorageException catch (e) {
      return AvatarUploadResult.error('خطأ في الرفع: ${e.message}');
    } catch (e) {
      return AvatarUploadResult.error('خطأ غير متوقع: $e');
    }
  }

  /// على Android 13+ نحتاج READ_MEDIA_IMAGES، وإلا READ_EXTERNAL_STORAGE
  Future<Permission> _androidPhotoPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33)
      if (await Permission.photos.status != PermissionStatus.denied ||
          await Permission.photos.isGranted) {
        return Permission.photos;
      }
      return Permission.storage;
    }
    return Permission.photos;
  }
}
