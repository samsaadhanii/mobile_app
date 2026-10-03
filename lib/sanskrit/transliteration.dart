/// Transliteration between the scripts in [Script], with WX as the pivot
/// (ARCHITECTURE.md D4). Plain Dart, no Flutter, no network.
///
/// The mappings follow the scl `converters/` tables. Where a table is
/// silent the text passes through unchanged: spaces, punctuation, digits
/// (except Devanagari digits), `-`, `_`, `->`, parentheses, and any Latin
/// letter that is not part of the scheme. Vedic accents are not handled.
library;

import 'devanagari.dart';
import 'script.dart';

export 'script.dart';

/// One direction of a Latin-script scheme: longest match wins, anything
/// unmatched is copied.
class _Table {
  _Table(Map<String, String> map, {this.literalAt = false})
      : _map = map,
        _maxLen = map.keys.fold(1, (m, k) => k.length > m ? k.length : m);

  final Map<String, String> _map;
  final int _maxLen;

  /// `@word` is written as a literal Latin word (the `@` is dropped), as in
  /// the reference `wx2utf8roman` and `wx-velthuis` tables.
  final bool literalAt;

  String apply(String text) {
    final out = StringBuffer();
    final n = text.length;
    var i = 0;
    while (i < n) {
      if (literalAt && text[i] == '@') {
        var j = i + 1;
        while (j < n && RegExp('[a-zA-Z]').hasMatch(text[j])) {
          j++;
        }
        out.write(text.substring(i + 1, j));
        i = j;
        continue;
      }
      String? hit;
      var len = 0;
      for (var l = _maxLen < n - i ? _maxLen : n - i; l >= 1; l--) {
        final v = _map[text.substring(i, i + l)];
        if (v != null) {
          hit = v;
          len = l;
          break;
        }
      }
      if (hit == null) {
        out.write(text[i]);
        i++;
      } else {
        out.write(hit);
        i += len;
      }
    }
    return out.toString();
  }
}

Map<String, String> _inverse(Map<String, String> m) =>
    {for (final e in m.entries) e.value: e.key};

// ── IAST ────────────────────────────────────────────────────────────────
// wx2utf8roman.lex (WX -> IAST) and utf8roman2wx.lex (IAST -> WX).
const _wxToIast = {
  'A': 'ā', 'I': 'ī', 'U': 'ū', 'L': 'ḷ', 'q': 'ṛ', 'Q': 'ṝ',
  'E': 'ai', 'O': 'au', 'H': 'ḥ', 'M': 'ṃ', 'z': 'ṁ',
  'K': 'kh', 'G': 'gh', 'f': 'ṅ', 'C': 'ch', 'J': 'jh', 'F': 'ñ',
  't': 'ṭ', 'T': 'ṭh', 'd': 'ḍ', 'D': 'ḍh', 'N': 'ṇ',
  'w': 't', 'W': 'th', 'x': 'd', 'X': 'dh', 'P': 'ph', 'B': 'bh',
  'S': 'ś', 'R': 'ṣ', 'Z': "'", 'lY': 'ḻ',
};

// Only lower case is listed; upper case is derived in _iastToWx.
// `ṁ` is candrabindu (WX z), not anusvāra: that is how Samsaadhanii's own
// IAST output uses it, although utf8roman2wx.lex reads it as M (U4b).
const _iastToWxLower = {
  'ā': 'A', 'ī': 'I', 'ū': 'U', 'ḷ': 'L', 'ṛ': 'q', 'ṝ': 'Q',
  'ai': 'E', 'au': 'O', 'ṃ': 'M', 'ṁ': 'z', 'ḥ': 'H',
  'kh': 'K', 'gh': 'G', 'ṅ': 'f', 'ch': 'C', 'jh': 'J', 'ñ': 'F',
  'ṭ': 't', 'ṭh': 'T', 'ḍ': 'd', 'ḍh': 'D', 'ṇ': 'N',
  't': 'w', 'th': 'W', 'd': 'x', 'dh': 'X', 'ph': 'P', 'bh': 'B',
  'ś': 'S', 'ṣ': 'R', "'": 'Z', 'ḻ': 'lY',
};

/// Letters with a combining mark -> the precomposed letter the table uses.
const _iastComposed = {
  'ā': 'ā', 'ī': 'ī', 'ū': 'ū',
  'ṝ': 'ṝ', 'ṛ': 'ṛ', 'ḷ': 'ḷ',
  'ṃ': 'ṃ', 'ṁ': 'ṁ', 'm̐': 'ṁ', 'ḥ': 'ḥ',
  'ṅ': 'ṅ', 'ñ': 'ñ', 'ṇ': 'ṇ',
  'ṭ': 'ṭ', 'ḍ': 'ḍ', 'ś': 'ś', 'ṣ': 'ṣ',
};

