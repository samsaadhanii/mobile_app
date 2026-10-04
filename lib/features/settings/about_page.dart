import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/app_wordmark.dart';

/// About: both teams, versions and licences, as plain Flutter text.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = 'Version ${info.version} (build ${info.buildNumber})');
      }
    }).catchError((_) {
      // No version to show; the rest of the page does not depend on it.
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget heading(String t) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(t, style: theme.textTheme.titleMedium),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppWordmark(size: 28),
          if (_version != null) Text(_version!),
          heading('Saṃsādhanī'),
          const Text(
            'Saṃsādhanī is a computational platform developed at the '
            'Department of Sanskrit Studies, University of Hyderabad, for '
            'Sanskrit language processing. It hosts several computational '
            'tools such as a morphological analyser, a morphological '
            'generator, sandhi analysis and generation modules, and a '
            'dependency parser and Sanskrit-Hindi machine translation '
            'system.',
          ),
          const SizedBox(height: 8),
          const Text('Copyright © Amba Kulkarni and the Saṃsādhanī team. '
              'Licensed under the GNU General Public License.'),
          heading('Sanskrit Heritage Platform'),
          // Placeholder: the Heritage team words its own credit (Heritage Q28).
          const Text('[Text to come from the Sanskrit Heritage team.]'),
          heading('Data'),
          const Text('The Dhātupāṭha concordance data is by N. Shailaja and '
              'Amba Kulkarni, under the Creative Commons '
              'Attribution-ShareAlike 3.0 licence.'),
          heading('Licences'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: const Text('Open source licences'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const LicenceTextPage())),
          ),
        ],
      ),
    );
  }
}

/// The licence text bundled with the app (`assets/LICENSE`).
class LicenceTextPage extends StatelessWidget {
  const LicenceTextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open source licences')),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/LICENSE'),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('The licence text could not be loaded.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(snapshot.data!),
          );
        },
      ),
    );
  }
}
