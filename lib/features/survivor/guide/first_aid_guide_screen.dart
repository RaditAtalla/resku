import 'package:flutter/material.dart';

class FirstAidGuideScreen extends StatelessWidget {
  const FirstAidGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FIRST AID GUIDE'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4.0, bottom: 12.0),
              child: Text(
                'OFFLINE EMERGENCY PROTOCOLS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: Colors.grey,
                ),
              ),
            ),
            _buildFirstAidAccordion(
              title: '1. CPR (Cardiopulmonary Resuscitation)',
              subtitle: 'For unresponsive victims with abnormal breathing',
              urgencyColor: const Color(0xFFEF4444), // Critical (Red)
              icon: Icons.heart_broken,
              steps: [
                'Ensure the scene is safe for you and the victim.',
                'Check responsiveness: Tap shoulders and shout "Are you OK?".',
                'Call for help immediately and locate any nearby responders.',
                'Start chest compressions: Place hands in the center of the chest, push down hard and fast (100–120 compressions per minute at a depth of 2 inches).',
                'Give rescue breaths: After 30 compressions, tilt the head back, pinch the nose, and deliver 2 quick breaths. Repeat this 30:2 ratio.',
              ],
              warningText: 'DO NOT stop compressions unless the victim shows signs of life or professional medical support takes over.',
            ),
            _buildFirstAidAccordion(
              title: '2. Severe Bleeding Management',
              subtitle: 'Control major blood loss using pressure and elevation',
              urgencyColor: const Color(0xFFEF4444), // Critical (Red)
              icon: Icons.bloodtype,
              steps: [
                'Protect yourself by wearing gloves if available.',
                'Apply direct pressure: Use a clean cloth or sterile gauze and press firmly directly on the wound.',
                'Maintain pressure: Keep pressing. If blood seeps through, place another cloth on top without removing the original.',
                'Elevate: Raise the wound above the level of the heart if no bone fracture is suspected.',
                'Apply tourniquet: For life-threatening extremity bleeding, apply a tight band 2-3 inches above the wound (never on a joint). Note the time it was applied.',
              ],
              warningText: 'DO NOT remove blood-soaked bandages, as this will tear the forming blood clot. Always layer new wraps on top.',
            ),
            _buildFirstAidAccordion(
              title: '3. Fractures and Splinting',
              subtitle: 'Stabilize broken bones and joint dislocations',
              urgencyColor: const Color(0xFFF59E0B), // Moderate (Amber)
              icon: Icons.personal_injury,
              steps: [
                'Control any external bleeding first with direct pressure around the injury site.',
                'Immobilize the area: Keep the injured limb completely still. Do not try to realign or push bones back in.',
                'Construct a splint: Use rigid materials (boards, rolled newspapers, sticks) placed above and below the joint.',
                'Secure the splint: Use bandages, cloth strips, or tape to secure the splint. Wrap firmly but do not cut off blood circulation.',
                'Apply cold: Apply ice wrapped in a towel to reduce swelling if available.',
              ],
              warningText: 'NEVER attempt to straighten a fractured bone yourself. Doing so can damage nerves, muscles, and blood vessels.',
            ),
            _buildFirstAidAccordion(
              title: '4. Severe Burns Treatment',
              subtitle: 'Treat heat, chemical, or electrical burns',
              urgencyColor: const Color(0xFFF59E0B), // Moderate (Amber)
              icon: Icons.local_fire_department,
              steps: [
                'Remove the heat source: Ensure the hazard is cleared.',
                'Cool the burn: Rinse the area immediately under cool (not freezing) running water for 10 to 20 minutes.',
                'Remove jewelry/restrictive clothing from the burned area before swelling starts, but do not remove stuck clothing.',
                'Cover loosely: Protect with a sterile, non-stick bandage or clean dry plastic wrap. Wrap loosely to avoid pressure.',
                'Treat shock: Lay the person flat, elevate feet if comfortable, and keep them warm.',
              ],
              warningText: 'NEVER apply butter, cooking oils, ice, or toothpaste to severe burns. These trap heat and worsen the damage.',
            ),
            _buildFirstAidAccordion(
              title: '5. Heatstroke & Dehydration',
              subtitle: 'Cooling down someone suffering from extreme heat',
              urgencyColor: const Color(0xFF10B981), // Mild (Green)
              icon: Icons.thermostat,
              steps: [
                'Move to shade: Relocate the person to a cool, air-conditioned, or shaded place immediately.',
                'Cool down rapidly: Splash or spray cool water, fan them, and apply damp cold cloths to the neck, armpits, and groin.',
                'Hydrate carefully: Offer cool water or electrolyte solution slowly, only if they are fully conscious and alert.',
                'Lay them down and elevate feet slightly to support blood flow.',
              ],
              warningText: 'DO NOT give fluids to an unconscious or vomiting person, as it poses a severe choking risk.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstAidAccordion({
    required String title,
    required String subtitle,
    required Color urgencyColor,
    required IconData icon,
    required List<String> steps,
    required String warningText,
  }) {
    return Card(
      color: const Color(0xFF1E1E2C),
      margin: const EdgeInsets.only(bottom: 14.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          brightness: Brightness.dark,
        ),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: urgencyColor, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
          ),
          childrenPadding: const EdgeInsets.all(16.0),
          expandedAlignment: Alignment.topLeft,
          children: [
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            // Step by step list
            ...List.generate(steps.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: urgencyColor, width: 1.5),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: urgencyColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        steps[index],
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            // Warning Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      warningText,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
