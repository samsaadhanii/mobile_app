/// Devanagari <-> WX. Plain Dart, no Flutter.
///
/// Not covered, so passed through unchanged: nukta (U+093C) and the
/// precomposed nukta letters, Vedic accents, the daṇḍa and double daṇḍa
/// (U+0964, U+0965), and every other character outside the tables.
library;

const _virama = '्';
const _zwj = '‍';
const _zwnj = '‌';

const _consonants = {
  'क': 'k', 'ख': 'K', 'ग': 'g', 'घ': 'G', 'ङ': 'f',
  'च': 'c', 'छ': 'C', 'ज': 'j', 'झ': 'J', 'ञ': 'F',
  'ट': 't', 'ठ': 'T', 'ड': 'd', 'ढ': 'D', 'ण': 'N',
  'त': 'w', 'थ': 'W', 'द': 'x', 'ध': 'X', 'न': 'n',
  'प': 'p', 'फ': 'P', 'ब': 'b', 'भ': 'B', 'म': 'm',
  'य': 'y', 'र': 'r', 'ल': 'l', 'ळ': 'lY', 'व': 'v',
  'श': 'S', 'ष': 'R', 'स': 's', 'ह': 'h',
};

const _independentVowels = {
  'अ': 'a', 'आ': 'A', 'इ': 'i', 'ई': 'I', 'उ': 'u', 'ऊ': 'U',
  'ऋ': 'q', 'ॠ': 'Q', 'ऌ': 'L', 'ए': 'e', 'ऐ': 'E', 'ओ': 'o', 'औ': 'O',
};

const _vowelSigns = {
  'ा': 'A', 'ि': 'i', 'ी': 'I', 'ु': 'u', 'ू': 'U',
  'ृ': 'q', 'ॄ': 'Q', 'ॢ': 'L', 'े': 'e', 'ै': 'E', 'ो': 'o', 'ौ': 'O',
};

const _signs = {
  'ं': 'M', 'ः': 'H', 'ँ': 'z', 'ऽ': 'Z', 'ॐ': 'oM',
};

const _digits = '०१२३४५६७८९';

final _wxConsonants = {
  for (final e in _consonants.entries) e.value: e.key,
};
final _wxVowelsIndependent = {
  for (final e in _independentVowels.entries) e.value: e.key,
};
final _wxVowelSigns = {
  for (final e in _vowelSigns.entries) e.value: e.key,
};
final _wxSigns = {
  'M': 'ं', 'H': 'ः', 'z': 'ँ', 'Z': 'ऽ',
};

String devanagariToWx(String text) {
  final out = StringBuffer();
  final n = text.length;
  var i = 0;
  while (i < n) {
    final ch = text[i];
    i++;
    final consonant = _consonants[ch];
    if (consonant != null) {
      out.write(consonant);
      final next = i < n ? text[i] : '';
      if (next == _virama) {
        i++;
        if (i < n && (text[i] == _zwj || text[i] == _zwnj)) i++;
      } else if (_vowelSigns.containsKey(next)) {
        out.write(_vowelSigns[next]);
        i++;
      } else {
        out.write('a');
      }
      continue;
    }
    final digit = _digits.indexOf(ch);
    out.write(_independentVowels[ch] ??
        _vowelSigns[ch] ??
        _signs[ch] ??
        (digit >= 0 ? '$digit' : (ch == _virama ? '' : ch)));
  }
  return out.toString();
}

String wxToDevanagari(String wx) {
  final out = StringBuffer();
  final n = wx.length;
  var pending = false; // last thing written was a consonant with no vowel yet
  var i = 0;
  while (i < n) {
    final ch = wx[i];
    // '@word' is a literal Latin word in the reference converters.
    if (ch == '@') {
      var j = i + 1;
      while (j < n && RegExp('[a-zA-Z]').hasMatch(wx[j])) {
        j++;
      }
      if (pending) out.write(_virama);
      pending = false;
      out.write(wx.substring(i + 1, j));
      i = j;
      continue;
    }
    String? consonant;
    if (ch == 'l' && i + 1 < n && wx[i + 1] == 'Y') {
      consonant = _wxConsonants['lY'];
      i += 2;
    } else {
      consonant = _wxConsonants[ch];
      i++;
    }
    if (consonant != null) {
      if (pending) out.write(_virama);
      out.write(consonant);
      pending = true;
      continue;
    }
    final vowel = _wxVowelsIndependent[ch];
    if (vowel != null) {
      if (pending) {
        if (ch != 'a') out.write(_wxVowelSigns[ch]);
      } else {
        out.write(vowel);
      }
      pending = false;
      continue;
    }
    if (pending) out.write(_virama);
    pending = false;
    final digit = '0123456789'.indexOf(ch);
    out.write(_wxSigns[ch] ?? (digit >= 0 ? _digits[digit] : ch));
  }
  if (pending) out.write(_virama);
  return out.toString();
}
