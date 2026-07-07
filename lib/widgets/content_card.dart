import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/content_item.dart';
import 'package:intl/intl.dart';

class ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onTap;
  const ContentCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.category != null && item.category!.isNotEmpty)
                      Text(
                        item.category!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (item.date != null)
                          Text(
                            DateFormat('d MMM y', 'fr_FR').format(item.date!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.date != null && item.author != null) const Text(' • ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        if (item.author != null && item.author!.isNotEmpty)
                          Expanded(
                            child: Text(
                              item.author!,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(item.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.article_rounded, color: colorScheme.primary))
                    : Icon(Icons.article_rounded, color: colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContentCardShimmer extends StatelessWidget {
  const ContentCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        child: Container(height: 120),
      ),
    );
  }
}
