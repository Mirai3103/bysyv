import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(color: AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}
