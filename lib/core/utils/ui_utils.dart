import 'package:flutter/material.dart';

class UIUtils {
  static late double screenWidth;
  static late double screenHeight;
  static late double statusBarHeight;
  static late double bottomBarHeight;

  static void init(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    statusBarHeight = MediaQuery.of(context).padding.top;
    bottomBarHeight = MediaQuery.of(context).padding.bottom;
  }
}
