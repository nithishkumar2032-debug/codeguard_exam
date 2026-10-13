import 'package:flutter/material.dart';

/// Screen size classification for responsive web layouts.
enum DeviceScreenType { mobile, tablet, desktop }

/// Reusable utility widget providing responsive layout switching.
///
/// Ensures layout components adapt smoothly between smartphones, tablets,
/// laptops, and large monitor displays.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceScreenType screenType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  static DeviceScreenType getDeviceType(MediaQueryData mediaQuery) {
    final double width = mediaQuery.size.width;
    if (width >= 1024) {
      return DeviceScreenType.desktop;
    } else if (width >= 600) {
      return DeviceScreenType.tablet;
    } else {
      return DeviceScreenType.mobile;
    }
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenType = getDeviceType(mediaQuery);
    return builder(context, screenType);
  }
}
