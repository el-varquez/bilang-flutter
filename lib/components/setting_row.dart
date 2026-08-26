import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_switch.dart';

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.name,
    required this.help,
    required this.value,
    this.onChanged,
  });

  final String name;
  final String help;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Tokens.surface2,
          borderRadius: BorderRadius.circular(Tokens.radiusControl),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: Tokens.uiFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    help,
                    style: const TextStyle(
                      fontFamily: Tokens.uiFont,
                      fontSize: 13,
                      color: Tokens.ink3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            AppSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
