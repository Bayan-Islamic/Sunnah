import 'package:flutter/material.dart';

import '../../../../core/models/book.dart';

/// One collection row on the home screen.
class BookTile extends StatelessWidget {
  const BookTile({super.key, required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.nameAr,
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.nameEn,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${book.author} · ${book.totalHadiths} hadiths',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: theme.textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
