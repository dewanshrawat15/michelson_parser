import 'package:michelson_parser/michelson_parser.dart';

class MichelsonGrammar {
  Grammar lexer;

  var macroCADRconst = 'C[AD]+R';
  var macroSETCADRconst = 'SET_C[AD]+R';
  var DIPmatcher = new RegExp('DII+P');
  var DUPmatcher = new RegExp('DUU+P');
  var macroASSERTlistConst = [
    'ASSERT',
    'ASSERT_EQ',
    'ASSERT_NEQ',
    'ASSERT_GT',
    'ASSERT_LT',
    'ASSERT_GE',
    'ASSERT_LE',
    'ASSERT_NONE',
    'ASSERT_SOME',
    'ASSERT_LEFT',
    'ASSERT_RIGHT',
    'ASSERT_CMPEQ',
    'ASSERT_CMPNEQ',
    'ASSERT_CMPGT',
    'ASSERT_CMPLT',
    'ASSERT_CMPGE',
    'ASSERT_CMPLE'
  ];
  var macroIFCMPlist = [
    'IFCMPEQ',
    'IFCMPNEQ',
    'IFCMPLT',
    'IFCMPGT',
    'IFCMPLE',
    'IFCMPGE'
  ];
  var macroCMPlist = ['CMPEQ', 'CMPNEQ', 'CMPLT', 'CMPGT', 'CMPLE', 'CMPGE'];
  var macroIFlist = ['IFEQ', 'IFNEQ', 'IFLT', 'IFGT', 'IFLE', 'IFGE'];

   var parameter;
 var storage;
 var code;
 var comparableType;
 var constantType;
 var singleArgType;
 var lparen;
 var rparen;
 var doubleArgType;
 var annot;
 var number;
 var string;
 var lbrace;
 var rbrace;
 var constantData;
 var singleArgData;
 var doubleArgData;
 var bytes;
 var elt;
 var semicolon;
 var baseInstruction;
 var macroCADR;
 var macroDIP;
 var macroDUP;
 var macroSETCADR;
 var macroASSERTlist;

  MichelsonGrammar() {
    lexer = new Grammar({
      'annot': RegExp(r'[\@\%\:][a-z_A-Z0-9]+'),
      'lparen': '(',
      'rparen': ')',
      'lbrace': '{',
      'rbrace': '}',
      'ws': RegExp(r'[ \t]+'),
      'semicolon': ";",
      'bytes': RegExp(r'0x[0-9a-fA-F]+'),
      'number': RegExp('-?[0-9]+(?!x)'),
      'parameter': ['parameter', 'Parameter'],
      'storage': ['Storage', 'storage'],
      'code': ['Code', 'code'],
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
      'constantType': ['key', 'unit', 'signature', 'operation', 'address'],
      'singleArgType': ['option', 'list', 'set', 'contract'],
      'doubleArgType': ['pair', 'or', 'lambda', 'map', 'big_map'],
      'baseInstruction': [
        'ABS', 'ADD', 'ADDRESS', 'AMOUNT', 'AND', 'BALANCE', 'BLAKE2B', 'CAR',
        'CAST', 'CDR', 'CHECK_SIGNATURE',
        'COMPARE', 'CONCAT', 'CONS', 'CONTRACT', /*'CREATE_CONTRACT',*/ 'DIP',
        /*'DROP',*/ /*'DUP',*/ 'EDIV',
        /*'EMPTY_MAP',*/
        'EMPTY_SET', 'EQ', 'EXEC', 'FAIL', 'FAILWITH', 'GE', 'GET', 'GT',
        'HASH_KEY', 'IF', 'IF_CONS', 'IF_LEFT', 'IF_NONE',
        'IF_RIGHT', 'IMPLICIT_ACCOUNT', 'INT', 'ISNAT', 'ITER', 'LAMBDA', 'LE',
        'LEFT', 'LOOP', 'LOOP_LEFT', 'LSL', 'LSR', 'LT',
        'MAP', 'MEM', 'MUL', 'NEG', 'NEQ', 'NIL', 'NONE', 'NOT', 'NOW', 'OR',
        'PACK', 'PAIR', /*'PUSH',*/ 'REDUCE', 'RENAME', 'RIGHT', 'SELF',
        'SENDER', 'SET_DELEGATE', 'SHA256', 'SHA512', 'SIZE', 'SLICE', 'SOME',
        'SOURCE', 'STEPS_TO_QUOTA', 'SUB', 'SWAP',
        'TRANSFER_TOKENS', 'UNIT', 'UNPACK', 'UPDATE', 'XOR',
        'UNPAIR', 'UNPAPAIR', // TODO: macro
        'IF_SOME', // TODO: macro
        'IFCMPEQ', 'IFCMPNEQ', 'IFCMPLT', 'IFCMPGT', 'IFCMPLE', 'IFCMPGE',
        'CMPEQ', 'CMPNEQ', 'CMPLT', 'CMPGT', 'CMPLE',
        'CMPGE', 'IFEQ', 'NEQ', 'IFLT', 'IFGT', 'IFLE',
        'IFGE', // TODO: should be separate
        /*'DIG',*/ /*'DUG',*/ 'EMPTY_BIG_MAP', 'APPLY', 'CHAIN_ID'
      ],
      'macroCADR': macroCADRconst,
      // 'macroDIP': macroDIPconst,
      // 'macroDUP': macroDUPconst,
      'macroSETCADR': macroSETCADRconst,
      'macroASSERTlist': macroASSERTlistConst,
      'constantData': ['Unit', 'True', 'False', 'None', 'instruction'],
      'singleArgData': ['Left', 'Right', 'Some'],
      'doubleArgData': ['Pair'],
      'elt': "Elt",
      // 'word': RegExp(r'[a-zA-Z_0-9]+'),
      // 'string': /"(?:\\["\\]|[^\n"\\])*"/s
    });
  }

