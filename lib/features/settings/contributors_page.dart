import 'package:flutter/material.dart';

/// Contributors, as plain Flutter text. Taken from the contributors page of
/// the Saṃsādhanī website (version 1 showed it as a web page); the e-mail
/// addresses listed there are left out.
class ContributorsPage extends StatelessWidget {
  const ContributorsPage({super.key});

  static const _institutions = [
    'Academy of Sanskrit Research, Melkote (2002-03): the initial version of '
        'the morphological analyser.',
    'Language Technologies Research Center, IIIT Hyderabad (2002-03): noun '
        'paradigms, and porting the morphological analyser to Linux in the '
        "'Anusāraka' format.",
    'Sansk-Net Center, Rashtriya Sanskrit Vidyapeetha, Tirupati (2004-2007): '
        'students and teachers who improved the morphological analyser and '
        'supplied the paradigms.',
    'Satyam Computer Services Limited, Hyderabad (2002 - June 2006): '
        'support for the Sanskrit-Hindi Anusāraka work.',
    'University of Hyderabad (July 2006 onwards): infrastructure.',
    'DeitY, MCIT, Government of India (April 2008 - June 2012): funding for '
        'the consortium project "Development of tools for Analysis of Sanskrit '
        'texts and Sanskrit-Hindi Machine Translation System" under the TDIL '
        'programme.',
  ];

  static const _consortium = [
    'Prof. Amba Kulkarni, University of Hyderabad (leader)',
    'Prof. Girish Nath Jha, JNU, Delhi',
    'Prof. Tirumala Kulkarni, PPVP, Bengaluru',
    'Prof. S. S. Murthy, RSVP, Tirupati',
    'Prof. Veeranarayana Pandurangi, JRRSU, Jaipur',
    'Prof. Dipti Misra Sharma, IIIT Hyderabad',
    'Prof. Srinivas Varakhedi, Sanskrit Academy, Hyderabad',
    'Prof. Varalakshmi, Sanskrit Academy, Hyderabad',
  ];

  static const _scholars = [
    'Amruta Barbadikar',
    'Anilkumar: verb and derivational morphology; compound analyser',
    'Arjuna S. R.: Nyāyacitradipika',
    'Gayatri Sepuri: verb form generator',
    'Madhusoodan J. Pai: sentence generator',
    'Pankaj Vyas: sandhi joiner',
    'Monali Das: Saṅkṣepa Rāmāyaṇa e-reader, anaphora resolution',
    'Pavankumar Satuluri: Sanskrit parser; compound generator',
    'Pawan Goyal: Aṣṭādhyāyī simulator',
    'Prasanna Venkatesh: verb morphology, paradigm approach',
    'Preeti Shukl: Bhagavadgītā e-reader',
    'Saee Vaze',
    'Sanjeev Panchal: Ākāṅkṣā module',
    'Shailaja N.: Dhātupāṭha',
    'Sheeba V.: noun morphology',
    'Sheetal Pokar: Sanskrit parser',
    'Sivaja S. Nair: sandhi joiner and Amarakosha',
    'Sriram Krishnan: segmenter and parser',
    'Sushama Vempati: sandhi joiner',
  ];

  static const _postdocs = [
    'Anupama Ryali: e-reader for Śiśupālavadha',
    'Shailaja N.: Dhātupāṭha',
  ];

  static const _associates = [
    'Devanand Shukla: morph analyser; Aṣṭādhyāyī simulator',
    'Gauri: Sanskrit-Hindi MT; search engine',
    'Karunakar: search engine',
    'Kiranmayi: Sanskrit-Hindi MT',
    'Krishna Mohan: corpus maintenance',
    'Yajus Vyas: developer of START',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget heading(String t) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(t, style: theme.textTheme.titleMedium),
        );
    List<Widget> list(List<String> items) =>
        [for (final i in items) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(i))];

    return Scaffold(
      appBar: AppBar(title: const Text('Contributors')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('We thank the following institutes and individuals who '
              'have contributed to the development of Saṃsādhanī.'),
          heading('Institutions'),
          ...list(_institutions),
          heading('Consortium'),
          ...list(_consortium),
          heading('Research scholars'),
          ...list(_scholars),
          heading('Post-doctoral fellows'),
          ...list(_postdocs),
          heading('Research associates'),
          ...list(_associates),
          const SizedBox(height: 16),
          const Text('Several users and volunteers have contributed in '
              'various ways: by testing modules, suggesting corrections and '
              'improvements.'),
          heading('Sanskrit Heritage Platform'),
          // Placeholder until the Heritage team words its own section.
          const Text('[Text to come from the Sanskrit Heritage team.]'),
        ],
      ),
    );
  }
}
