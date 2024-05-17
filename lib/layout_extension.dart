import 'package:flutter/material.dart';

extension SizeExtension on BuildContext {
  SizedBox height(double factor) {
    return SizedBox(height: MediaQuery.of(this).size.height * factor);
  }

  SizedBox width(double factor) {
    return SizedBox(height: MediaQuery.of(this).size.width * factor);
  }

  double containerWidth(double factor) {
    return MediaQuery.of(this).size.width * factor;
  }

  double containerHeight(double factor) {
    return MediaQuery.of(this).size.height * factor;
  }
}
