import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../settings/cubit/settings_cubit.dart';

/// Opens the reader settings sheet.
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reader settings', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: state.showAuthenticOnly,
                  onChanged: cubit.setShowAuthenticOnly,
                  title: const Text('Sahih & Hasan only'),
                  subtitle: const Text(
                    'Hide weak (da\'if) narrations for casual reading',
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text('Arabic text size', style: theme.textTheme.titleSmall),
                Row(
                  children: [
                    const Icon(Icons.text_decrease_rounded),
                    Expanded(
                      child: Slider(
                        value: state.arabicFontScale,
                        min: 0.8,
                        max: 2.0,
                        divisions: 12,
                        label: '${(state.arabicFontScale * 100).round()}%',
                        onChanged: cubit.setArabicFontScale,
                      ),
                    ),
                    const Icon(Icons.text_increase_rounded),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fully offline. No accounts, no ads, no tracking.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
