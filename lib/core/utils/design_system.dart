import 'package:flutter/material.dart';
import '../models/survivor_record.dart';

/// AppColors encapsulates color constants defined by the Light Mode Strava-style
/// tactical layout. Consolidating colors here prevents visual discrepancies
/// across different widgets.
class AppColors {
  AppColors._();

  static const Color orange = Color(0xFFFC5200);
  static const Color darkOrange = Color(0xFFE43F00);
  static const Color black = Color(0xFF1F1F22);
  static const Color charcoal = Color(0xFF2F2F35);
  static const Color grayBg = Color(0xFFF7F7FA);
  static const Color border = Color(0xFFE5E5E9);
  static const Color muted = Color(0xFF6D6D78);

  // Triage status color tokens
  static const Color critical = Color(0xFFE11D48); // Rose red
  static const Color injured = Color(0xFFD97706); // Amber
  static const Color safe = Color(0xFF059669); // Emerald

  // Light transparent backgrounds for status badges
  static const Color criticalBg = Color(0xFFFFE4E6);
  static const Color injuredBg = Color(0xFFFEF3C7);
  static const Color safeBg = Color(0xFFD1FAE5);

  // Light transparent borders for status badges
  static const Color criticalBorder = Color(0xFFFDA4AF);
  static const Color injuredBorder = Color(0xFFFCD34D);
  static const Color safeBorder = Color(0xFF6EE7B7);
}

/// AppTextStyles defines standard text styling guidelines for the application.
/// Using static TextStyle instances ensures typography consistency and centralizes
/// font adjustments (e.g., swapping families).
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headerLogo = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: AppColors.black,
    letterSpacing: -0.5,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 8,
    color: AppColors.muted,
    fontFamily: 'monospace',
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static const TextStyle systemTime = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    color: AppColors.muted,
    letterSpacing: 0.5,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: AppColors.black,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    color: AppColors.muted,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    color: AppColors.black,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle monospaceLabel = TextStyle(
    fontFamily: 'monospace',
    fontSize: 10,
    color: AppColors.muted,
  );

  static const TextStyle monospaceBold = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );
}

/// ReskuButton provides pre-styled buttons (primary, secondary, outlined)
/// matching the design system guidelines. Creating a single consolidated button
/// prevents UI button sprawl and simplifies styling changes.
class ReskuButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isSecondary;
  final bool isOutlined;
  final double? width;
  final double height;

  const ReskuButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.width,
    this.height = 38,
  })  : isPrimary = true,
        isSecondary = false,
        isOutlined = false;

  const ReskuButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.width,
    this.height = 38,
  })  : isPrimary = false,
        isSecondary = true,
        isOutlined = false;

  const ReskuButton.outlined({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.width,
    this.height = 38,
  })  : isPrimary = false,
        isSecondary = false,
        isOutlined = true;

  @override
  Widget build(BuildContext context) {
    Color bg, text, borderCol;
    
    if (isPrimary) {
      bg = AppColors.orange;
      text = Colors.white;
      borderCol = Colors.transparent;
    } else if (isSecondary) {
      bg = AppColors.black;
      text = Colors.white;
      borderCol = Colors.transparent;
    } else {
      bg = Colors.white;
      text = AppColors.black;
      borderCol = AppColors.border;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: text,
      elevation: 0,
      side: isOutlined ? BorderSide(color: borderCol, width: 1) : BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );

    final Widget childContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: onPressed,
        child: childContent,
      ),
    );
  }
}

/// ReskuCard implements the standard 'strava-card' aesthetics from the PRD,
/// utilizing a flat container with border lines, clean border radii, and 
/// subtle drop shadow. It also supports rendering a colored vertical accent
/// bar on its left side.
class ReskuCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;

  const ReskuCard({
    super.key,
    required this.child,
    this.accentColor,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (accentColor != null)
              Container(
                width: 5,
                color: accentColor,
              ),
            Expanded(
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ReskuBadge renders triage status tags with matching background, border,
/// and text colors dynamically. Exposing this as a reusable component keeps
/// badge styling unified across both map tooltips, table lists, and detail dialogs.
class ReskuBadge extends StatelessWidget {
  final SurvivorStatus status;

  const ReskuBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, text, border;
    
    switch (status) {
      case SurvivorStatus.critical:
        bg = AppColors.criticalBg;
        text = AppColors.critical;
        border = AppColors.criticalBorder;
        break;
      case SurvivorStatus.injured:
        bg = AppColors.injuredBg;
        text = AppColors.injured;
        border = AppColors.injuredBorder;
        break;
      case SurvivorStatus.safe:
        bg = AppColors.safeBg;
        text = AppColors.safe;
        border = AppColors.safeBorder;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// ReskuTextField wraps input fields and packages the character limit UI logic,
/// transition borders, and label counts in one place. It prevents duplicative
/// code when implementing input console boards.
class ReskuTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxCount;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;

  const ReskuTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxCount = 160,
    this.onChanged,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final currentLength = value.text.length;
        final isOverLimit = currentLength > maxCount;

        return Stack(
          children: [
            TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 12, color: AppColors.black),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Color(0xFFD0D0D5), fontSize: 11),
                contentPadding: EdgeInsets.only(
                  left: prefixIcon != null ? 36 : 10,
                  right: 10,
                  top: 10,
                  bottom: 24, // extra bottom padding for character count indicator
                ),
                prefixIcon: prefixIcon != null
                    ? Icon(prefixIcon, color: AppColors.muted, size: 18)
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.orange),
                ),
                isDense: true,
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Text(
                '$currentLength / $maxCount',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                  color: isOverLimit ? Colors.red : AppColors.muted,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ReskuToast renders a floating notification alert at the top of the interface.
/// Wrapping this ensures that popup announcements align with the primary theme colors.
class ReskuToast extends StatelessWidget {
  final String text;
  final IconData icon;

  const ReskuToast({
    super.key,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.charcoal),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.orange, size: 16),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// ReskuModal delivers the popup dialog detailing survivor needs, coordinates,
/// and dispatch buttons with backdrop integration. Wrapping this modal guarantees
/// layout coherence and avoids duplicative modal layout routines.
class ReskuModal extends StatelessWidget {
  final String name;
  final SurvivorStatus status;
  final String lastUpdate;
  final String coordinates;
  final String needs;
  final VoidCallback onDismiss;
  final VoidCallback onDeploy;

  const ReskuModal({
    super.key,
    required this.name,
    required this.status,
    required this.lastUpdate,
    required this.coordinates,
    required this.needs,
    required this.onDismiss,
    required this.onDeploy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ReskuBadge(status: status),
                      ],
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, color: AppColors.muted, size: 20),
                    onPressed: onDismiss,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildModalRow('Last Update:', lastUpdate),
              const SizedBox(height: 8),
              _buildModalRow(
                'Coordinates:',
                coordinates,
                valueColor: AppColors.orange,
                fontFamily: 'monospace',
              ),
              const SizedBox(height: 8),
              const Text(
                'REPORTED NEEDS:',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.muted,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.grayBg,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  needs,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onDismiss,
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onDeploy,
                      child: const Text(
                        'Deploy Team',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value, {Color? valueColor, String? fontFamily}) {
    return Row(
      children: [
        Text(
          '${label.toUpperCase()} ',
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.muted,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.black,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ],
    );
  }
}
