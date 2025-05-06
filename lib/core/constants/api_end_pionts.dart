// ignore_for_file: constant_identifier_names

class EndPoints {
  static const baseUrl = 'https://brg.shahfahad.info/api/v1'; // Global IP

  ///
  /// used ones
  ///
  static const signup = '/auth/register';
  static const login = '/auth/login';
  static const forgotPassword = '/auth/forgot-password';
  static const getUser = "/auth/get/user";
  static const ressetpass = "/auth/reset-password";
  static const verifyOtp = "/auth/verify-code";
  static const getCategories = "/businesses/shop/categories";
  static const getFeaturedBusiness = "/booster/bussines";
  static const getFeaturedProducts = "/booster/products";
  static String getRestaurantProducts(String id) =>
      "/businesses/$id/products/list";
  static const getAllReviews = "/businesses/review";
  static const addReview = "/businesses/review";
  static const getAllFavouriteProducts = '/favourite/customer/products';
  static const getAllFavouriteRestaurants = '/favourite/customer/bussiness';
  static String getRestaurantSubscriptionPlan(String id) =>
      "/subsctiption-plan/list/bussiness/$id";
  static const postCustomOrder = "/rider/custom-pickup";
  static const favouriteApiURL = '/favourite';
  static const scheduleOrder = '/schedule-orders/bulk';
  static String customerOrders(String id) => '/orders/user/$id';
  static const customerPlanOrders = '/subsctiption-plan/user-subscriptions';
  static const getNormalItems = "/businesses/products/customer/list";
  static const addToCart = "/businesses/products/cart";
  static const getCart = "/businesses/products/cart";
  static String updateCart(String id) => "/businesses/products/cart/$id";
  static String deleteCartItem(String id) => "/businesses/products/cart/$id";
  static const checkoutOrder = "/orders/bulk";
  static const getBasePrice = "/rider/price";
  static const getSessionByuserId = "/card-info/get";
  static const customerPlanOrder = "/orders";
  static const userSubscriptionList = "/subsctiption-plan/list/admin";
  static const customerFaqs = "/faqs";
  static const buyUserSubscription = "/subsctiption-plan/buy";
  static String updateOrderStatus(String id) => "/orders/order_status/$id";
  static const userPlanSubscription = '/subsctiption-plan/user-subscriptions';
  static String removeFavourite(String id) => "/favourite/$id";
  static const customerAnalytics = '/analytics/customer';
  static String getCategoryProducts(String id) =>
      "/businesses/products/list/$id";
  static const getCustomerOrderHistory = "/orders/history/all";
  static const getConversations = "/chat/latest-chats";
  static const getMessages = "/chat/user-chat";
  static const getCouponList = "/businesses/coupon";
  static const getCouponByCouponCode = "/businesses/coupon/code/";
  static const getVouchers = '/voucher';
  static const getBusinessList = "/businesses/list";
  static const updateProfile = "/auth/user/update";
  static const getAddress = "/auth/customer/address";
  static String deleteAddress(String id) => "/auth/customer/address/$id";
  static String updateAddress(String id) => "/auth/customer/address/$id";
  static String applyVoucher(String id) => "/voucher/active/$id";
  static const addNewAddress = "/auth/customer/address";
  static const getCustomerOffer = "/rider/notifications";
  static const acceptOrder = "/rider/notification/true";
  static const riderAnalytics = "/analytics/rider";
  static String addComplaint(String id) => "/rider/order/review/$id";
  static const dispatchOrder = "/rider/order/dispatch";
  static const deliverdOrder = "/rider/order/delivered";
  static const changePassword = "/auth/change-password";
  static String riderDeliveries (String id) => "/rider/specific-rider-deliveries/$id";
  static const getNotification = "/notifications";
  static const getAdvertisment = "/banners";
  static const customPickupOrder = "/rider/get-custom-pickup";
  static const socialLogin = "/auth/social-login";
  static const deviceToken = "/auth/user/fcm-token";
}
