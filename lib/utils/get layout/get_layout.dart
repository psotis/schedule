import 'package:flutter/material.dart';

const double mobileSize = 600;
const double tabletSize = 1300;
double? finalWidth;

double getLayout(BuildContext context) {
  double mediaQuery = MediaQuery.of(context).size.width;
  if (mobileSize < mediaQuery) {
    finalWidth = mediaQuery;
  } else {
    finalWidth = mediaQuery;
  }
  return finalWidth!;
}
