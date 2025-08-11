class ApiConfig {


  static const String baseUrl = "https://enzopik.thikse.in/api";
  static const String aiBaseUrl = "https://ai.thikse.in/api";

  static const String login = "$baseUrl/auth/login";
  static const String resetPassword = "$baseUrl/auth/reset-password";
  static const String logout = "$baseUrl/auth/logout";
  static const String getCpHome = "$baseUrl/get-cp-home";
  static const String getOrderDetails = "$baseUrl/get-order-details";
  static const String addVoucher = "$baseUrl/add-voucher";
  static const String SaveFcmToken = "$baseUrl/save-fcm-token";
  static const String fboAll = "$baseUrl/fbo/all";
  static const String getNewFbo = "$baseUrl/get-new-fbo";
  static const String nearestOrders = "$baseUrl/nearest-order";
  static const String getRejectedFbo = "$baseUrl/get-rejected-fbo";
  static const String getNotification = "$baseUrl/get-notifications";
  static const String getAllCompletedOrders = "$baseUrl/get-all-completed-orders";
  static const String requestRegisteredFbo = "$baseUrl/request-registered-fbo";
  static const String AllAgent = "$baseUrl/agent/all";
  static const String chatBot = "$baseUrl/chatbot";
  static const String DownloadAcknowledgedVoucher = "$baseUrl/download-acknowledged-voucher";
  static String downloadPdf(String type, int userId) => "$baseUrl/download$type/$userId";
  static String fboApproval(int fboId) => "$baseUrl/fbo-approval/$fboId";
  static String updateOilSale(int orderId) => "$baseUrl/update-oil-sale/$orderId";
  static String getOilSale(String userId) => "$baseUrl/get-oil-sale/$userId";
  static String getMonthlyOilSale(String userId, int month) => "$baseUrl/get-monthly-oil-sale/$userId/$month";
  static const String getUserOilCompleted = "$baseUrl/get-user-oil-completed-sale";
  static const String RequestOil = "$baseUrl/users/request-oil";
  static const String register = "$baseUrl/register";
  static const String sendOtp = "$baseUrl/send-otp";
  static const String verifyOtp = "$baseUrl/verify-otp";
  static const String getProfileData = "$baseUrl/get-profile-data";
  static const String AddFeedback = "$baseUrl/add-feedback";
  static const String getRange = "$baseUrl/get-range";
  static const String getUnitPrice = "$baseUrl/get-unit-price";
  static const String ChangePassword = "$baseUrl/auth/change-password";
  static const String UpdateProfile = "$baseUrl/profile/update";
  static const String CancelOilOrder = "$baseUrl/cancel-oil-sale";
  static String getVendorRejectedOrders(String vendorId) => "$baseUrl/get-vendor-rejected-orders/$vendorId";
  static String getFboAddress(String userId) => "$baseUrl/fbo/getaddress/$userId";
  static String getVendorAssignedSale(String vendorId) => "$baseUrl/get-vendor-assigned-sale/$vendorId";
  static const String verifyAddressRadius = "$aiBaseUrl/distance_calculation";
  static const String get_nearest_vendors = "$baseUrl/get-nearest-vendors";
  static const String new_agent = "$baseUrl/get-new-vendor";
  static String vendorApproval(int id) => "$baseUrl/vendor-approval/$id";
  static String fbo_contract_pdf(int id) => "$baseUrl/downloadcontract/$id";
}
