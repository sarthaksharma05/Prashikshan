import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_palette.dart';
import '../utils/domain_data.dart';

/// Horizontal scrollable domain filter chip row.
/// First chip is always "All". Remaining chips come from kDomains.
class DomainFilterRow extends StatelessWidget {
  const DomainFilterRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'All', 'icon': Icons.apps},
      ...kDomains,
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = items[i];
          final label = item['label'] as String;
          final icon = item['icon'] as IconData;
          final isSel = selected == label;
          return GestureDetector(
            onTap: () => onSelected(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? AppPalette.pureWhite : AppPalette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSel ? AppPalette.pureWhite : AppPalette.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14,
                      color: isSel ? Colors.black : AppPalette.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSel ? Colors.black : AppPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
