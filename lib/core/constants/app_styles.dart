import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppStyles {
  static TextStyle headingLarge = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static TextStyle headingMedium = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle bodyText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static TextStyle buttonText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle brandName = GoogleFonts.birthstone(
    fontSize: 52,
    fontWeight: FontWeight.w400,
    color: AppColors.rose,
  );
}
