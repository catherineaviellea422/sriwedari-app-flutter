import 'package:flutter/services.dart';

/// Formatter input terpusat untuk mencegah karakter ilegal masuk ke kolom form
/// baik lewat keyboard fisik (Web/Desktop) maupun paste.
class SwInputFormatters {
  const SwInputFormatters._();

  /// Hanya huruf (A-Z / a-z), spasi, serta tanda baca nama wajar (`. , ' -`).
  /// Angka dan simbol lain diblokir langsung.
  static final List<TextInputFormatter> personName = [
    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s.,'\-]")),
    LengthLimitingTextInputFormatter(80),
  ];

  /// Khusus nomor WhatsApp: hanya digit angka 0-9 (maks. 15 digit).
  static final List<TextInputFormatter> phoneDigits = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(15),
  ];

  /// Khusus angka bulat positif/non-negatif.
  static final List<TextInputFormatter> digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  /// Khusus angka bertanda +/- (misal delta mutasi stok).
  static final List<TextInputFormatter> signedInt = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-]')),
    LengthLimitingTextInputFormatter(6),
  ];

  /// Mencegah spasi pada input email / identifier.
  static final List<TextInputFormatter> noWhitespace = [
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
  ];

  /// Format tanggal ISO `YYYY-MM-DD`.
  static final List<TextInputFormatter> isoDate = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
    LengthLimitingTextInputFormatter(10),
  ];

  /// Format kode kupon / kode booking (alfanumerik, `-`, `_`).
  static final List<TextInputFormatter> alphaNumCode = [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
    LengthLimitingTextInputFormatter(32),
  ];

  /// Kode verifikasi OTP 6 digit.
  static final List<TextInputFormatter> otpCode = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(6),
  ];
}

class SwValidators {
  const SwValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegex = RegExp(r'^(?:\+62|62|0)8[1-9][0-9]{6,11}$');

  static final RegExp _personNameAllowedRegex = RegExp(r"^[a-zA-Z\s.,'\-]+$");

  static final RegExp _isoDateRegex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static String? requiredField(String? value, [String fieldName = 'Kolom']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  /// Validasi nama orang / sanggar: wajib isi, hanya huruf & tanda baca nama
  /// yang valid, bebas angka, dan minimal mengandung 2 huruf.
  static String? personName(
    String? value, [
    String fieldName = 'Nama lengkap',
  ]) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return '$fieldName wajib diisi';
    }
    if (RegExp(r'[0-9]').hasMatch(v)) {
      return '$fieldName tidak boleh mengandung angka';
    }
    if (!_personNameAllowedRegex.hasMatch(v)) {
      return '$fieldName hanya boleh berisi huruf';
    }
    if (RegExp(r'[a-zA-Z]').allMatches(v).length < 2) {
      return '$fieldName minimal 2 huruf';
    }
    return null;
  }

  /// Validasi tanggal strict format `YYYY-MM-DD` dan kalender valid.
  static String? isoDate(String? value, [String fieldName = 'Tanggal']) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return '$fieldName wajib diisi';
    }
    final match = _isoDateRegex.firstMatch(v);
    if (match == null) {
      return 'Format $fieldName harus YYYY-MM-DD (mis. 2026-11-30)';
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime.tryParse(v);
    if (parsed == null ||
        parsed.year != year ||
        parsed.month != month ||
        parsed.day != day) {
      return '$fieldName tidak valid di kalender';
    }
    return null;
  }

  static String? intRange(
    String? value, {
    required String fieldName,
    int min = 0,
    int? max,
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return '$fieldName wajib diisi';
    }
    final parsed = int.tryParse(v);
    if (parsed == null) {
      return '$fieldName harus berupa angka bulat';
    }
    if (parsed < min) {
      return '$fieldName minimal $min';
    }
    if (max != null && parsed > max) {
      return '$fieldName maksimal $max';
    }
    return null;
  }

  static String? otpCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Kode verifikasi wajib diisi';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(v)) {
      return 'Kode verifikasi harus 6 digit angka';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? emailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email atau nomor telepon wajib diisi';
    }
    final v = value.trim();
    if (_emailRegex.hasMatch(v) || _phoneRegex.hasMatch(v.replaceAll(RegExp(r'[\s-]'), ''))) {
      return null;
    }
    // Juga dukung alias demo singkat saat dev seperti 'admin' / 'tamu'
    if (v == 'admin' || v == 'tamu' || v == 'user') {
      return null;
    }
    return 'Masukkan email atau nomor WhatsApp yang valid';
  }

  static String? phoneId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor WhatsApp wajib diisi';
    }
    final clean = value.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (!_phoneRegex.hasMatch(clean)) {
      return 'Gunakan nomor WhatsApp Indonesia yang valid (mis. 0812...)';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi wajib diisi';
    }
    if (value.length < minLength) {
      return 'Kata sandi minimal $minLength karakter';
    }
    return null;
  }
}