String _capitalise(String s) => s[0].toUpperCase() + s.substring(1);

final _iastToWx = _Table({
  for (final e in _iastToWxLower.entries) ...{
    e.key: e.value,
    _capitalise(e.key): e.value,
    if (e.key.length > 1 && e.key.codeUnitAt(0) < 128)
      e.key.toUpperCase(): e.value,
  },
  // Upper-case plain vowels (the table maps A -> a, I -> i, ...).
  'A': 'a', 'I': 'i', 'U': 'u', 'E': 'e', 'O': 'o',
  // Capital consonants whose WX letter differs from the Latin one.
  'T': 'w', 'D': 'x', 'Th': 'W', 'Dh': 'X', 'N': 'n', 'R': 'r',
  'P': 'p', 'B': 'b', 'M': 'm', 'Y': 'y', 'L': 'l', 'V': 'v', 'S': 's',
  'K': 'k', 'G': 'g', 'C': 'c', 'J': 'j',
});

String _iastToWxText(String text) {
  var s = text;
  for (final e in _iastComposed.entries) {
    s = s.replaceAll(e.key, e.value);
  }
  return _iastToWx.apply(s);
}

final _wxToIastTable = _Table(_wxToIast, literalAt: true);

// ── SLP1 ────────────────────────────────────────────────────────────────
// slp2wx.lex and wx2slp.lex. SLP1 `L` (ळ) is `lY` in WX; the scl tables
// leave `L` alone, which would turn it into WX ḷ.
const _slp1ToWx = {
  "'": 'Z', 't': 'w', 'T': 'W', 'd': 'x', 'D': 'X', 'f': 'q', 'F': 'Q',
  'w': 't', 'W': 'T', 'q': 'd', 'Q': 'D', 'R': 'N', 'Y': 'F', 'N': 'f',
  'x': 'L', 'z': 'R', '|': 'lYh', '~': 'z', 'L': 'lY',
};
final _slp1ToWxTable = _Table(_slp1ToWx);
final _wxToSlp1Table = _Table({
  ..._inverse(_slp1ToWx),
});

// ── Velthuis ────────────────────────────────────────────────────────────
// velthuis-wx.lex and wx-velthuis.lex.
const _velthuisToWx = {
  'a_a': 'aa', 'i_i': 'ii', 'u_u': 'uu', 'a_i': 'ai', 'a_u': 'au',
  'aa': 'A', 'ii': 'I', 'uu': 'U', 'ai': 'E', 'au': 'O',
  '.rr': 'Q', '.r': 'q', '.R': 'Q', '.l': 'L',
  'kh': 'K', 'gh': 'G', '"n': 'f', 'ch': 'C', 'jh': 'J', '~n': 'F',
  '.th': 'T', '.t': 't', '.T': 'T', '.dh': 'D', '.d': 'd', '.D': 'D',
  'th': 'W', 't': 'w', 'T': 'W', 'dh': 'X', 'd': 'x', 'D': 'X',
  '.n': 'N', 'ph': 'P', 'bh': 'B', '"s': 'S', 'z': 'S', '.s': 'R',
  '.h': 'H', '.m': 'M', '"m': 'z', "'": 'Z',
};
const _wxToVelthuis = {
  'aa': 'a_a', 'ai': 'a_i', 'au': 'a_u', 'ii': 'i_i', 'uu': 'u_u',
  'A': 'aa', 'I': 'ii', 'U': 'uu', 'L': '.l', 'E': 'ai', 'O': 'au',
  'H': '.h', 'q': '.r', 'Q': '.rr', 'K': 'kh', 'G': 'gh', 'C': 'ch',
  'J': 'jh', 'F': '~n', 't': '.t', 'T': '.th', 'd': '.d', 'D': '.dh',
  'N': '.n', 'M': '.m', 'w': 't', 'W': 'th', 'x': 'd', 'X': 'dh',
  'P': 'ph', 'B': 'bh', 'S': 'z', 'R': '.s', 'z': '"m',
  // Not in wx-velthuis.lex; the inverse of what velthuis-wx.lex accepts.
  'f': '"n', 'Z': "'",
};
final _velthuisToWxTable = _Table(_velthuisToWx);
final _wxToVelthuisTable = _Table(_wxToVelthuis, literalAt: true);

