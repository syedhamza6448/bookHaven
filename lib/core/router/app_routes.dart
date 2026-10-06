class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const adminDashboard = '/admin';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const bookList = '/books';
  static const bookDetails = '/book/:id';
  static const categories = '/categories';
  static const search = '/search';
  static const cart = '/cart';
  static const wishlist = '/wishlist';
  static const profile = '/profile';
  static const checkout = '/checkout';
  static const orderSuccess = '/order-success/:id';
  static const editProfile = '/edit-profile';
  static const addresses = '/addresses';
  static const paymentMethods = '/payment-methods';

  static String bookListPath({
    String? title,
    String? genreId,
    String? authorId,
    String? sort,
  }) {
    final params = <String, String>{
      if (title != null) 'title': title,
      if (genreId != null) 'genre': genreId,
      if (authorId != null) 'author': authorId,
      if (sort != null) 'sort': sort,
    };
    return Uri(
      path: bookList,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }

  static String bookDetailsPath(String id, {String? heroTag}) => heroTag == null
      ? '/book/$id'
      : '/book/$id?hero=${Uri.encodeQueryComponent(heroTag)}';

  static String searchPath({String? query, String? genreId}) {
    final params = <String, String>{
      if (query != null && query.isNotEmpty) 'q': query,
      if (genreId != null && genreId.isNotEmpty) 'genre': genreId,
    };
    return Uri(
      path: search,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }

  static String orderSuccessPath(String id, {String? number}) => Uri(
    path: '/order-success/$id',
    queryParameters: {if (number != null) 'n': number},
  ).toString();
}
