import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/job_record.dart';
import '../models/user_profile.dart';

class AppStorage {
  static const _profileKey = 'nz_job_matcher_profile_v1';
  static const _jobsKey = 'nz_job_matcher_jobs_v1';
  static const _secureStorage = FlutterSecureStorage();

  Future<UserProfile> loadProfile() async {
    final raw = await _secureStorage.read(key: _profileKey);
    if (raw == null || raw.isEmpty) return const UserProfile();
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const UserProfile();
    } on TypeError {
      return const UserProfile();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _secureStorage.write(key: _profileKey, value: jsonEncode(profile.toJson()));
  }

  Future<List<JobRecord>> loadJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_jobsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final items = jsonDecode(raw) as List<dynamic>;
      return items.map((item) => JobRecord.fromJson(item as Map<String, dynamic>)).toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> saveJobs(List<JobRecord> jobs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_jobsKey, jsonEncode(jobs.map((job) => job.toJson()).toList()));
  }
}