  scriptToJson(d) => '[ ${d[0]}, ${d[2]}, { "prim": "code", "args": [ [ ${d[4]} ] ] } ]';

  singleArgKeywordToJson(d) => '{ "prim": "${d[0]}", "args": [ ${d[2]} ] }';

  keywordToJson(d) {
        var word = d[0].toString();

        if (d.length == 1) {
            if (checkKeyword(word)) {
                return expandKeyword(word, null);
            } else {
                return '{ "prim": "${d[0]}" }';
            }
        } else {
            const annot = d[1].map((x) => '"${x[1]}"');
            if (checkKeyword(word)) {
                return [expandKeyword(word, annot)];
            } else {
                return '{ "prim": "${d[0]}", "annots": [${annot}] }';
            }
        }
    }

  checkKeyword(word){
        if (check_assert(word)) { return true; }
        if (check_compare(word)) { return true; }
        if (check_dip(word)) { return true; }
        if (check_dup(word)) { return true; }
        if (check_fail(word)) { return true; }
        if (check_if(word)) { return true; }
        if (checkC_R(word)) { return true; }
        if (check_other(word)) { return true; }
        if (checkSetCadr(word)) { return true; }
        return false;
    }

    expandKeyword(word, annot) {
        if (checkC_R(word)) { return expandC_R(word, annot); }
        if (check_assert(word)) { return expand_assert(word, annot); }
        if (check_compare(word)) { return expand_cmp(word, annot); }
        if (check_dip(word)) { return expandDIP(word, annot); }
        if (check_dup(word)) { return expand_dup(word, annot); }
        if (check_fail(word)) { return expand_fail(word, annot); }
        if (check_if(word)) { return expandIF(word, annot); }
        if (check_other(word)) { return expand_other(word, annot); }
        if (checkSetCadr(word)) { return expandSetCadr(word, annot); }
        return false;
    }

    check_assert(asser) => macroASSERTlistConst.contains(asser);
    check_compare(cmp) => macroCMPlist.contains(cmp);
    check_dip(dip) => DIPmatcher.hasMatch(dip);
    check_dup(dup) => DUPmatcher.hasMatch(dup);
    check_fail(fail) => fail == "FAIL";
    check_if(ifStatement) => (macroIFCMPlist.contains(ifStatement) || macroIFlist.contains(ifStatement) || ifStatement == 'IF_SOME'); // TODO: IF_SOME
    
    checkC_R(c_r) => RegExp('^C(A|D)(A|D)+R$').hasMatch(c_r);
    expandC_R(word, annot) {
        var expandedC_R = word.substring(1, word.length-1).split('').map((c) => (c === 'A' ? '{ "prim": "CAR" }' : '{ "prim": "CDR" }'));

        if (annot != null) {
            const lastChar = word.slice(-2, -1);
            if (lastChar === 'A') {
                expandedC_R[expandedC_R.length-1] = '{ "prim": "CAR", "annots": [${annot}] }';
            } else if (lastChar === 'D') {
                expandedC_R[expandedC_R.length-1] = '{ "prim": "CDR", "annots": [${annot}] }';
            }
        }

        return `[${expandedC_R.join(', ')}]`;
    }

    check_other(word) => (word == "UNPAIR" || word == "UNPAPAIR"); // TODO: dynamic matching
    checkSetCadr(s) => new RegExp(macroSETCADRconst).hasMatch(s);







  id(x) => x[0];

