// Member names describe the small, class-documented presentation API.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

/// Approved system-font typography roles for the MVP.
abstract final class AppTypography {
  static const textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  );
}
