import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static const String _cloudinaryCloudName =
      'tyctvuni';

  static const String _cloudinaryUploadPreset =
      'smclose_profile_photos';

  User? get currentUser =>
      _auth.currentUser;

  DocumentReference<Map<String, dynamic>>?
      get _userDocument {
    final user =
        _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid);
  }

  // =====================================================
  // PROFILE STREAM
  // =====================================================

  Stream<Map<String, dynamic>?>
      getProfileStream() {
    final doc =
        _userDocument;

    if (doc == null) {
      return Stream.value(
        null,
      );
    }

    return doc.snapshots().map(
      (snapshot) {
        if (!snapshot.exists) {
          return null;
        }

        return snapshot.data();
      },
    );
  }

  // =====================================================
  // GET PROFILE
  // =====================================================

  Future<Map<String, dynamic>?>
      getProfile() async {
    final doc =
        _userDocument;

    if (doc == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    final snapshot =
        await doc.get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  // =====================================================
  // UPLOAD PROFILE PHOTO - CLOUDINARY
  // =====================================================

  Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String extension,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    if (bytes.isEmpty) {
      throw Exception(
        'The selected image is empty.',
      );
    }

    if (bytes.length >
        5 * 1024 * 1024) {
      throw Exception(
        'Profile photo must be smaller than 5 MB.',
      );
    }

    String cleanExtension =
        extension
            .trim()
            .toLowerCase();

    if (cleanExtension.startsWith('.')) {
      cleanExtension =
          cleanExtension.substring(
        1,
      );
    }

    if (![
      'jpg',
      'jpeg',
      'png',
      'webp',
    ].contains(
      cleanExtension,
    )) {
      cleanExtension =
          'jpg';
    }

    final uri =
        Uri.parse(
      'https://api.cloudinary.com/v1_1/'
      '$_cloudinaryCloudName/image/upload',
    );

    final request =
        http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields[
            'upload_preset'] =
        _cloudinaryUploadPreset;

    request.fields['folder'] =
        'smclose/profile_photos';

    request.fields['public_id'] =
        '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename:
            'profile.$cleanExtension',
      ),
    );

    final streamedResponse =
        await request.send();

    final response =
        await http.Response
            .fromStream(
      streamedResponse,
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message =
          'Unable to upload profile photo.';

      try {
        final decoded =
            jsonDecode(
          response.body,
        );

        if (decoded is Map &&
            decoded['error'] is Map) {
          final error =
              decoded['error']
                  as Map;

          final cloudinaryMessage =
              error['message']
                  ?.toString();

          if (cloudinaryMessage !=
                  null &&
              cloudinaryMessage
                  .isNotEmpty) {
            message =
                cloudinaryMessage;
          }
        }
      } catch (_) {}

      throw Exception(
        message,
      );
    }

    final decoded =
        jsonDecode(
      response.body,
    );

    if (decoded is! Map) {
      throw Exception(
        'Invalid upload response.',
      );
    }

    final secureUrl =
        decoded['secure_url']
            ?.toString()
            .trim();

    if (secureUrl == null ||
        secureUrl.isEmpty) {
      throw Exception(
        'Cloudinary did not return a photo URL.',
      );
    }

    final publicId =
        decoded['public_id']
            ?.toString()
            .trim();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'photoUrl':
            secureUrl,

        if (publicId != null &&
            publicId.isNotEmpty)
          'photoPublicId':
              publicId,

        'updatedAt':
            FieldValue
                .serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    await user.updatePhotoURL(
      secureUrl,
    );

    return secureUrl;
  }

  // =====================================================
  // REMOVE PROFILE PHOTO
  // =====================================================

  Future<void>
      removeProfilePhoto() async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'photoUrl':
            FieldValue.delete(),

        'photoPublicId':
            FieldValue.delete(),

        'updatedAt':
            FieldValue
                .serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    await user.updatePhotoURL(
      null,
    );
  }

  // =====================================================
  // SAVE CLIENT PROFILE
  // =====================================================

  Future<void> saveProfile({
    required String name,
    required String phone,
    required String location,
    required String bio,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    final nameValue =
        name.trim();

    final phoneValue =
        phone.trim();

    final locationValue =
        location.trim();

    final bioValue =
        bio.trim();

    if (nameValue.isEmpty) {
      throw Exception(
        'Please enter your name.',
      );
    }

    if (phoneValue.isEmpty) {
      throw Exception(
        'Please enter your phone number.',
      );
    }

    if (locationValue.isEmpty) {
      throw Exception(
        'Please enter your location.',
      );
    }

    final doc =
        _firestore
            .collection('users')
            .doc(user.uid);

    final existing =
        await doc.get();

    final data =
        <String, dynamic>{
      'uid':
          user.uid,

      'email':
          user.email,

      'name':
          nameValue,

      'phone':
          phoneValue,

      'location':
          locationValue,

      'bio':
          bioValue,

      'clientProfileComplete':
          true,

      'updatedAt':
          FieldValue
              .serverTimestamp(),
    };

    if (!existing.exists) {
      data['createdAt'] =
          FieldValue
              .serverTimestamp();
    }

    await doc.set(
      data,
      SetOptions(
        merge: true,
      ),
    );

    if (user.displayName !=
        nameValue) {
      await user.updateDisplayName(
        nameValue,
      );
    }
  }

  // =====================================================
  // SAVE WORKER PROFILE
  // =====================================================

  Future<void> saveWorkerProfile({
    required String name,
    required String phone,
    required String location,
    required String bio,
    required List<String> skills,
    required List<String> categories,
    required int experienceYears,
    required bool acceptingJobs,
    required Map<
            String,
            List<Map<String, int>>>
        availability,
  }) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in.',
      );
    }

    final nameValue =
        name.trim();

    final phoneValue =
        phone.trim();

    final locationValue =
        location.trim();

    final bioValue =
        bio.trim();

    if (nameValue.isEmpty) {
      throw Exception(
        'Please enter your name.',
      );
    }

    if (phoneValue.isEmpty) {
      throw Exception(
        'Please enter your phone number.',
      );
    }

    if (locationValue.isEmpty) {
      throw Exception(
        'Please enter your location.',
      );
    }

    if (skills.isEmpty) {
      throw Exception(
        'Please add at least one skill.',
      );
    }

    if (categories.isEmpty) {
      throw Exception(
        'Please select at least one work category.',
      );
    }

    if (acceptingJobs) {
      final hasAvailability =
          availability.values.any(
        (slots) =>
            slots.isNotEmpty,
      );

      if (!hasAvailability) {
        throw Exception(
          'Please add at least one availability time slot.',
        );
      }
    }

    for (final entry
        in availability.entries) {
      for (final slot
          in entry.value) {
        final start =
            slot[
                'startMinutes'];

        final end =
            slot[
                'endMinutes'];

        if (start == null ||
            end == null ||
            start < 0 ||
            end > 1440 ||
            start >= end) {
          throw Exception(
            'Invalid availability time found.',
          );
        }
      }
    }

    final doc =
        _firestore
            .collection('users')
            .doc(user.uid);

    final existing =
        await doc.get();

    final existingData =
        existing.data();

    final rawWorker =
        existingData?[
            'workerProfile'];

    final oldWorker =
        rawWorker is Map
            ? Map<String,
                dynamic>.from(
                rawWorker,
              )
            : <String,
                dynamic>{};

    final data =
        <String, dynamic>{
      'uid':
          user.uid,

      'email':
          user.email,

      'name':
          nameValue,

      'phone':
          phoneValue,

      'location':
          locationValue,

      'bio':
          bioValue,

      'workerProfileComplete':
          true,

      'workerProfile': {
        'skills':
            skills,

        'categories':
            categories,

        'experienceYears':
            experienceYears,

        'acceptingJobs':
            acceptingJobs,

        'isAvailable':
            acceptingJobs,

        'availability':
            availability,

        'rating':
            oldWorker[
                    'rating'] ??
                0.0,

        'reviewCount':
            oldWorker[
                    'reviewCount'] ??
                0,

        'completedJobs':
            oldWorker[
                    'completedJobs'] ??
                0,

        if (oldWorker[
                'lastReviewJobId'] !=
            null)
          'lastReviewJobId':
              oldWorker[
                  'lastReviewJobId'],
      },

      'updatedAt':
          FieldValue
              .serverTimestamp(),
    };

    if (!existing.exists) {
      data['createdAt'] =
          FieldValue
              .serverTimestamp();
    }

    await doc.set(
      data,
      SetOptions(
        merge: true,
      ),
    );

    if (user.displayName !=
        nameValue) {
      await user.updateDisplayName(
        nameValue,
      );
    }
  }
}