  Map<String, dynamic> get grammar => {
        'Lexer': null,
        'ParserRules': [
          {"name": "main", "symbols": ["instruction"], "postprocess": id},
    {"name": "main", "symbols": ["data"], "postprocess": id},
    {"name": "main", "symbols": ["type"], "postprocess": id},
    {"name": "main", "symbols": ["parameter"], "postprocess": id},
    {"name": "main", "symbols": ["storage"], "postprocess": id},
    {"name": "main", "symbols": ["code"], "postprocess": id},
    {"name": "main", "symbols": ["script"], "postprocess": id},
    {"name": "main", "symbols": ["parameterValue"], "postprocess": id},
    {"name": "main", "symbols": ["storageValue"], "postprocess": id},
    {"name": "main", "symbols": ["typeData"], "postprocess": id},
    {"name": "script", "symbols": ["parameter", "_", "storage", "_", "code"], "postprocess": scriptToJson},
    {"name": "parameterValue", "symbols": [(lexer.has("parameter") ? {'type': "parameter"} : parameter), "_", "typeData", "_", "semicolons"], "postprocess": singleArgKeywordToJson},
    {"name": "storageValue", "symbols": [(lexer.has("storage") ? {'type': "storage"} : storage), "_", "typeData", "_", "semicolons"], "postprocess": singleArgKeywordToJson},
    {"name": "parameter", "symbols": [(lexer.has("parameter") ? {'type': "parameter"} : parameter), "_", "type", "_", "semicolons"], "postprocess": singleArgKeywordToJson},
    {"name": "storage", "symbols": [(lexer.has("storage") ? {'type': "storage"} : storage), "_", "type", "_", "semicolons"], "postprocess": singleArgKeywordToJson},
    {"name": "code", "symbols": [(lexer.has("code") ? {'type': "code"} : code), "_", "subInstruction", "_", "semicolons", "_"], "postprocess": (d) => d[2]},
    {"name": "code", "symbols": [(lexer.has("code") ? {type: "code"} : code), "_", {"literal":"{};"}], "postprocess": (d) => "code {}"},
    {"name": "type", "symbols": [(lexer.has("comparableType") ? {'type': "comparableType"} : comparableType)], "postprocess": keywordToJson},
    {"name": "type", "symbols": [(lexer.has("constantType") ? {'type': "constantType"} : constantType)], "postprocess": keywordToJson},
    {"name": "type", "symbols": [(lexer.has("singleArgType") ? {'type': "singleArgType"} : singleArgType), "_", "type"], "postprocess": singleArgKeywordToJson},
    {"name": "type", "symbols": [(lexer.has("lparen") ? {type: "lparen"} : lparen), "_", (lexer.has("singleArgType") ? {type: "singleArgType"} : singleArgType), "_", "type", "_", (lexer.has("rparen") ? {type: "rparen"} : rparen)], "postprocess": singleArgKeywordWithParenToJson},
    {"name": "type", "symbols": [(lexer.has("lparen") ? {type: "lparen"} : lparen), "_", (lexer.has("singleArgType") ? {type: "singleArgType"} : singleArgType), "_", (lexer.has("lparen") ? {type: "lparen"} : lparen), "_", "type", "_", (lexer.has("rparen") ? {type: "rparen"} : rparen), "_", (lexer.has("rparen") ? {type: "rparen"} : rparen)], "postprocess": singleArgKeywordWithParenToJson},
    {"name": "type", "symbols": [(lexer.has("doubleArgType") ? {type: "doubleArgType"} : doubleArgType), "_", "type", "_", "type"], "postprocess": doubleArgKeywordToJson},
    {"name": "type", "symbols": [(lexer.has("lparen") ? {type: "lparen"} : lparen), "_", (lexer.has("doubleArgType") ? {type: "doubleArgType"} : doubleArgType), "_", "type", "_", "type", "_", (lexer.has("rparen") ? {type: "rparen"} : rparen)], "postprocess": doubleArgKeywordWithParenToJson},
    {"name": "type$ebnf$1$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "type$ebnf$1", "symbols": ["type$ebnf$1$subexpression$1"]},
    {"name": "type$ebnf$1$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "type$ebnf$1", "symbols": ["type$ebnf$1", "type$ebnf$1$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "type", "symbols": [(lexer.has("comparableType") ? {type: "comparableType"} : comparableType), "type$ebnf$1"], "postprocess": keywordToJson},
    {"name": "type$ebnf$2$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "type$ebnf$2", "symbols": ["type$ebnf$2$subexpression$1"]},
    {"name": "type$ebnf$2$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "type$ebnf$2", "symbols": ["type$ebnf$2", "type$ebnf$2$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "type", "symbols": [(lexer.has("constantType") ? {type: "constantType"} : constantType), "type$ebnf$2"], "postprocess": keywordToJson},
    {"name": "type$ebnf$3$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "type$ebnf$3", "symbols": ["type$ebnf$3$subexpression$1"]},
    {"name": "type$ebnf$3$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "type$ebnf$3", "symbols": ["type$ebnf$3", "type$ebnf$3$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "type", "symbols": [(lexer.has("lparen") ? {type: "lparen"} : lparen), "_", (lexer.has("comparableType") ? {type: "comparableType"} : comparableType), "type$ebnf$3", "_", (lexer.has("rparen") ? {type: "rparen"} : rparen)], "postprocess": comparableTypeToJson},
    {"name": "type$ebnf$4$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "type$ebnf$4", "symbols": ["type$ebnf$4$subexpression$1"]},
    {"name": "type$ebnf$4$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "type$ebnf$4", "symbols": ["type$ebnf$4", "type$ebnf$4$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "type", "symbols": [(lexer.has("lparen") ? {type: "lparen"} : lparen), "_", (lexer.has("constantType") ? {type: "constantType"} : constantType), "type$ebnf$4", "_", (lexer.has("rparen") ? {type: "rparen"} : rparen)], "postprocess": comparableTypeToJson},
    {"name": "type$ebnf$5$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "type$ebnf$5", "symbols": ["type$ebnf$5$subexpression$1"]},
    {"name": "type$ebnf$5$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "type$ebnf$5", "symbols": ["type$ebnf$5", "type$ebnf$5$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "type", "symbols": [(lexer.has("lparen") ? {type: "lparen"} : lparen), "_", (lexer.has("singleArgType") ? {type: "singleArgType"} : singleArgType), "type$ebnf$5", "_", "type", (lexer.has("rparen") ? {type: "rparen"} : rparen)], "postprocess": singleArgTypeKeywordWithParenToJson},
    {"name": "type$ebnf$6$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "type$ebnf$6", "symbols": ["type$ebnf$6$subexpression$1"]},
    {"name": "type$ebnf$6$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "type$ebnf$6", "symbols": ["type$ebnf$6", "type$ebnf$6$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "type", "symbols": [(lexer.has("lparen") ? {type: "lparen"} : lparen), "_", (lexer.has("doubleArgType") ? {type: "doubleArgType"} : doubleArgType), "type$ebnf$6", "_", "type", "_", "type", (lexer.has("rparen") ? {type: "rparen"} : rparen)], "postprocess": doubleArgTypeKeywordWithParenToJson},
    {"name": "typeData", "symbols": [(lexer.has("singleArgType") ? {type: "singleArgType"} : singleArgType), "_", "typeData"], "postprocess": singleArgKeywordToJson},
    {"name": "typeData", "symbols": [(lexer.has("lparen") ? {type: "lparen"} : lparen), "_", (lexer.has("singleArgType") ? {type: "singleArgType"} : singleArgType), "_", "typeData", "_", (lexer.has("rparen") ? {type: "rparen"} : rparen)], "postprocess": singleArgKeywordWithParenToJson},
    {"name": "typeData", "symbols": [(lexer.has("doubleArgType") ? {type: "doubleArgType"} : doubleArgType), "_", "typeData", "_", "typeData"], "postprocess": doubleArgKeywordToJson},
    {"name": "typeData", "symbols": [(lexer.has("lparen") ? {type: "lparen"} : lparen), "_", (lexer.has("doubleArgType") ? {type: "doubleArgType"} : doubleArgType), "_", "typeData", "_", "typeData", "_", (lexer.has("rparen") ? {type: "rparen"} : rparen)], "postprocess": doubleArgKeywordWithParenToJson},
    {"name": "typeData", "symbols": ["subTypeData"], "postprocess": id},
    {"name": "typeData", "symbols": ["subTypeElt"], "postprocess": id},
    {"name": "typeData", "symbols": [(lexer.has("number") ? {type: "number"} : number)], "postprocess": intToJson},
    {"name": "typeData", "symbols": [(lexer.has("string") ? {type: "string"} : string)], "postprocess": stringToJson},
    {"name": "typeData", "symbols": [(lexer.has("lbrace") ? {type: "lbrace"} : lbrace), "_", (lexer.has("rbrace") ? {type: "rbrace"} : rbrace)], "postprocess": d => []},
    {"name": "data", "symbols": [(lexer.has("constantData") ? {type: "constantData"} : constantData)], "postprocess": keywordToJson},
    {"name": "data", "symbols": [(lexer.has("singleArgData") ? {type: "singleArgData"} : singleArgData), "_", "data"], "postprocess": singleArgKeywordToJson},
    {"name": "data", "symbols": [(lexer.has("doubleArgData") ? {type: "doubleArgData"} : doubleArgData), "_", "data", "_", "data"], "postprocess": doubleArgKeywordToJson},
    {"name": "data", "symbols": ["subData"], "postprocess": id},
    {"name": "data", "symbols": ["subElt"], "postprocess": id},
    {"name": "data", "symbols": [(lexer.has("string") ? {type: "string"} : string)], "postprocess": stringToJson},
    {"name": "data", "symbols": [(lexer.has("bytes") ? {type: "bytes"} : bytes)], "postprocess": bytesToJson},
    {"name": "data", "symbols": [(lexer.has("number") ? {type: "number"} : number)], "postprocess": intToJson},
    {"name": "subData", "symbols": [(lexer.has("lbrace") ? {type: "lbrace"} : lbrace), "_", (lexer.has("rbrace") ? {type: "rbrace"} : rbrace)], "postprocess": d => "[]"},
    {"name": "subData$ebnf$1$subexpression$1", "symbols": ["data", "_"]},
    {"name": "subData$ebnf$1", "symbols": ["subData$ebnf$1$subexpression$1"]},
    {"name": "subData$ebnf$1$subexpression$2", "symbols": ["data", "_"]},
    {"name": "subData$ebnf$1", "symbols": ["subData$ebnf$1", "subData$ebnf$1$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "subData", "symbols": [{"literal":"("}, "_", "subData$ebnf$1", {"literal":")"}], "postprocess": instructionSetToJsonSemi},
    {"name": "subData$ebnf$2$subexpression$1$ebnf$1", "symbols": [{"literal":";"}], "postprocess": id},
    {"name": "subData$ebnf$2$subexpression$1$ebnf$1", "symbols": [], "postprocess": () => null},
    {"name": "subData$ebnf$2$subexpression$1", "symbols": ["data", "_", "subData$ebnf$2$subexpression$1$ebnf$1", "_"]},
    {"name": "subData$ebnf$2", "symbols": ["subData$ebnf$2$subexpression$1"]},
    {"name": "subData$ebnf$2$subexpression$2$ebnf$1", "symbols": [{"literal":";"}], "postprocess": id},
    {"name": "subData$ebnf$2$subexpression$2$ebnf$1", "symbols": [], "postprocess": () => null},
    {"name": "subData$ebnf$2$subexpression$2", "symbols": ["data", "_", "subData$ebnf$2$subexpression$2$ebnf$1", "_"]},
    {"name": "subData$ebnf$2", "symbols": ["subData$ebnf$2", "subData$ebnf$2$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "subData", "symbols": [{"literal":"{"}, "_", "subData$ebnf$2", {"literal":"}"}], "postprocess": dataListToJsonSemi},
    {"name": "subElt", "symbols": [(lexer.has("lbrace") ? {type: "lbrace"} : lbrace), "_", (lexer.has("rbrace") ? {type: "rbrace"} : rbrace)], "postprocess": d => "[]"},
    {"name": "subElt$ebnf$1$subexpression$1$ebnf$1", "symbols": [{"literal":";"}], "postprocess": id},
    {"name": "subElt$ebnf$1$subexpression$1$ebnf$1", "symbols": [], "postprocess": () => null},
    {"name": "subElt$ebnf$1$subexpression$1", "symbols": ["elt", "subElt$ebnf$1$subexpression$1$ebnf$1", "_"]},
    {"name": "subElt$ebnf$1", "symbols": ["subElt$ebnf$1$subexpression$1"]},
    {"name": "subElt$ebnf$1$subexpression$2$ebnf$1", "symbols": [{"literal":";"}], "postprocess": id},
    {"name": "subElt$ebnf$1$subexpression$2$ebnf$1", "symbols": [], "postprocess": () => null},
    {"name": "subElt$ebnf$1$subexpression$2", "symbols": ["elt", "subElt$ebnf$1$subexpression$2$ebnf$1", "_"]},
    {"name": "subElt$ebnf$1", "symbols": ["subElt$ebnf$1", "subElt$ebnf$1$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "subElt", "symbols": [{"literal":"{"}, "_", "subElt$ebnf$1", {"literal":"}"}], "postprocess": dataListToJsonSemi},
    {"name": "elt", "symbols": [(lexer.has("elt") ? {type: "elt"} : elt), "_", "data", "_", "data"], "postprocess": doubleArgKeywordToJson},
    {"name": "subTypeData", "symbols": [(lexer.has("lbrace") ? {type: "lbrace"} : lbrace), "_", (lexer.has("rbrace") ? {type: "rbrace"} : rbrace)], "postprocess": d => "[]"},
    {"name": "subTypeData$ebnf$1$subexpression$1$ebnf$1", "symbols": [{"literal":";"}], "postprocess": id},
    {"name": "subTypeData$ebnf$1$subexpression$1$ebnf$1", "symbols": [], "postprocess": () => null},
    {"name": "subTypeData$ebnf$1$subexpression$1", "symbols": ["data", "subTypeData$ebnf$1$subexpression$1$ebnf$1", "_"]},
    {"name": "subTypeData$ebnf$1", "symbols": ["subTypeData$ebnf$1$subexpression$1"]},
    {"name": "subTypeData$ebnf$1$subexpression$2$ebnf$1", "symbols": [{"literal":";"}], "postprocess": id},
    {"name": "subTypeData$ebnf$1$subexpression$2$ebnf$1", "symbols": [], "postprocess": () => null},
    {"name": "subTypeData$ebnf$1$subexpression$2", "symbols": ["data", "subTypeData$ebnf$1$subexpression$2$ebnf$1", "_"]},
    {"name": "subTypeData$ebnf$1", "symbols": ["subTypeData$ebnf$1", "subTypeData$ebnf$1$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "subTypeData", "symbols": [{"literal":"{"}, "_", "subTypeData$ebnf$1", {"literal":"}"}], "postprocess": instructionSetToJsonSemi},
    {"name": "subTypeData$ebnf$2$subexpression$1$ebnf$1", "symbols": [{"literal":";"}], "postprocess": id},
    {"name": "subTypeData$ebnf$2$subexpression$1$ebnf$1", "symbols": [], "postprocess": () => null},
    {"name": "subTypeData$ebnf$2$subexpression$1", "symbols": ["data", "subTypeData$ebnf$2$subexpression$1$ebnf$1", "_"]},
    {"name": "subTypeData$ebnf$2", "symbols": ["subTypeData$ebnf$2$subexpression$1"]},
    {"name": "subTypeData$ebnf$2$subexpression$2$ebnf$1", "symbols": [{"literal":";"}], "postprocess": id},
    {"name": "subTypeData$ebnf$2$subexpression$2$ebnf$1", "symbols": [], "postprocess": () => null},
    {"name": "subTypeData$ebnf$2$subexpression$2", "symbols": ["data", "subTypeData$ebnf$2$subexpression$2$ebnf$1", "_"]},
    {"name": "subTypeData$ebnf$2", "symbols": ["subTypeData$ebnf$2", "subTypeData$ebnf$2$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "subTypeData", "symbols": [{"literal":"("}, "_", "subTypeData$ebnf$2", {"literal":")"}], "postprocess": instructionSetToJsonSemi},
    {"name": "subTypeElt", "symbols": [(lexer.has("lbrace") ? {type: "lbrace"} : lbrace), "_", (lexer.has("rbrace") ? {type: "rbrace"} : rbrace)], "postprocess": d => "[]"},
    {"name": "subTypeElt$ebnf$1$subexpression$1$ebnf$1", "symbols": [{"literal":";"}], "postprocess": id},
    {"name": "subTypeElt$ebnf$1$subexpression$1$ebnf$1", "symbols": [], "postprocess": () => null},
    {"name": "subTypeElt$ebnf$1$subexpression$1", "symbols": ["typeElt", "subTypeElt$ebnf$1$subexpression$1$ebnf$1", "_"]},
    {"name": "subTypeElt$ebnf$1", "symbols": ["subTypeElt$ebnf$1$subexpression$1"]},
    {"name": "subTypeElt$ebnf$1$subexpression$2$ebnf$1", "symbols": [{"literal":";"}], "postprocess": id},
    {"name": "subTypeElt$ebnf$1$subexpression$2$ebnf$1", "symbols": [], "postprocess": () => null},
    {"name": "subTypeElt$ebnf$1$subexpression$2", "symbols": ["typeElt", "subTypeElt$ebnf$1$subexpression$2$ebnf$1", "_"]},
    {"name": "subTypeElt$ebnf$1", "symbols": ["subTypeElt$ebnf$1", "subTypeElt$ebnf$1$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "subTypeElt", "symbols": [{"literal":"[{"}, "_", "subTypeElt$ebnf$1", {"literal":"}]"}], "postprocess": instructionSetToJsonSemi},
    {"name": "subTypeElt$ebnf$2$subexpression$1$ebnf$1", "symbols": [{"literal":";"}], "postprocess": id},
    {"name": "subTypeElt$ebnf$2$subexpression$1$ebnf$1", "symbols": [], "postprocess": () => null},
    {"name": "subTypeElt$ebnf$2$subexpression$1", "symbols": ["typeElt", "_", "subTypeElt$ebnf$2$subexpression$1$ebnf$1", "_"]},
    {"name": "subTypeElt$ebnf$2", "symbols": ["subTypeElt$ebnf$2$subexpression$1"]},
    {"name": "subTypeElt$ebnf$2$subexpression$2$ebnf$1", "symbols": [{"literal":";"}], "postprocess": id},
    {"name": "subTypeElt$ebnf$2$subexpression$2$ebnf$1", "symbols": [], "postprocess": () => null},
    {"name": "subTypeElt$ebnf$2$subexpression$2", "symbols": ["typeElt", "_", "subTypeElt$ebnf$2$subexpression$2$ebnf$1", "_"]},
    {"name": "subTypeElt$ebnf$2", "symbols": ["subTypeElt$ebnf$2", "subTypeElt$ebnf$2$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "subTypeElt", "symbols": [{"literal":"[{"}, "_", "subTypeElt$ebnf$2", {"literal":"}]"}], "postprocess": instructionSetToJsonSemi},
    {"name": "typeElt", "symbols": [(lexer.has("elt") ? {type: "elt"} : elt), "_", "typeData", "_", "typeData"], "postprocess": doubleArgKeywordToJson},
    {"name": "subInstruction", "symbols": [(lexer.has("lbrace") ? {type: "lbrace"} : lbrace), "_", (lexer.has("rbrace") ? {type: "rbrace"} : rbrace)], "postprocess": d => ""},
    {"name": "subInstruction", "symbols": [(lexer.has("lbrace") ? {type: "lbrace"} : lbrace), "_", "instruction", "_", (lexer.has("rbrace") ? {type: "rbrace"} : rbrace)], "postprocess": d => d[2]},
    {"name": "subInstruction$ebnf$1$subexpression$1", "symbols": ["instruction", "_", (lexer.has("semicolon") ? {type: "semicolon"} : semicolon), "_"]},
    {"name": "subInstruction$ebnf$1", "symbols": ["subInstruction$ebnf$1$subexpression$1"]},
    {"name": "subInstruction$ebnf$1$subexpression$2", "symbols": ["instruction", "_", (lexer.has("semicolon") ? {type: "semicolon"} : semicolon), "_"]},
    {"name": "subInstruction$ebnf$1", "symbols": ["subInstruction$ebnf$1", "subInstruction$ebnf$1$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "subInstruction", "symbols": [(lexer.has("lbrace") ? {type: "lbrace"} : lbrace), "_", "subInstruction$ebnf$1", "instruction", "_", (lexer.has("rbrace") ? {type: "rbrace"} : rbrace)], "postprocess": instructionSetToJsonNoSemi},
    {"name": "subInstruction$ebnf$2$subexpression$1", "symbols": ["instruction", "_", (lexer.has("semicolon") ? {type: "semicolon"} : semicolon), "_"]},
    {"name": "subInstruction$ebnf$2", "symbols": ["subInstruction$ebnf$2$subexpression$1"]},
    {"name": "subInstruction$ebnf$2$subexpression$2", "symbols": ["instruction", "_", (lexer.has("semicolon") ? {type: "semicolon"} : semicolon), "_"]},
    {"name": "subInstruction$ebnf$2", "symbols": ["subInstruction$ebnf$2", "subInstruction$ebnf$2$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "subInstruction", "symbols": [(lexer.has("lbrace") ? {type: "lbrace"} : lbrace), "_", "subInstruction$ebnf$2", (lexer.has("rbrace") ? {type: "rbrace"} : rbrace)], "postprocess": instructionSetToJsonSemi},
    {"name": "instructions", "symbols": [(lexer.has("baseInstruction") ? {type: "baseInstruction"} : baseInstruction)]},
    {"name": "instructions", "symbols": [(lexer.has("macroCADR") ? {type: "macroCADR"} : macroCADR)]},
    {"name": "instructions", "symbols": [(lexer.has("macroDIP") ? {type: "macroDIP"} : macroDIP)]},
    {"name": "instructions", "symbols": [(lexer.has("macroDUP") ? {type: "macroDUP"} : macroDUP)]},
    {"name": "instructions", "symbols": [(lexer.has("macroSETCADR") ? {type: "macroSETCADR"} : macroSETCADR)]},
    {"name": "instructions", "symbols": [(lexer.has("macroASSERTlist") ? {type: "macroASSERTlist"} : macroASSERTlist)]},
    {"name": "instruction", "symbols": ["instructions"], "postprocess": keywordToJson},
    {"name": "instruction", "symbols": ["subInstruction"], "postprocess": id},
    {"name": "instruction$ebnf$1$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$1", "symbols": ["instruction$ebnf$1$subexpression$1"]},
    {"name": "instruction$ebnf$1$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$1", "symbols": ["instruction$ebnf$1", "instruction$ebnf$1$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": ["instructions", "instruction$ebnf$1", "_"], "postprocess": keywordToJson},
    {"name": "instruction", "symbols": ["instructions", "_", "subInstruction"], "postprocess": singleArgInstrKeywordToJson},
    {"name": "instruction$ebnf$2$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$2", "symbols": ["instruction$ebnf$2$subexpression$1"]},
    {"name": "instruction$ebnf$2$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$2", "symbols": ["instruction$ebnf$2", "instruction$ebnf$2$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": ["instructions", "instruction$ebnf$2", "_", "subInstruction"], "postprocess": singleArgTypeKeywordToJson},
    {"name": "instruction", "symbols": ["instructions", "_", "type"], "postprocess": singleArgKeywordToJson},
    {"name": "instruction$ebnf$3$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$3", "symbols": ["instruction$ebnf$3$subexpression$1"]},
    {"name": "instruction$ebnf$3$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$3", "symbols": ["instruction$ebnf$3", "instruction$ebnf$3$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": ["instructions", "instruction$ebnf$3", "_", "type"], "postprocess": singleArgTypeKeywordToJson},
    {"name": "instruction", "symbols": ["instructions", "_", "data"], "postprocess": singleArgKeywordToJson},
    {"name": "instruction$ebnf$4$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$4", "symbols": ["instruction$ebnf$4$subexpression$1"]},
    {"name": "instruction$ebnf$4$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$4", "symbols": ["instruction$ebnf$4", "instruction$ebnf$4$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": ["instructions", "instruction$ebnf$4", "_", "data"], "postprocess": singleArgTypeKeywordToJson},
    {"name": "instruction", "symbols": ["instructions", "_", "type", "_", "type", "_", "subInstruction"], "postprocess": tripleArgKeyWordToJson},
    {"name": "instruction$ebnf$5$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$5", "symbols": ["instruction$ebnf$5$subexpression$1"]},
    {"name": "instruction$ebnf$5$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$5", "symbols": ["instruction$ebnf$5", "instruction$ebnf$5$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": ["instructions", "instruction$ebnf$5", "_", "type", "_", "type", "_", "subInstruction"], "postprocess": tripleArgTypeKeyWordToJson},
    {"name": "instruction", "symbols": ["instructions", "_", "subInstruction", "_", "subInstruction"], "postprocess": doubleArgInstrKeywordToJson},
    {"name": "instruction$ebnf$6$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$6", "symbols": ["instruction$ebnf$6$subexpression$1"]},
    {"name": "instruction$ebnf$6$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$6", "symbols": ["instruction$ebnf$6", "instruction$ebnf$6$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": ["instructions", "instruction$ebnf$6", "_", "subInstruction", "_", "subInstruction"], "postprocess": doubleArgTypeKeywordToJson},
    {"name": "instruction", "symbols": ["instructions", "_", "type", "_", "type"], "postprocess": doubleArgKeywordToJson},
    {"name": "instruction$ebnf$7$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$7", "symbols": ["instruction$ebnf$7$subexpression$1"]},
    {"name": "instruction$ebnf$7$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$7", "symbols": ["instruction$ebnf$7", "instruction$ebnf$7$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": ["instructions", "instruction$ebnf$7", "_", "type", "_", "type"], "postprocess": doubleArgTypeKeywordToJson},
    {"name": "instruction", "symbols": [{"literal":"PUSH"}, "_", "type", "_", "data"], "postprocess": doubleArgKeywordToJson},
    {"name": "instruction", "symbols": [{"literal":"PUSH"}, "_", "type", "_", (lexer.has("lbrace") ? {type: "lbrace"} : lbrace), (lexer.has("rbrace") ? {type: "rbrace"} : rbrace)], "postprocess": pushToJson},
    {"name": "instruction$ebnf$8$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$8", "symbols": ["instruction$ebnf$8$subexpression$1"]},
    {"name": "instruction$ebnf$8$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$8", "symbols": ["instruction$ebnf$8", "instruction$ebnf$8$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": [{"literal":"PUSH"}, "instruction$ebnf$8", "_", "type", "_", "data"], "postprocess": pushWithAnnotsToJson},
    {"name": "instruction$ebnf$9", "symbols": [/[0-9]/]},
    {"name": "instruction$ebnf$9", "symbols": ["instruction$ebnf$9", /[0-9]/], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": [{"literal":"DIP"}, "_", "instruction$ebnf$9", "_", "subInstruction"], "postprocess": dipnToJson},
    {"name": "instruction$ebnf$10", "symbols": [/[0-9]/]},
    {"name": "instruction$ebnf$10", "symbols": ["instruction$ebnf$10", /[0-9]/], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": [{"literal":"DUP"}, "_", "instruction$ebnf$10"], "postprocess": dupnToJson},
    {"name": "instruction", "symbols": [{"literal":"DUP"}], "postprocess": keywordToJson},
    {"name": "instruction$ebnf$11$subexpression$1", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$11", "symbols": ["instruction$ebnf$11$subexpression$1"]},
    {"name": "instruction$ebnf$11$subexpression$2", "symbols": ["_", (lexer.has("annot") ? {type: "annot"} : annot)]},
    {"name": "instruction$ebnf$11", "symbols": ["instruction$ebnf$11", "instruction$ebnf$11$subexpression$2"], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": [{"literal":"DUP"}, "instruction$ebnf$11", "_"], "postprocess": keywordToJson},
    {"name": "instruction$ebnf$12", "symbols": [/[0-9]/]},
    {"name": "instruction$ebnf$12", "symbols": ["instruction$ebnf$12", /[0-9]/], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": [{"literal":"DIG"}, "_", "instruction$ebnf$12"], "postprocess": dignToJson},
    {"name": "instruction$ebnf$13", "symbols": [/[0-9]/]},
    {"name": "instruction$ebnf$13", "symbols": ["instruction$ebnf$13", /[0-9]/], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": [{"literal":"DUG"}, "_", "instruction$ebnf$13"], "postprocess": dignToJson},
    {"name": "instruction$ebnf$14", "symbols": [/[0-9]/]},
    {"name": "instruction$ebnf$14", "symbols": ["instruction$ebnf$14", /[0-9]/], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "instruction", "symbols": [{"literal":"DROP"}, "_", "instruction$ebnf$14"], "postprocess": dropnToJson},
    {"name": "instruction", "symbols": [{"literal":"DROP"}], "postprocess": keywordToJson},
    {"name": "instruction", "symbols": [{"literal":"CREATE_CONTRACT"}, "_", (lexer.has("lbrace") ? {type: "lbrace"} : lbrace), "_", "parameter", "_", "storage", "_", "code", "_", (lexer.has("rbrace") ? {type: "rbrace"} : rbrace)], "postprocess": subContractToJson},
    {"name": "instruction", "symbols": [{"literal":"EMPTY_MAP"}, "_", "type", "_", "type"], "postprocess": doubleArgKeywordToJson},
    {"name": "instruction", "symbols": [{"literal":"EMPTY_MAP"}, "_", (lexer.has("lparen") ? {type: "lparen"} : lparen), "_", "type", "_", (lexer.has("rparen") ? {type: "rparen"} : rparen), "_", "type"], "postprocess": doubleArgParenKeywordToJson},
    {"name": "_$ebnf$1", "symbols": []},
    {"name": "_$ebnf$1", "symbols": ["_$ebnf$1", /[\s]/], "postprocess": (d) => d[0].concat([d[1]])},
    {"name": "_", "symbols": ["_$ebnf$1"]},
    {"name": "semicolons$ebnf$1", "symbols": [/[;]/], "postprocess": id},
    {"name": "semicolons$ebnf$1", "symbols": [], "postprocess": () => null},
    {"name": "semicolons", "symbols": ["semicolons$ebnf$1"]}
        ],
        'ParserStart': "main"
      };

  arrpush(d) => d[0].addAll([d[1]]).toList();

  joiner(d) => d.join('');
}
