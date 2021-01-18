import 'package:michelson_parser/src/parser/nearley.dart';

class Grammar extends StreamLexer {
  Map<String, dynamic> delimiters;

  Grammar(this.delimiters) : super();

  feed(String text) {
    var tokens = tokenize(text).toList();
    return tokens;
  }

  Iterable<GrammarResultModel> tokenize(String chunk) sync* {
    String _sequence = '';

    for (int i = 0; i < chunk.length; i++) {
      final char = chunk[i];
      if (isArrayOrStringContaines(char)) {
        var argChar = getKeyFromValue(char);
        if (_sequence.length > 0) {
          var argSeq = getKeyFromValue(_sequence);
          yield GrammarResultModel(argSeq, _sequence);
        }
        yield GrammarResultModel(argChar, char);
        _sequence = '';
      } else {
        _sequence += char;
      }
    }

    if (_sequence.length > 0) yield GrammarResultModel('LAST', _sequence);
  }

  bool isArrayOrStringContaines(char) {
    if (delimiters.values.contains(char)) return true;
    var result = false;
    delimiters.forEach((key, value) {
      if (value is List) result = value.contains(char);
      if (value is RegExp) result = value.hasMatch(char);
    });
    return result;
  }

  getKeyFromValue(String char) => delimiters.entries
      .firstWhere((e) => e.value is List
          ? e.value.contains(char)
          : e.value is RegExp
              ? (e.value as RegExp).hasMatch(char)
              : e.value == char)
      .key;
}

class GrammarResultModel {
  String type;
  String value;

  GrammarResultModel(this.type, this.value);

  toJson() => {'type': type, 'value': value};
}
