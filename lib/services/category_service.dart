import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryService {
  CategoryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const List<String> defaultCategories = [
    'Cleaning',
    'Electrical',
    'Plumbing',
    'AC & Appliance Repair',
    'Carpentry',
    'Painting',
    'Delivery',
    'Moving',
    'Tutoring',
    'Computer & IT',
    'Photography',
    'Other',
  ];

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');

  Stream<List<Map<String, dynamic>>> watchAllCategories() {
    return _categories.snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) {
        return <String, dynamic>{
          ...doc.data(),
          'categoryId': doc.id,
        };
      }).toList();

      items.sort((a, b) {
        final aOrder = (a['sortOrder'] as num?)?.toInt() ?? 9999;
        final bOrder = (b['sortOrder'] as num?)?.toInt() ?? 9999;

        final orderCompare = aOrder.compareTo(bOrder);

        if (orderCompare != 0) {
          return orderCompare;
        }

        return (a['name']?.toString() ?? '')
            .toLowerCase()
            .compareTo(
              (b['name']?.toString() ?? '').toLowerCase(),
            );
      });

      return items;
    });
  }

  Stream<List<String>> watchActiveCategoryNames({
    bool includeFallbackDefaults = true,
  }) {
    return watchAllCategories().map((items) {
      final active = items
          .where((item) => item['active'] != false)
          .map((item) => item['name']?.toString().trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      if (active.isEmpty && includeFallbackDefaults) {
        return List<String>.from(defaultCategories);
      }

      return active;
    });
  }

  Future<void> addCategory({
    required String name,
  }) async {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      throw Exception('Category name is required.');
    }

    await _ensureUniqueName(
      name: trimmed,
    );

    final snapshot = await _categories.get();

    final maxOrder = snapshot.docs.fold<int>(
      0,
      (current, doc) {
        final value = (doc.data()['sortOrder'] as num?)?.toInt() ?? 0;
        return value > current ? value : current;
      },
    );

    final ref = _categories.doc();

    await ref.set({
      'categoryId': ref.id,
      'name': trimmed,
      'active': true,
      'sortOrder': maxOrder + 1,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _auth.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    });

    await _writeAuditLog(
      action: 'category_created',
      targetId: ref.id,
      details: {
        'name': trimmed,
      },
    );
  }

  Future<void> updateCategory({
    required String categoryId,
    required String name,
  }) async {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      throw Exception('Category name is required.');
    }

    await _ensureUniqueName(
      name: trimmed,
      excludingId: categoryId,
    );

    await _categories.doc(categoryId).update({
      'name': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    });

    await _writeAuditLog(
      action: 'category_updated',
      targetId: categoryId,
      details: {
        'name': trimmed,
      },
    );
  }

  Future<void> setCategoryActive({
    required String categoryId,
    required bool active,
    required String name,
  }) async {
    await _categories.doc(categoryId).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    });

    await _writeAuditLog(
      action: active
          ? 'category_enabled'
          : 'category_disabled',
      targetId: categoryId,
      details: {
        'name': name,
      },
    );
  }

  Future<void> deleteCategory({
    required String categoryId,
    required String name,
  }) async {
    await _categories.doc(categoryId).delete();

    await _writeAuditLog(
      action: 'category_deleted',
      targetId: categoryId,
      details: {
        'name': name,
      },
    );
  }

  Future<void> seedDefaultCategories() async {
    final snapshot = await _categories.get();

    final existingNames = snapshot.docs
        .map((doc) => doc.data()['name']?.toString().trim().toLowerCase() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();

    final batch = _firestore.batch();

    var created = 0;

    for (var index = 0; index < defaultCategories.length; index++) {
      final name = defaultCategories[index];

      if (existingNames.contains(name.toLowerCase())) {
        continue;
      }

      final ref = _categories.doc();

      batch.set(ref, {
        'categoryId': ref.id,
        'name': name,
        'active': true,
        'sortOrder': index + 1,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });

      created++;
    }

    if (created == 0) {
      return;
    }

    await batch.commit();

    await _writeAuditLog(
      action: 'default_categories_seeded',
      targetId: 'categories',
      details: {
        'createdCount': created,
      },
    );
  }

  Future<void> _ensureUniqueName({
    required String name,
    String? excludingId,
  }) async {
    final snapshot = await _categories.get();

    final normalized = name.trim().toLowerCase();

    final duplicate = snapshot.docs.any((doc) {
      if (doc.id == excludingId) {
        return false;
      }

      return (doc.data()['name']?.toString().trim().toLowerCase() ?? '') ==
          normalized;
    });

    if (duplicate) {
      throw Exception('A category with this name already exists.');
    }
  }

  Future<void> _writeAuditLog({
    required String action,
    required String targetId,
    required Map<String, dynamic> details,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final ref = _firestore.collection('admin_audit_logs').doc();

    await ref.set({
      'logId': ref.id,
      'adminId': user.uid,
      'adminEmail': user.email,
      'action': action,
      'targetType': 'category',
      'targetId': targetId,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
