import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/theme/models/job_model.dart' as job_models;
import '../../../services/api_service.dart';

class HomeService {
  static final HomeService _instance = HomeService._internal();

  factory HomeService() {
    return _instance;
  }

  HomeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch user's selected domains from Firestore
  /// Returns empty list if user not found or no domains
  Future<List<String>> getUserDomains() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return [];
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        return [];
      }

      final data = doc.data();
      return List<String>.from(data?['domains'] as List<dynamic>? ?? []);
    } catch (e) {
      debugPrint('Error fetching user domains: $e');
      return [];
    }
  }

  /// Fetch jobs filtered by user's selected domains
  /// Uses whereIn for multiple domains (max 10)
  Future<List<job_models.Job>> getFilteredJobsByUserDomains({
    int limit = 50,
  }) async {
    try {
      final domains = await getUserDomains();

      // If user has no domains, return empty
      if (domains.isEmpty) {
        return [];
      }

      // Query jobs where domain is in user's selected domains
      final snapshot = await _firestore
          .collection('jobs')
          .where('domain', whereIn: domains)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => job_models.Job.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching filtered jobs: $e');
      return [];
    }
  }

  /// Fetch AI recommendations from FastAPI using user's selected domains/skills.
  Future<List<job_models.Job>> getApiRecommendationsForUser({
    int limit = 50,
  }) async {
    try {
      final domains = await getUserDomains();

      if (domains.isEmpty) {
        return [];
      }

      final List<dynamic> apiJobs =
          await ApiService.getRecommendations(domains);
      final List<dynamic> limitedJobs = apiJobs.take(limit).toList();

      return limitedJobs.map((dynamic item) {
        final Map<String, dynamic> jobMap =
            Map<String, dynamic>.from(item as Map<dynamic, dynamic>);

        final dynamic rawSkills = jobMap['skills'];
        final List<dynamic> parsedSkills =
            rawSkills is List<dynamic> ? rawSkills : <dynamic>[];

        return job_models.Job(
          title: (jobMap['title'] ?? '').toString(),
          company: (jobMap['company'] ?? '').toString(),
          location: (jobMap['location'] ?? '').toString(),
          description: (jobMap['description'] ?? '').toString(),
          skills: parsedSkills,
          domain: (jobMap['domain'] ?? '').toString(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching API recommendations: $e');
      return [];
    }
  }

  /// Stream jobs filtered by user's selected domains
  /// For real-time updates as jobs are added/modified
  Stream<List<job_models.Job>> getFilteredJobsFeed({int limit = 50}) async* {
    try {
      final domains = await getUserDomains();

      // If no domains, yield empty stream
      if (domains.isEmpty) {
        yield [];
        return;
      }

      // Stream jobs matching user's domains
      yield* _firestore
          .collection('jobs')
          .where('domain', whereIn: domains)
          .limit(limit)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snap) {
        return snap.docs
            .map((doc) => job_models.Job.fromFirestore(doc.data()))
            .toList();
      });
    } catch (e) {
      debugPrint('Error in filtered jobs stream: $e');
      yield [];
    }
  }

  /// Fetch jobs from Firestore with limit and optional filters
  /// This is structured for future scalability:
  /// - Later: add sorting by AI rank
  /// - Later: add search parameter
  Stream<List<job_models.Job>> getJobsFeed({
    int limit = 50,
    String? domainFilter,
    String? sortBy,
  }) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('jobs').limit(limit);

    // Apply single domain filter if provided
    if (domainFilter != null && domainFilter.isNotEmpty) {
      query = query.where('domain', isEqualTo: domainFilter);
    }

    return query.snapshots().map((QuerySnapshot<Map<String, dynamic>> snap) {
      final list = snap.docs
          .map((doc) => job_models.Job.fromFirestore(doc.data()))
          .toList();
      return list;
    });
  }

  /// Fetch a single job by ID (for detail view in future)
  Future<job_models.Job?> getJobById(String jobId) async {
    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();
      if (doc.exists) {
        return job_models.Job.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching job by ID: $e');
      return null;
    }
  }
}
