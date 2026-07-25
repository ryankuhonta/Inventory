import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MVP package dependencies stay local-only and offline-first', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    for (final package in _forbiddenPackages) {
      expect(
        _declaresPackage(pubspec, package),
        isFalse,
        reason: 'MVP release should not depend on $package.',
      );
    }

    expect(pubspec, contains('version: 0.1.0+1'));
    expect(pubspec, contains('pubspec.yaml'));
  });

  test('MVP feature tree excludes deferred release scope', () {
    final featureNames = Directory('lib/features')
        .listSync()
        .whereType<Directory>()
        .map(
          (directory) => directory.uri.pathSegments
              .where((segment) => segment.isNotEmpty)
              .last,
        )
        .toSet();

    expect(
      featureNames,
      {'dashboard', 'history', 'products', 'settings', 'stock'},
    );
    expect(featureNames.intersection(_forbiddenFeatureFolders), isEmpty);
  });

  test('Android manifest remains offline-first with no extra permissions', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, isNot(contains('android.permission.INTERNET')));
    expect(manifest, isNot(contains('android.permission.CAMERA')));
    expect(manifest, isNot(contains('android.permission.POST_NOTIFICATIONS')));
    expect(manifest, isNot(contains('<uses-permission')));
  });

  test('Android build config has release placeholders documented cleanly', () {
    final buildConfig = File('android/app/build.gradle.kts').readAsStringSync();

    expect(buildConfig, contains('applicationId = "com.rkuhonta.tindatrack"'));
    expect(buildConfig, contains('versionCode = flutter.versionCode'));
    expect(buildConfig, contains('versionName = flutter.versionName'));
    expect(buildConfig, contains('signingConfigs.getByName("debug")'));
    expect(buildConfig, isNot(contains('TODO')));
  });
}

bool _declaresPackage(String pubspec, String package) {
  return RegExp(
    '^  ${RegExp.escape(package)}:',
    multiLine: true,
  ).hasMatch(pubspec);
}

const _forbiddenPackages = {
  'http',
  'dio',
  'firebase_core',
  'firebase_auth',
  'firebase_analytics',
  'firebase_crashlytics',
  'cloud_firestore',
  'google_mobile_ads',
  'mobile_scanner',
  'barcode_scan2',
  'sentry_flutter',
  'supabase_flutter',
};

const _forbiddenFeatureFolders = {
  'accounting',
  'analytics',
  'auth',
  'barcode',
  'branches',
  'cloud',
  'login',
  'pos',
  'remote',
  'scanner',
  'staff',
  'suppliers',
  'sync',
};
