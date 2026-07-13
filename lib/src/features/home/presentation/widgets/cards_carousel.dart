import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

/// Simple mock model for a payment card. Ready to be swapped with a
/// backend-provided entity once the Rust API is wired.
class BankCardData {
  const BankCardData({
    required this.holder,
    required this.last4,
    required this.expiry,
    required this.brand,
    this.isPrimary = false,
  });

  final String holder;
  final String last4;
  final String expiry; // MM/YY
  final String brand;
  final bool isPrimary;
}

/// Horizontally scrollable list of the user's cards with an add card CTA.
class CardsCarousel extends StatelessWidget {
  const CardsCarousel({
    super.key,
    required this.cards,
    this.onCardTap,
    this.onAddCard,
  });

  final List<BankCardData> cards;
  final ValueChanged<BankCardData>? onCardTap;
  final VoidCallback? onAddCard;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w),
        itemCount: cards.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: AppSpacing.sm.w),
        itemBuilder: (context, index) {
          if (index == cards.length) {
            return _AddCardTile(onTap: onAddCard);
          }
          final card = cards[index];
          return _BankCardTile(
            card: card,
            onTap: onCardTap == null ? null : () => onCardTap!(card),
          );
        },
      ),
    );
  }
}

class _BankCardTile extends StatelessWidget {
  const _BankCardTile({required this.card, this.onTap});

  final BankCardData card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final onCard = cs.onPrimary;

    return SizedBox(
      width: 280.w,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorders.lg,
          child: Inj(
            padding: EdgeInsets.all(AppSpacing.md.w),
            decoration: BoxDecoration(
              borderRadius: AppBorders.lg,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.secondary,
                  Color.alphaBlend(
                    cs.primary.withValues(alpha: 0.6),
                    cs.secondary,
                  ),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      card.brand,
                      style: tt.titleMedium?.copyWith(
                        color: onCard,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    if (card.isPrimary)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: onCard.withValues(alpha: 0.15),
                          borderRadius: AppBorders.xs,
                        ),
                        child: Text(
                          'home.primary'.tr(),
                          style: tt.labelSmall?.copyWith(
                            color: onCard,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  '•••• •••• •••• ${card.last4}',
                  style: tt.titleMedium?.copyWith(
                    color: onCard,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'home.card_holder'.tr(),
                            style: tt.labelSmall?.copyWith(
                              color: onCard.withValues(alpha: 0.75),
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            card.holder.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(
                              color: onCard,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'home.valid_thru'.tr(),
                          style: tt.labelSmall?.copyWith(
                            color: onCard.withValues(alpha: 0.75),
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          card.expiry,
                          style: tt.bodyMedium?.copyWith(
                            color: onCard,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddCardTile extends StatelessWidget {
  const _AddCardTile({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    return SizedBox(
      width: 160.w,
      child: DottedBorderBox(
        color: cs.outline,
        borderRadius: AppBorders.lg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppBorders.lg,
            onTap: onTap,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconsaxPlusLinear.add_circle,
                    size: 32.sp,
                    color: cs.primary,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'home.add_card'.tr(),
                    style: tt.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lightweight dashed-outline container used by the "Add card" tile so we
/// do not need to pull in an external dashed-border package.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    super.key,
    required this.child,
    required this.color,
    required this.borderRadius,
  });

  final Widget child;
  final Color color;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, borderRadius: borderRadius),
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    final path = Path()..addRRect(rrect);

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderRadius != borderRadius;
}
