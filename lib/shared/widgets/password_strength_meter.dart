import 'package:bookhaven/core/constants/app_colors.dart';
import 'package:bookhaven/core/constants/app_dimens.dart';
import 'package:flutter/material.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const new({super.key, required this.password});

  final String password;

  int get _score {
    var s = 0;
    if (password.length >= 8) s++;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      s++;
    }
    if (RegExp(r'\d').hasMatch(password)) s++;
    if (RegExp('[^A-Za-z0-9]').hasMatch(password)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final score = _score;
    const labels = ['Too weak', 'Weak', 'Fair', 'Good', 'Strong'];
    final color = score <= 1
        ? scheme.error
        : score == 2
        ? AppColors.lightAccent
        : scheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.sm),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 4,
                    margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: i < score
                          ? color
                          : scheme.onSurface.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Text(
            labels[score],
            style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
          )
        ],
      ),
    );
  }
}
