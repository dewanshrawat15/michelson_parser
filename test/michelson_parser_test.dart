import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:michelson_parser/src/grammar/grammar.dart';
import 'package:michelson_parser/src/parser/nearley.dart';
import 'package:michelson_parser/src/parser/parser_gram.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('demo grammar parser', () {
    var date = DateTime.now();
    var grammar = DemoGrammar();

    // Create a Parser object from our grammar.
    var parser = Nearley();
    parser.parser(Nearley.fromCompiled(grammar));

    // Parse something!
    print(jsonEncode(parser.feed("co\n")));

    print(DateTime.now().difference(date).inMicroseconds);
  });

  test('grammer', () async {
    var date = DateTime.now();
    var grammar = Grammar({
      'space': ' ',
      'number': RegExp('-?[0-9]+(?!x)'),
      'linebrake': '\n',
      'parameter': ['parameter', 'Parameter'],
      'storage': ['storage', 'storage'],
      'code': 'code',
      'semicolon': ";",
      // 'string': 'string',
      'lparn': '{',
      'rparn': '}',
      'comparableType': [
        'int',
        'nat',
        'string',
        'bytes',
        'mutez',
        'bool',
        'key_hash',
        'timestamp',
        'chain_id'
      ],
      'baseInstruction': [
        'ABS',
        'ADD',
        'ADDRESS',
        'AMOUNT',
        'AND',
        'BALANCE',
        'BLAKE2B',
        'CAR',
        'CAST',
        'CDR',
        'CHECK_SIGNATURE',
        'COMPARE',
        'CONCAT',
        'CONS',
        'CONTRACT',
        'DIP',
        'EDIV',
        'EMPTY_SET',
        'EQ',
        'EXEC',
        'FAIL',
        'FAILWITH',
        'GE',
        'GET',
        'GT',
        'HASH_KEY',
        'IF',
        'IF_CONS',
        'IF_LEFT',
        'IF_NONE',
        'IF_RIGHT',
        'IMPLICIT_ACCOUNT',
        'INT',
        'ISNAT',
        'ITER',
        'LAMBDA',
        'LE',
        'LEFT',
        'LOOP',
        'LOOP_LEFT',
        'LSL',
        'LSR',
        'LT',
        'MAP',
        'MEM',
        'MUL',
        'NEG',
        'NEQ',
        'NIL',
        'NONE',
        'NOT',
        'NOW',
        'OR',
        'PACK',
        'PAIR',
        'REDUCE',
        'RENAME',
        'RIGHT',
        'SELF',
        'SENDER',
        'SET_DELEGATE',
        'SHA256',
        'SHA512',
        'SIZE',
        'SLICE',
        'SOME',
        'SOURCE',
        'STEPS_TO_QUOTA',
        'SUB',
        'SWAP',
        'TRANSFER_TOKENS',
        'UNIT',
        'UNPACK',
        'UPDATE',
        'XOR',
        'UNPAIR',
        'UNPAPAIR',
        'IF_SOME',
        'IFCMPEQ',
        'IFCMPNEQ',
        'IFCMPLT',
        'IFCMPGT',
        'IFCMPLE',
        'IFCMPGE',
        'CMPEQ',
        'CMPNEQ',
        'CMPLT',
        'CMPGT',
        'CMPLE',
        'CMPGE',
        'IFEQ',
        'NEQ',
        'IFLT',
        'IFGT',
        'IFLE',
        'IFGE',
        'EMPTY_BIG_MAP',
        'APPLY',
        'CHAIN_ID'
      ],
      'constantType': ['key', 'unit', 'signature', 'operation', 'address'],
      'singleArgType': ['option', 'list', 'set', 'contract'],
      'doubleArgType': ['pair', 'or', 'lambda', 'map', 'big_map'],
      'constantData': ['Unit', 'True', 'False', 'None', 'instruction'],
      'singleArgData': ['Left', 'Right', 'Some'],
      'doubleArgData': ['Pair'],
      'elt': "Elt",
    });

    var tokens =
        grammar.feed("""3245 543 parameter string; storage string; code{}""");
    print(jsonEncode(tokens));
    print(tokens.length);
    print(DateTime.now().difference(date).inMicroseconds);
  });
}
