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
  final String message; // Raw text message description
  final bool isAnalyzing;
  final VoidCallback? onAiTriage;
  final SurvivorStatus? aiSuggestedStatus;
  final String? aiSuggestedNeeds;
  final VoidCallback? onApplyAiTriage;
  final VoidCallback onDismiss;
  final VoidCallback onDeploy;

  const ReskuModal({
    super.key,
    required this.name,
    required this.status,
    required this.lastUpdate,
    required this.coordinates,
    required this.needs,
    required this.message,
    this.isAnalyzing = false,
    this.onAiTriage,
    this.aiSuggestedStatus,
    this.aiSuggestedNeeds,
    this.onApplyAiTriage,
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
              const SizedBox(height: 12),
              
              // Survivor Message Section
              const Text(
                'SURVIVOR MESSAGE:',
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.grayBg,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  message.isEmpty ? 'No text description provided by survivor.' : '"$message"',
                  style: TextStyle(
                    color: message.isEmpty ? AppColors.muted : AppColors.black,
                    fontSize: 11,
                    fontStyle: message.isEmpty ? FontStyle.italic : FontStyle.normal,
                    height: 1.35,
                  ),
                ),
              ),

              // AI Triage Section
              if (message.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (isAnalyzing) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.grayBg,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        LinearProgressIndicator(
                          color: AppColors.orange,
                          backgroundColor: AppColors.border,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Analyzing text via local Qwen 2.5 SLM...',
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: 'monospace',
                            color: AppColors.muted,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else if (aiSuggestedStatus != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.injuredBg.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.injuredBorder, width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.auto_awesome, color: AppColors.injured, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'AI TRIAGE SUGGESTIONS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.injured,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Urgency: ', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                            ReskuBadge(status: status),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, size: 10, color: AppColors.muted),
                            const SizedBox(width: 4),
                            ReskuBadge(status: aiSuggestedStatus!),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Needs:   ', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                            Expanded(
                              child: Text(
                                '${needs.isEmpty ? "None" : needs}  ➔  ${aiSuggestedNeeds!.isEmpty ? "None" : aiSuggestedNeeds}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ReskuButton.secondary(
                          label: 'Apply AI Suggestions',
                          icon: Icons.check,
                          height: 28,
                          onPressed: onApplyAiTriage,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ReskuButton.outlined(
                    label: 'Run AI Triage (Qwen SLM)',
                    icon: Icons.auto_awesome,
                    height: 32,
                    onPressed: onAiTriage,
                  ),
                ],
              ],

              const SizedBox(height: 12),
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
                  needs.isEmpty ? 'No needs specified.' : needs,
                  style: TextStyle(
                    color: needs.isEmpty ? AppColors.muted : AppColors.black,
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

/// ReskuCentroidModal delivers the popup dialog detailing cluster-wide needs,
/// sub-graph components, and the bulk supply drop deployment button.
class ReskuCentroidModal extends StatelessWidget {
  final String centroidName;
  final int totalSurvivors;
  final Map<String, int> aggregateNeeds;
  final List<String> survivorNames;
  final VoidCallback onDismiss;
  final VoidCallback onDeployBulk;

  const ReskuCentroidModal({
    super.key,
    required this.centroidName,
    required this.totalSurvivors,
    required this.aggregateNeeds,
    required this.survivorNames,
    required this.onDismiss,
    required this.onDeployBulk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Container(
          width: 340,
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.inventory_2, color: AppColors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'CENTROID LOGISTICS HUB',
                        style: AppTextStyles.cardTitle,
                      ),
                    ],
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
              
              Row(
                children: [
                  const Text('CENTROID NODE: ', style: AppTextStyles.monospaceLabel),
                  Text(centroidName, style: AppTextStyles.bodyBold),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('TOTAL POPULATION: ', style: AppTextStyles.monospaceLabel),
                  Text('$totalSurvivors active survivors', style: AppTextStyles.bodyBold),
                ],
              ),
              const SizedBox(height: 12),

              // Aggregated Supply Needs Section
              const Text(
                'AGGREGATED SUPPLY NEEDS:',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.muted,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.grayBg,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: aggregateNeeds.isEmpty
                    ? const Text(
                        'No specific resource needs requested by cluster survivors.',
                        style: TextStyle(color: AppColors.muted, fontSize: 11, fontStyle: FontStyle.italic),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: aggregateNeeds.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: AppTextStyles.bodyRegular,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'x${entry.value}',
                                    style: AppTextStyles.monospaceBold.copyWith(
                                      color: AppColors.orange,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 12),

              // Cluster Members
              const Text(
                'CLUSTER SURVIVOR LIST:',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.muted,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 60,
                child: SingleChildScrollView(
                  child: Text(
                    survivorNames.join(', '),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                      height: 1.35,
                    ),
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
                        'Cancel',
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
                      onPressed: onDeployBulk,
                      child: const Text(
                        'Deploy Bulk Drop',
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
}
