import 'package:flutter/material.dart';

extension SizeUtility on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;
  double get halfWidth => MediaQuery.sizeOf(this).width / 2;
  double get halfHeight => MediaQuery.sizeOf(this).height / 2;
  double percentWidth(double percentage) =>
      MediaQuery.sizeOf(this).width * (percentage / 100);
  double percentHeight(double percentage) =>
      MediaQuery.sizeOf(this).height * (percentage / 100);
}
