class AppRoutes {
  const AppRoutes._();

  // Root & Auth
  static const String root = '/';
  static const String login = '/login';
  static const String adminLogin = '/admin/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // User App
  static const String userDashboard = '/dashboard';
  static const String userGallery = '/galeri';
  static const String userGalleryDetail = '/galeri/:id';
  static const String userCostumes = '/kostum';
  static const String userCostumeDetail = '/kostum/:id';
  static const String userBooking = '/pesan';
  static const String userBookingSuccess = '/pesan/sukses/:id';
  static const String userSchedule = '/jadwal';
  static const String userScheduleDaily = '/jadwal/harian';
  static const String userScheduleToday = '/jadwal/hari-ini';
  static const String userProfile = '/profil';

  // Public & Education
  static const String about = '/tentang';
  static const String aboutHistory = '/tentang/sejarah';
  static const String aboutCurators = '/tentang/kurator';
  static const String blog = '/warta';
  static const String blogDetail = '/warta/:slug';

  // Admin / Curator Panel
  static const String adminDashboard = '/admin/dashboard';
  static const String adminGallery = '/admin/galeri';
  static const String adminGalleryCreate = '/admin/galeri/baru';
  static const String adminCategories = '/admin/kategori';
  static const String adminCostumes = '/admin/kostum';
  static const String adminOrders = '/admin/pesanan';
  static const String adminPos = '/admin/loket';
  static const String adminEvents = '/admin/acara';
  static const String adminCoupons = '/admin/kupon';
  static const String adminReviews = '/admin/ulasan';
  static const String adminVisitors = '/admin/kunjungan';
  static const String adminUsers = '/admin/pengguna';
  static const String adminAudit = '/admin/audit';
  static const String adminSettings = '/admin/pengaturan';
  static const String adminDocs = '/admin/docs';

  static String galleryDetailPath(String id) => '/galeri/$id';
  static String costumeDetailPath(String id) => '/kostum/$id';
  static String bookingSuccessPath(String id) => '/pesan/sukses/$id';
  static String blogDetailPath(String slug) => '/warta/$slug';
  static String userProfileWithTab(String tab) =>
      '$userProfile?tab=${Uri.encodeComponent(tab)}';

  static bool isAuthRequiredForUser(String location) {
    return location.startsWith(userBooking) || location.startsWith(userProfile);
  }
}
