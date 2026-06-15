import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Design token: all text styles.
// Line-heights are expressed as height multipliers (Flutter convention).
// screenTitle, cardTitle, numStrong use Quicksand (geometric heading font).
abstract final class AppText {
  static TextStyle get screenTitle => GoogleFonts.quicksand(
    fontSize: 18, fontWeight: FontWeight.w700, height: 1.2,
  );
  static TextStyle get cardTitle => GoogleFonts.quicksand(
    fontSize: 14, fontWeight: FontWeight.w700, height: 1.25,
  );
  static TextStyle get numStrong => GoogleFonts.quicksand(
    fontSize: 15, fontWeight: FontWeight.w700, height: 1.1,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, height: 1.25,
  );
  static const TextStyle body = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, height: 1.3,
  );
  static const TextStyle label = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500, height: 1.2,
  );
  static const TextStyle meta = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400, height: 1.2,
  );
}
