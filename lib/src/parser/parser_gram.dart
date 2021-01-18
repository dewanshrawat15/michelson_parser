class DemoGrammar {
  id(x) => x[0];

  Map<String, dynamic> get grammar => {
        'Lexer': null,
        'ParserRules': [
          {
            "name": r"main$ebnf$1$subexpression$1",
            "symbols": [
              "statement",
              {"literal": "\n"}
            ]
          },
          {
            "name": r"main$ebnf$1",
            "symbols": [r"main$ebnf$1$subexpression$1"]
          },
          {
            "name": r"main$ebnf$1$subexpression$2",
            "symbols": [
              "statement",
              {"literal": "\n"}
            ]
          },
          {
            "name": r"main$ebnf$1",
            "symbols": [r"main$ebnf$1", r"main$ebnf$1$subexpression$2"],
            "postprocess": arrpush
          },
          {
            "name": "main",
            "symbols": [r"main$ebnf$1"]
          },
          {
            "name": r"statement$string$1",
            "symbols": [
              {"literal": "f"},
              {"literal": "o"},
              {"literal": "o"}
            ],
            "postprocess": joiner
          },
          {
            "name": "statement",
            "symbols": [r"statement$string$1"]
          },
          {
            "name": r"statement$string$2",
            "symbols": [
              {"literal": "b"},
              {"literal": "a"},
              {"literal": "r"}
            ],
            "postprocess": joiner
          },
          {
            "name": "statement",
            "symbols": [r"statement$string$2"]
          },
          {
            "name": r"statement$string$3",
            "symbols": [
              {"literal": "j"},
              {"literal": "a"},
              {"literal": "y"}
            ],
            "postprocess": joiner
          },
          {
            "name": "statement",
            "symbols": [r"statement$string$3"]
          },
          {
            "name": r"statement$string$4",
            "symbols": [
              {"literal": "c"},
              {"literal": "o"},
              {"literal": "w"}
            ],
            "postprocess": joiner
          },
          {
            "name": "statement",
            "symbols": [r"statement$string$4"]
          },
          {
            "name": r"statement$string$5",
            "symbols": [
              {"literal": "h"},
              {"literal": "e"},
              {"literal": "l"},
              {"literal": "l"},
              {"literal": "o"}
            ],
            "postprocess": joiner
          },
          {
            "name": "statement",
            "symbols": [r"statement$string$5"]
          }
        ],
        'ParserStart': "main"
      };

  arrpush(d) => d[0].addAll([d[1]]).toList();

  joiner(d) => d.join('');
}
