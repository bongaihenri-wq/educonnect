import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  // === PALETTE VIOLET + BIS ===
  static const Color violet = Color(0xFF7C3AED);
  static const Color violetLight = Color(0xFFA78BFA);
  static const Color violetDark = Color(0xFF5B21B6);
  static const Color violetPale = Color(0xFFEDE9FE);
  static const Color violetLighter = Color(0xFFF5F3FF);
  
  static const Color bis = Color(0xFFF5F5DC);
  static const Color bisLight = Color(0xFFFAFAF5);
  static const Color bisDark = Color(0xFFE8E4D9);
  static const Color bisWarm = Color(0xFFF0EAD6);
  
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFDFDFD);
  
  static const Color nightBlue = Color(0xFF1E1B4B);
  static const Color nightBlueLight = Color(0xFF312E81);
  static const Color nightBlueLighter = Color(0xFF4338CA);
  static const Color tealDark = Color(0xFF0F766E);
  
  static const Color teal = Color(0xFF14B8A6);
  static const Color coral = Color(0xFFFB7185);
  static const Color sunshine = Color(0xFFF59E0B);
  static const Color mint = Color(0xFF10B981);
  static const Color rose = Color(0xFFF43F5E);
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: violet,
      scaffoldBackgroundColor: bisLight,
      colorScheme: const ColorScheme.light(
        primary: violet,
        secondary: teal,
        surface: white,
        background: bisLight,
        error: error,
        onPrimary: white,
        onSecondary: white,
        onSurface: nightBlue,
        onBackground: nightBlue,
        onError: white,
      ),
      // Polices système au lieu de Google Fonts
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32.sp, 
          fontWeight: FontWeight.bold, 
          color: nightBlue,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28.sp, 
          fontWeight: FontWeight.bold, 
          color: nightBlue,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 24.sp, 
          fontWeight: FontWeight.w700, 
          color: nightBlue,
        ),
        headlineMedium: TextStyle(
          fontSize: 20.sp, 
          fontWeight: FontWeight.w600, 
          color: nightBlue,
        ),
        headlineSmall: TextStyle(
          fontSize: 18.sp, 
          fontWeight: FontWeight.w600, 
          color: nightBlue,
        ),
        titleLarge: TextStyle(
          fontSize: 16.sp, 
          fontWeight: FontWeight.w600, 
          color: nightBlue,
        ),
        bodyLarge: TextStyle(
          fontSize: 16.sp, 
          color: nightBlue,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.sp, 
          color: nightBlueLight,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12.sp, 
          color: nightBlueLight.withOpacity(0.8),
        ),
        labelLarge: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: violet,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: violet,
          foregroundColor: white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          textStyle: TextStyle(
            fontSize: 15.sp, 
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: violet,
          side: const BorderSide(color: violet, width: 2),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          textStyle: TextStyle(
            fontSize: 15.sp, 
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: violet,
          textStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: bisDark, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: violet, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: error, width: 2.5),
        ),
        labelStyle: TextStyle(
          fontSize: 14.sp, 
          color: nightBlueLight,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          fontSize: 14.sp, 
          color: nightBlueLight.withOpacity(0.5),
        ),
        prefixIconColor: violet,
        suffixIconColor: nightBlueLight,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        color: white,
        shadowColor: violet.withOpacity(0.1),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: bisLight,
        foregroundColor: nightBlue,
        titleTextStyle: TextStyle(
          fontSize: 20.sp, 
          fontWeight: FontWeight.w700, 
          color: nightBlue,
        ),
        iconTheme: const IconThemeData(color: violet, size: 24),
        actionsIconTheme: const IconThemeData(color: nightBlue),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: violet,
        unselectedItemColor: nightBlueLight.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bis,
        selectedColor: violetPale,
        labelStyle: TextStyle(
          fontSize: 12.sp,
          color: nightBlue,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 12.sp,
          color: violetDark,
          fontWeight: FontWeight.w600,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: violet,
        foregroundColor: white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: bisDark,
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: nightBlue,
        contentTextStyle: TextStyle(
          fontSize: 14.sp,
          color: white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: violet,
        unselectedLabelColor: nightBlueLight.withOpacity(0.6),
        indicatorColor: violet,
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return lightTheme;
  }
  
  static LinearGradient get violetGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, violetLight],
  );
  
  static LinearGradient get heroGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, teal],
  );
  
  static LinearGradient get sunsetGradient => const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [violet, coral, sunshine],
  );
  
  static LinearGradient get softGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [violetPale, bisLight],
  );
}

