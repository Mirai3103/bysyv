import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mix/mix.dart';

import '../core/theme/app_mix_theme.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class BysivApp extends ConsumerWidget {
  const BysivApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MixScope(
      colors: AppMixTheme.colors,
      spaces: AppMixTheme.spaces,
      radii: AppMixTheme.radii,
      boxShadows: AppMixTheme.boxShadows,
      child: MaterialApp.router(
        title: 'Bysiv',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
