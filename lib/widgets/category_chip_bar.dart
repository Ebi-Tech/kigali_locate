import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';

class CategoryChipBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;

  const CategoryChipBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppConstants.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = AppConstants.categories[index];
          final isAll = category == 'All';
          final isSelected =
              isAll ? selected == null : selected == category;

          return GestureDetector(
            onTap: () => onSelected(isAll ? null : category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: 1,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
