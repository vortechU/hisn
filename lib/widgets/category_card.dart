import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/dua_category.dart';
import '../theme/category_visuals.dart';
import 'arabic_text.dart';

/// A tappable card summarising a dua category on the home grid.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.count,
    required this.onTap,
  });

  final DuaCategory category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visuals = CategoryVisuals.of(category.id);
    final s = AppStrings.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: visuals.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(visuals.icon, color: visuals.color, size: 24),
                  ),
                  const SizedBox(width: 8),
                  // In English the Arabic name sits here as decoration; in
                  // Arabic the name becomes the card's main title below.
                  if (!s.ar)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: ArabicText(
                          category.titleArabic,
                          fontSize: 18,
                          color: visuals.color,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              const SizedBox(height: 12),
              if (s.ar)
                ArabicText(
                  category.titleArabic,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.start,
                  height: 1.4,
                  maxLines: 2,
                )
              else
                Text(
                  category.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                s.duaCount(count),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
