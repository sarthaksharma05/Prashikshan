import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/theme/models/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();

  factory UserService() {
    return _instance;
  }

  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveUserOnboardingData({
    required String name,
    required String mobileNumber,
    required String university,
    required String cgpa,
    required String role,
    required List<String> domains,
    required String level,
    required String lookingFor,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore.collection('users').doc(user.uid).set(
        <String, dynamic>{
          'name': name,
          'email': user.email ?? '',
          'mobileNumber': mobileNumber.trim(),
          'university': university.trim(),
          'cgpa': cgpa.trim(),
          'role': role,
          'domains': domains,
          'level': level,
          'lookingFor': lookingFor,
          'isOnboarded': true,
          'createdAt': FieldValue.serverTimestamp(),
          'uid': user.uid,
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw Exception('Firestore error: ${e.message}');
    }
  }

  /// Save company-specific onboarding data
  Future<void> saveCompanyOnboardingData({
    required String companyName,
    required String companySize,
    required List<String> industryDomains,
    // hiringRoles REMOVED — collected per job posting
    required String hiringType,
    required String location,
    required String websiteUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      debugPrint('💾 [COMPANY ONBOARDING] Saving | company: $companyName | domains: $industryDomains');
      await _firestore.collection('users').doc(user.uid).set(
        <String, dynamic>{
          'name': companyName.trim(),
          'email': user.email ?? '',
          'role': 'company',          // ✅ Single source of truth for AppRouter
          'company_name': companyName.trim(),
          'company_size': companySize,
          'domains': industryDomains,
          // 'hiring_roles' REMOVED — will be stored per job posting
          'hiring_type': hiringType,
          'location': location.trim(),
          'website': websiteUrl.trim(),
          'isOnboarded': true,
          'createdAt': FieldValue.serverTimestamp(),
          'uid': user.uid,
        },
        SetOptions(merge: true),
      );
      debugPrint('✅ [COMPANY ONBOARDING] Saved successfully');
    } on FirebaseException catch (e) {
      throw Exception('Firestore error: ${e.message}');
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      return null;
    } on FirebaseException catch (e) {
      throw Exception('Failed to fetch user profile: ${e.message}');
    }
  }

  Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Special query for Companies to fetch all students with optional filters
  Stream<List<UserModel>> getStudentUsers({
    String? domainFilter,
    String? universityFilter,
  }) {
    Query query = _firestore.collection('users').where('role', isEqualTo: 'student');

    if (universityFilter != null && universityFilter != 'All Universities') {
      query = query.where('university', isEqualTo: universityFilter);
    }
    
    // Note: Firestore array-contains only works for one domain.
    // If the student has multiple domains, we'll filter array-contains if domainFilter is set.
    if (domainFilter != null && domainFilter != 'All Domains') {
      query = query.where('domains', arrayContains: domainFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update(updates);
    } on FirebaseException catch (e) {
      throw Exception('Failed to update profile: ${e.message}');
    }
  }

  /// Upload profile photo to Firebase Storage
  Future<String> uploadProfilePhoto(String uid, File file) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$uid.jpg');

      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update user document with the photo URL
      await updateUserProfile(
        uid: uid,
        updates: {'profilePhotoUrl': downloadUrl},
      );

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload profile photo: ${e.message}');
    }
  }

  Future<String> uploadResume(String uid, File file) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('resumes')
          .child('$uid.pdf');

      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'application/pdf'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await updateUserProfile(
        uid: uid,
        updates: {'resumeUrl': downloadUrl},
      );

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload resume: ${e.message}');
    }
  }
}
