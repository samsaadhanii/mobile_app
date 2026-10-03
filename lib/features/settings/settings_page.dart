import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../home/recent_inputs.dart';
import '../tools/tool_entries.dart';
import 'about_page.dart';
import 'contributors_page.dart';

/// Settings (`SCREENS.md` section 6), then About and Contributors.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _ChoiceTile<InputScriptSetting>(
            title: 'Input script',
            value: s.inputScript,
            options: InputScriptSetting.values,
            label: (v) => v.label,
            onChanged: s.setInputScript,
          ),
          _ChoiceTile<DisplayScriptSetting>(
            title: 'Display script',
            value: s.displayScript,
            options: DisplayScriptSetting.values,
            label: (v) => v.label,
            onChanged: s.setDisplayScript,
          ),
          _ChoiceTile<LabelLanguage>(
            title: 'Grammar labels',
            value: s.labelLanguage,
            options: LabelLanguage.values,
            label: (v) => v.label,
            onChanged: s.setLabelLanguage,
          ),
          _ChoiceTile<EngineId>(
            title: 'Preferred engine',
            value: s.preferredEngine,
            options: EngineId.values,
            label: (v) => engineNames[v]!,
            onChanged: s.setPreferredEngine,
          ),
          SwitchListTile(
            title: const Text('Keep recent inputs'),
            subtitle: const Text('Stored on this phone only'),
            value: s.keepRecentInputs,
            onChanged: (keep) {
              s.setKeepRecentInputs(keep);
              // "Don't keep" also forgets what was kept.
              if (!keep) context.read<RecentInputs>().clear();
            },
          ),
          ListTile(
            title: const Text('Clear recent inputs'),
            onTap: () => context.read<RecentInputs>().clear(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AboutPage())),
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Contributors'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const ContributorsPage())),
          ),
        ],
      ),
    );
  }
}

/// A setting with a few values: the current one under the title, a dialog to
/// change it.
class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.value,
    required this.options,
    required this.label,
    required this.onChanged,
  });

  final String title;
  final T value;
  final List<T> options;
  final String Function(T) label;
  final Future<void> Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(label(value)),
      onTap: () async {
        final picked = await showDialog<T>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(title),
            children: [
              for (final o in options)
                ListTile(
                  title: Text(label(o)),
                  trailing: o == value ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, o),
                ),
            ],
          ),
        );
        if (picked != null) await onChanged(picked);
      },
    );
  }
}
