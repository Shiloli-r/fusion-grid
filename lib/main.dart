import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/theme/fusion_theme.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const FusionApp());
}

class FusionApp extends StatelessWidget {
  const FusionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Fusion Grid',
      debugShowCheckedModeBanner: false,
      theme: FusionTheme.dark(),
      initialRoute: AppRoutes.home,
      initialBinding: AppRoutes.bindings,
      getPages: AppRoutes.pages,
    );
  }
}
