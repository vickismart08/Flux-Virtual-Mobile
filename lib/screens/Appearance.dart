import 'package:flutter/material.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/main.dart'; 

class Appearance extends StatefulWidget {
  const Appearance({super.key});

  @override
  State<Appearance> createState() => _AppearanceState();
}

class _AppearanceState extends State<Appearance> {
  final List<_ModeOption> _options = [
    _ModeOption(
      mode: ThemeMode.light,
      label: 'Light',
      subtitle: 'Classic bright interface',
      icon: Icons.light_mode_outlined,
    ),
    _ModeOption(
      mode: ThemeMode.dark,
      label: 'Dark',
      subtitle: 'Easy on the eyes at night',
      icon: Icons.dark_mode_outlined,
    ),
    _ModeOption(
      mode: ThemeMode.system,
      label: 'System default',
      subtitle: 'Follows your device setting',
      icon: Icons.phone_android_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text(
            'Theme',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: List.generate(_options.length, (index) {
                final option = _options[index];
                final isLast = index == _options.length - 1;
                final isSelected = themeNotifier.mode == option.mode;

                return Column(
                  children: [
                    ListTile(
                      onTap: () {
                        themeNotifier.setMode(option.mode);
                        setState(() {});
                      },
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.softOrange.withOpacity(0.15)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          option.icon,
                          size: 20,
                          color: isSelected
                              ? AppColors.softOrange
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                        ),
                      ),
                      title: Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        option.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.45),
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.softOrange,
                              size: 22,
                            )
                          : Icon(
                              Icons.circle_outlined,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.25),
                              size: 22,
                            ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 72,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.08),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeOption {
  final ThemeMode mode;
  final String label;
  final String subtitle;
  final IconData icon;

  const _ModeOption({
    required this.mode,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}