// ── Kyoto-Harvard ───────────────────────────────────────────────────────
// kyoto_ra.lex, plus `lR` (ḷ), which the standard scheme has and the
// table lacks.
const _kyotoToWx = {
  'RR': 'Q', 'R': 'q', 'lR': 'L', 'ai': 'E', 'au': 'O',
  'kh': 'K', 'gh': 'G', 'G': 'f', 'ch': 'C', 'jh': 'J', 'J': 'F',
  'Th': 'T', 'T': 't', 'Dh': 'D', 'D': 'd',
  'th': 'W', 't': 'w', 'dh': 'X', 'd': 'x', 'ph': 'P', 'bh': 'B',
  'z': 'S', 'S': 'R', "'": 'Z',
};
const _wxToKyoto = {
  'Q': 'RR', 'q': 'R', 'L': 'lR', 'E': 'ai', 'O': 'au',
  'K': 'kh', 'G': 'gh', 'f': 'G', 'C': 'ch', 'J': 'jh', 'F': 'J',
  'T': 'Th', 't': 'T', 'D': 'Dh', 'd': 'D',
  'W': 'th', 'w': 't', 'X': 'dh', 'x': 'd', 'P': 'ph', 'B': 'bh',
  'S': 'z', 'R': 'S', 'Z': "'",
  // Candrabindu has no Kyoto-Harvard letter; written as anusvāra.
  'z': 'M',
};
final _kyotoToWxTable = _Table(_kyotoToWx);
final _wxToKyotoTable = _Table(_wxToKyoto);

// ── ITRANS ──────────────────────────────────────────────────────────────
// itrans_ra.lex, whose output is the intermediate "ra" form; mapped here to
// WX directly. Nukta letters (q, K, G, z, f, .D, .Dh) are not handled.
const _itransToWx = {
  'OM': 'oM', 'AUM': 'oM', 'aa': 'A', 'ii': 'I', 'uu': 'U',
  'RRi': 'q', 'R^i': 'q', 'RRI': 'Q', 'R^I': 'Q', 'LLi': 'L', 'L^i': 'L',
  'ai': 'E', 'au': 'O', '.n': 'M', '.m': 'M', '.N': 'z', '.a': 'Z',
  'kh': 'K', 'gh': 'G', '~N': 'f', 'N^': 'f',
  'chh': 'C', 'ch': 'c', 'Ch': 'C', 'jh': 'J', '~n': 'F', 'JN': 'F',
  'T': 't', 'Th': 'T', 'D': 'd', 'Dh': 'D',
  't': 'w', 'th': 'W', 'd': 'x', 'dh': 'X', 'ph': 'P', 'bh': 'B',
  'w': 'v', 'sh': 'S', 'shh': 'R', 'Sh': 'R', 'L': 'lY',
  'ksh': 'kR', 'x': 'kR', 'GY': 'jF', 'j~n': 'jF', 'dny': 'jF',
};
const _wxToItrans = {
  'A': 'aa', 'I': 'ii', 'U': 'uu', 'q': 'RRi', 'Q': 'RRI', 'L': 'LLi',
  'E': 'ai', 'O': 'au', 'z': '.N', 'Z': '.a',
  'K': 'kh', 'G': 'gh', 'f': '~N', 'c': 'ch', 'C': 'Ch', 'J': 'jh',
  'F': '~n', 't': 'T', 'T': 'Th', 'd': 'D', 'D': 'Dh',
  'w': 't', 'W': 'th', 'x': 'd', 'X': 'dh', 'P': 'ph', 'B': 'bh',
  'S': 'sh', 'R': 'Sh', 'lY': 'L',
};
final _itransToWxTable = _Table(_itransToWx);
final _wxToItransTable = _Table(_wxToItrans);

/// Converts [text] written in [from] to WX.
String toWx(String text, Script from) {
  switch (from) {
    case Script.wx:
      return text;
    case Script.devanagari:
      return devanagariToWx(text);
    case Script.iast:
      return _iastToWxText(text);
    case Script.slp1:
      return _slp1ToWxTable.apply(text);
    case Script.kyotoHarvard:
      return _kyotoToWxTable.apply(text);
    case Script.velthuis:
      return _velthuisToWxTable.apply(text);
    case Script.itrans:
      return _itransToWxTable.apply(text);
  }
}

/// Converts [wx] to [to].
String fromWx(String wx, Script to) {
  switch (to) {
    case Script.wx:
      return wx;
    case Script.devanagari:
      return wxToDevanagari(wx);
    case Script.iast:
      return _wxToIastTable.apply(wx);
    case Script.slp1:
      return _wxToSlp1Table.apply(wx);
    case Script.kyotoHarvard:
      return _wxToKyotoTable.apply(wx);
    case Script.velthuis:
      return _wxToVelthuisTable.apply(wx);
    case Script.itrans:
      return _wxToItransTable.apply(wx);
  }
}

/// Converts [text] from one script to another, through WX.
String convert(String text, Script from, Script to) =>
    from == to ? text : fromWx(toWx(text, from), to);
