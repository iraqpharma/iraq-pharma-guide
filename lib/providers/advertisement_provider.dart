import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/advertisement.dart';

final advertisementsProvider = StreamProvider<List<Advertisement>>((ref) {
  return Supabase.instance.client
      .from('advertisements')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows
          .map(Advertisement.fromJson)
          .where((ad) => ad.isActive)
          .toList());
});
