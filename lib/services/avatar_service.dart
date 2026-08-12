import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarService {
  AvatarService._();
  static final AvatarService instance = AvatarService._();

  final _client = Supabase.instance.client;
  final _picker = ImagePicker();

  /// فتح معرض الصور واختيار صورة مضغوطة ورفعها
  /// يرجع الـ URL العام أو null عند الإلغاء أو الخطأ
  Future<String?> pickAndUpload() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;

    // فتح الاستوديو مع ضغط الصورة مباشرة
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,   // ضغط 60% يكفي للصور الشخصية
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null) return null;

    try {
      final bytes = await File(file.path).readAsBytes();
      final ext   = file.path.split('.').last.toLowerCase();
      final path  = 'avatars/$uid.$ext';

      // رفع الصورة إلى Supabase Storage
      await _client.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true, // استبدل القديمة إذا موجودة
        ),
      );

      // الحصول على الـ URL العام
      final url = _client.storage.from('avatars').getPublicUrl(path);

      // حفظ الـ URL في جدول profiles
      await _client.from('profiles').update({'avatar_url': url}).eq('id', uid);

      return url;
    } catch (_) {
      return null;
    }
  }
}
