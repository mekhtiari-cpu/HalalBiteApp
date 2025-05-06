// import 'package:brg_app/core/models/review.dart';
//
// extension ReviewListExtensions on List<Review> {
//   double getPercentage(int star) {
//     if (isEmpty) return 0;
//     final starCount = where((review) => review.stars == star).length;
//     return (starCount / length) * 100;
//   }
//
//   double get averageRating {
//     if (isEmpty) return 0.0;
//     double totalStars = fold(0.0, (sum, review) => sum + (review.stars ?? 0.0));
//     double avgRating = totalStars / length;
//     return double.parse(avgRating.toStringAsFixed(1));
//   }
//
//   double get percentage5Stars => getPercentage(5);
//   double get percentage4Stars => getPercentage(4);
//   double get percentage3Stars => getPercentage(3);
//   double get percentage2Stars => getPercentage(2);
//   double get percentage1Star => getPercentage(1);
// }
