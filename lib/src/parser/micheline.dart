import 'package:michelson_parser/michelson_parser.dart';

class MichelineGrammar {
  Grammar lexer;
  var lbrace, _, colon, quotedValue, rbrace, comma, lbracket, rbracket;
  final List defaultMichelsonKeywords = ['"parameter"', '"storage"', '"code"', '"False"', '"Elt"', '"Left"', '"None"', '"Pair"', '"Right"', '"Some"', '"True"', '"Unit"', '"PACK"', '"UNPACK"', '"BLAKE2B"', '"SHA256"', '"SHA512"', '"ABS"', '"ADD"', '"AMOUNT"', '"AND"', '"BALANCE"', '"CAR"', '"CDR"', '"CHECK_SIGNATURE"', '"COMPARE"', '"CONCAT"', '"CONS"', '"CREATE_ACCOUNT"', '"CREATE_CONTRACT"', '"IMPLICIT_ACCOUNT"', '"DIP"', '"DROP"', '"DUP"', '"EDIV"', '"EMPTY_MAP"', '"EMPTY_SET"', '"EQ"', '"EXEC"', '"FAILWITH"', '"GE"', '"GET"', '"GT"', '"HASH_KEY"', '"IF"', '"IF_CONS"', '"IF_LEFT"', '"IF_NONE"', '"INT"', '"LAMBDA"', '"LE"', '"LEFT"', '"LOOP"', '"LSL"', '"LSR"', '"LT"', '"MAP"', '"MEM"', '"MUL"', '"NEG"', '"NEQ"', '"NIL"', '"NONE"', '"NOT"', '"NOW"', '"OR"', '"PAIR"', '"PUSH"', '"RIGHT"', '"SIZE"', '"SOME"', '"SOURCE"', '"SENDER"', '"SELF"', '"STEPS_TO_QUOTA"', '"SUB"', '"SWAP"', '"TRANSFER_TOKENS"', '"SET_DELEGATE"', '"UNIT"', '"UPDATE"', '"XOR"', '"ITER"', '"LOOP_LEFT"', '"ADDRESS"', '"CONTRACT"', '"ISNAT"', '"CAST"', '"RENAME"', '"bool"', '"contract"', '"int"', '"key"', '"key_hash"', '"lambda"', '"list"', '"map"', '"big_map"', '"nat"', '"option"', '"or"', '"pair"', '"set"', '"signature"', '"string"', '"bytes"', '"mutez"', '"timestamp"', '"unit"', '"operation"', '"address"', '"SLICE"', '"DIG"', '"DUG"', '"EMPTY_BIG_MAP"', '"APPLY"', '"chain_id"', '"CHAIN_ID"'];
  List languageKeywords;

  MichelineGrammar(){
    languageKeywords = defaultMichelsonKeywords;
    lexer = Grammar({
      'lbrace': '{',
      'rbrace': '}',
      'lbracket': '[',
      'rbracket': ']',
      'colon': ":",
      'comma': ",",
      '_': RegExp(r'/[ \t]+/'),
      'quotedValue': RegExp(r'/"(?:\\["\\]|[^\n"\\])*"/s')
    });
  }

  void setKeywordList (List list){
    languageKeywords = list;
  }

  int getCodeForKeyword(String word){
    return languageKeywords.indexOf(word);
  }

  String encodeLength(int l){
    String output = '0000000' + l.toRadixString(16).toString();
    return output.substring(output.length - 8);
  }

  String getKeywordForWord(int index){
    return languageKeywords[index];
  }

  String staticIntToHex(String d){
    final prefix = '00';
    final String text = d[6].toString();
    final value = writeSignedInt(int.parse(text.substring(1, text.length - 1)));
    return prefix + value;
  }

  String staticStringToHex(String d){
    final String prefix = '01';
    var text = d[6].toString();
    text = text.substring(1, text.length - 1);
    text = text.replaceAll(RegExp(r'/\\"/g'), '"');
    final len = encodeLength(text.length);
    text = text.split('').map((c) => c.codeUnitAt(0).toRadixString(16).toString()).join('');
    return prefix + len + text;
  }

  String staticBytesToHex(String d){
    final prefix = '0a';
    var bytes = d[6].toString();
    bytes = bytes.substring(1, bytes.length - 1);
    final len = encodeLength(int.parse((bytes.length / 2).toString()));
    return prefix + len + bytes;
  }

  String staticArrayToHex(List d){
    List matchedArray = d[2];
    final String prefix = '02';
    String content = matchedArray.map((e) => e[0]).join('');
    final len = encodeLength(int.parse((content.length / 2).toString()));
    return prefix + len + content;
  }

  String encodePrimitive(String p){
    String result = '00' + getCodeForKeyword(p).toRadixString(16).toString();
    result = result.substring(result.length - 2);
    return result;
  }

  String primBareToHex(String d){
    final String prefix = '03';
    final String prim = encodePrimitive(d[6].toString());
    return prefix + prim;
  }

  String writeSignedInt(int value){
    if(value == 0){
      return '00';
    }
    final BigInt n = BigInt.from(value).abs();
    final l = n.bitLength.toInt();
    List arr = [];
    BigInt v = n;
    for (var i = 0; i < l; i += 7) {
      BigInt byte = BigInt.zero;
      if(i == 0){
        // byte = v.and(0x3f);
        // v = v.shiftRight(6);
      }
      else{
        // byte = v.and(0x7f);
        // v = v.shiftRight(7);
      }

      if(value < 0 && i == 0){
        // byte = byte.or(0x40);
      }
      
      if(i + 7 < l){
        // byte = byte.or(0x80);
      }
      arr.add(byte.toInt());
    }

    if(l % 7 == 0){
      arr[arr.length - 1] = arr[arr.length - 1] == null ? 0x80 : arr[arr.length - 1];
      arr.add(1);
    }

    var output = arr.map((v){
      int newNum = int.parse(v.toString());
      var str = '0' + newNum.toRadixString(16).toString();
      str = str.substring(str.length - 2);
      return str;
    }).join('');
    return output.substring(output.length - 2);
  }

}
