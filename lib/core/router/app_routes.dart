class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const adminDashboard = '/admin';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const bookList = '/books';

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
}
