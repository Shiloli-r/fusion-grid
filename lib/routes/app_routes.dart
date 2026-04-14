import 'package:get/get.dart';

import './app_bindings.dart';
import '../modules/game/views/game_page.dart';
import '../modules/home/views/home_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String game = '/game';

  static final Bindings bindings = AppBindings();

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<HomePage>(
      name: home,
      page: () => const HomePage(),
    ),
    GetPage<GamePage>(
      name: game,
      page: () => const GamePage(),
      preventDuplicates: false,
    ),
  ];
}

