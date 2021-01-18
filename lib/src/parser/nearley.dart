import 'dart:convert';
import 'dart:math';

import 'package:michelson_parser/src/parser/parser_gram.dart';

var fail = {};

class Nearley {
  static var start;
  static NearleyGrammar grammar;

  static var lexerState;

  List<Column> table;

  int current;

  var lexer;

  Map<String, dynamic> options;

  var results;

  static NearleyGrammar fromCompiled(DemoGrammar rules, {var start}) {
    var lexer = rules.grammar['Lexer'];
    var redefiendRule;
    if (rules.grammar.containsKey('ParserStart')) {
      start = rules.grammar['ParserStart'];
      redefiendRule = rules.grammar['ParserRules'];
    }
    List<Rule> _rules = redefiendRule
        .map<Rule>(
          (e) => Rule(
            e['name'],
            e['symbols'],
            e['postprocess'],
          ),
        )
        .toList();
    var g = NearleyGrammar(_rules, start);
    g.lexer = lexer;
    return g;
  }

  parser(NearleyGrammar fromCompiled) {
    grammar = fromCompiled;

    options = {
      'keepHistory': false,
      'lexer': grammar.lexer ?? new StreamLexer(),
    };

    //  for (var key in (options || {})) {
    //         this.options[key] = options[key];
    //     }

    // Setup lexer
    this.lexer = options['lexer'];
    lexerState = null;

    // Setup a table
    var column = new Column(grammar, 0);
    table = [column];

    // I could be expecting anything.
    column.wants[grammar.start] = [];
    column.predict(grammar.start);
    // ignore: todo
    // TODO what if start rule is nullable?
    column.process();
    this.current = 0; // token index
  }

  feed(String chunk) {
    var lexer = this.lexer;
    lexer.reset(chunk, state: lexerState);
    var column;
    var token;
    while (true) {
      try {
        token = lexer.next();
        if (token == null) {
          break;
        }
      } catch (e) {
        // Create the next column so that the error reporter
        // can display the correctly predicted states.
        var nextColumn = new Column(grammar, this.current + 1);
        this.table.add(nextColumn);
        var err = new NearleyError(reportLexerError(e));
        err.offset = this.current;
        err.token = e.token;
        throw err;
      }
      // We add new states to table[current+1]
      column = this.table[this.current];

      // GC unused states
      if (!options['keepHistory'] && this.current != 0) {
        table[this.current - 1] = null;
      }

      var n = this.current + 1;
      var nextColumn = new Column(grammar, n);
      this.table.add(nextColumn);

      // Advance all tokens that expect the symbol
      var literal = token['text'] != null ? token['text'] : token['value'];
      var value = lexer is StreamLexer ? token['value'] : token;
      var scannable = column.scannable;
      for (var w = scannable.length - 1; 0 <= w; --w) {
        var state = scannable[w] ?? null;
        var expect = state.rule.symbols[state.dot];
        // Try to consume the token
        // either regex or literal
        if (expect['test'] != null
            ? expect.test(value)
            : expect['type'] != null
                ? expect['type'] == token['type']
                : expect['literal'] == literal) {
          // Add it
          var next = state.nextState({
            'data': value,
            'token': token,
            'isToken': true,
            'reference': n - 1
          });
          nextColumn.states.add(next);
        }
      }

      // Next, for each of the rules, we either
      // (a) complete it, and try to see if the reference row expected that
      //     rule
      // (b) predict the next nonterminal it expects by adding that
      //     nonterminal's start state
      // To prevent duplication, we also keep track of rules we have already
      // added

      nextColumn.process();

      // If needed, throw an error:
      if (nextColumn.states.length == 0) {
        // No states at all! This is not good.
        var err = new NearleyError(reportError(token));
        err.offset = this.current;
        err.token = token;
        throw Exception(err.error);
      }

      // maybe save lexer state
      if (this.options['keepHistory'] != null) {
        column.lexerState = lexer.save();
      }

      this.current++;
    }
    if (column != null) {
      lexerState = lexer.save();
    }

    // Incrementally keep track of results
    this.results = this.finish();

    // Allow chaining, for whatever it's worth
    return results;
  }

  finish() {
    // Return the possible parsings
    var considerations = [];
    var start = grammar.start;
    var column = this.table[this.table.length - 1];
    column.states.forEach((t) {
      if (t.rule.name == start &&
          t.dot == t.rule.symbols.length &&
          t.reference == 0 &&
          t.data != fail) {
        considerations.add(t);
      }
    });
    return considerations.map((c) {
      return c.data;
    }).toList();
  }

  reportError(token) {
    var tokenDisplay =
        (token['type'] != null ? token['type'] + " token: " : "") +
            jsonEncode(token['value'] != null ? token['value'] : token);
    var lexerMessage = this.lexer.formatError(token, "Syntax error");
    return this.reportErrorCommon(lexerMessage, tokenDisplay);
  }

  String reportLexerError(lexerError) {
    var tokenDisplay, lexerMessage;
    // Planning to add a token property to moo's thrown error
    // even on erroring tokens to be used in error display below
    var token = lexerError.token;
    if (token) {
      tokenDisplay = "input " + jsonEncode(token.text[0]) + " (lexer error)";
      lexerMessage = this.lexer.formatError(token, "Syntax error");
    } else {
      tokenDisplay = "input (lexer error)";
      lexerMessage = lexerError.message;
    }
    return this.reportErrorCommon(lexerMessage, tokenDisplay);
  }

  reportErrorCommon(lexerMessage, tokenDisplay) {
    var lines = [];
    lines.add(lexerMessage);
    var lastColumnIndex = this.table.length - 2;
    var lastColumn = this.table[lastColumnIndex];
    var expectantStates = lastColumn.states.where((state) {
      var nextSymbol = state.rule.symbols[state.dot] ?? null;
      return nextSymbol != null && !(nextSymbol is String);
    }).toList();

    if (expectantStates.length == 0) {
      lines.add('Unexpected ' +
          tokenDisplay +
          '. I did not expect any more input. Here is the state of my parse table:\n');
      this.displayStateStack(lastColumn.states, lines);
    } else {
      lines.add('Unexpected ' +
          tokenDisplay +
          '. Instead, I was expecting to see one of the following:\n');
      // Display a "state stack" for each expectant state
      // - which shows you how this state came to be, step by step.
      // If there is more than one derivation, we only display the first one.
      var stateStacks = expectantStates.map((state) {
        return this.buildFirstStateStack(state, []) ?? [state];
      });
      // Display each state that is expecting a terminal symbol next.
      stateStacks.forEach((stateStack) {
        var state = stateStack[0];
        var nextSymbol = state.rule.symbols[state.dot];
        var symbolDisplay = this.getSymbolDisplay(nextSymbol);
        lines.add('A ' + symbolDisplay + ' based on:');
        this.displayStateStack(stateStack, lines);
      });
    }
    lines.add("");
    return lines.join("\n");
  }

  buildFirstStateStack(state, visited) {
    if (visited.indexOf(state) != -1) {
      // Found cycle, return null
      // to eliminate this path from the results, because
      // we don't know how to display it meaningfully
      return null;
    }
    if (state.wantedBy.length == 0) {
      return [state];
    }
    var prevState = state.wantedBy[0];
    var childVisited = [state]..addAll(visited);
    var childResult = this.buildFirstStateStack(prevState, childVisited);
    if (childResult == null) {
      return null;
    }
    return [state].addAll(childResult);
  }

  displayStateStack(stateStack, lines) {
    var lastDisplay;
    var sameDisplayCount = 0;
    for (var j = 0; j < stateStack.length; j++) {
      var state = stateStack[j];
      var display = state.rule.toStringWithData(state.dot);
      if (display == lastDisplay) {
        sameDisplayCount++;
      } else {
        if (sameDisplayCount > 0) {
          lines.add('    ^ ' +
              sameDisplayCount.toString() +
              ' more lines identical to this');
        }
        sameDisplayCount = 0;
        lines.add('    ' + display);
      }
      lastDisplay = display;
    }
  }

  getSymbolDisplay(symbol) {
    return getSymbolLongDisplay(symbol);
  }

  getSymbolLongDisplay(symbol) {
    // var type = typeof symbol;
    if (symbol is String) {
      return symbol;
    } else if (symbol is Map) {
      if (symbol['literal'] != null) {
        return jsonEncode(symbol['literal']);
      } else if (symbol is RegExp) {
        return 'character matching ' + symbol.toString();
      } else if (symbol['type'] != null) {
        return symbol['type'] + ' token';
      } else if (symbol['test'] != null) {
        return 'token matching ' + symbol['test'].toString();
      } else {
        throw new Exception('Unknown symbol type: ' + symbol.toString());
      }
    }
  }
}

class NearleyError {
  var error;
  int offset;
  var token;
  NearleyError(this.error);
}

class NearleyGrammar {
  List<Rule> rules;
  var start;

  var lexer;
  var byName;

  NearleyGrammar(this.rules, this.start) {
    this.rules = rules;
    this.start = start ?? this.rules[0].name;
    var byName = this.byName = {};
    this.rules.forEach((rule) {
      if (!byName.containsKey(rule.name)) {
        byName[rule.name] = [];
      }
      byName[rule.name].add(rule);
      // byName[rule.name] is List ? byName[rule.name] : [rule];
    });
  }
}

class Rule {
  var name;
  var symbols;
  var postprocess;
  Rule(this.name, this.symbols, this.postprocess);

  getSymbolShortDisplay(symbol) {
    // var type = typeof symbol;
    if (symbols is String) {
      return symbol;
    } else if (symbols is Map) {
      if (symbol.literal) {
        return jsonEncode(symbol.literal);
      } else if (symbol is RegExp) {
        return symbol.toString();
      } else if (symbol['type'] != null) {
        return '%' + symbol['type'];
      } else if (symbol['test'] != null) {
        return '<' + (symbol['test']).toString() + '>';
      } else {
        throw new NearleyError('Unknown symbol type: ' + symbol.toString());
      }
    }
  }

  toStringWithData(withCursorAt) {
    var symbolSequence = (withCursorAt == null)
        ? this.symbols.map(getSymbolShortDisplay).join(' ')
        : (this
                .symbols
                .sublist(0, withCursorAt)
                .map(getSymbolShortDisplay)
                .join(' ') +
            " ● " +
            this
                .symbols
                .sublist(withCursorAt)
                .map(getSymbolShortDisplay)
                .join(' '));
    return this.name + " → " + symbolSequence;
  }
}

class StreamLexer {
  var buffer;
  int index;
  var line;
  var lastLineBreak;

  StreamLexer() {
    this.reset("");
  }

  has(tokenType) {
    return true;
  }

  reset(data, {state}) {
    this.buffer = data;
    this.index = 0;
    this.line = state != null ? state.line : 1;
    this.lastLineBreak = state != null ? -state.col : 0;
  }

  next() {
    if (this.index < this.buffer.length) {
      var ch = this.buffer[this.index++];
      if (ch == '\n') {
        this.line += 1;
        this.lastLineBreak = this.index;
      }
      return {'value': ch};
    }
  }

  save() {
    return {
      'line': this.line,
      'col': this.index - this.lastLineBreak,
    };
  }

  formatError(token, message) {
    pad(n, length) {
      var s = (n).toString();
      return List.generate(length - s.length + 1, (index) => '').join(" ") + s;
    }

    // nb. this gets called after consuming the offending token,
    // so the culprit is index-1
    var buffer = this.buffer;
    if (buffer is String) {
      var lines = buffer.split("\n").sublist(max(0, this.line - 5), this.line);

      var nextLineBreak = buffer.indexOf('\n', this.index);
      if (nextLineBreak == -1) nextLineBreak = buffer.length;
      var col = this.index - this.lastLineBreak;
      var lastLineDigits = (this.line).toString().length;
      message += " at line " +
          this.line.toString() +
          " col " +
          col.toString() +
          ":\n\n";
      var msg = List();
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        msg.add(
            pad(this.line - lines.length + i + 1, lastLineDigits) + " " + line);
      }
      message += msg.join("\n");
      // lines
      //     .map((line, i) {
      //         return pad(this.line - lines.length + i + 1, lastLineDigits) + " " + line;
      //     })
      //     .join("\n");
      message += "\n" + pad("", lastLineDigits + col) + "^\n";
      return message;
    } else {
      return message + " at index " + (this.index - 1);
    }
  }
}

class Column {
  var grammar;

  var index;

  List states;

  Map wants;

  List scannable;

  Map completed;

  var lexerState;

  Column(grammar, index) {
    this.grammar = grammar;
    this.index = index;
    this.states = [];
    this.wants = {}; // states indexed by the non-terminal they expect
    this.scannable = []; // list of states that expect a token
    this.completed = {}; // states that are nullable
  }

  process({nextColumn}) {
    var states = this.states;
    var wants = this.wants;
    var completed = this.completed;

    for (var w = 0; w < states.length; w++) {
      // nb. we push() during iteration
      var state = states[w];

      if (state.isComplete) {
        state.finish();
        if (state.data != fail) {
          // complete
          var wantedBy = state.wantedBy;
          for (var i = wantedBy.length - 1; 0 <= i; i--) {
            // this line is hot
            var left = wantedBy[i];
            this.complete(left, state);
          }

          // special-case nullables
          if (state.reference == this.index) {
            // make sure future predictors of this rule get completed.
            var exp = state.rule.name;
            (this.completed[exp] = this.completed[exp] ?? []).add(state);
          }
        }
      } else {
        // queue scannable states
        var exp = state.rule.symbols[state.dot];
        if (!(exp is String)) {
          this.scannable.add(state);
          continue;
        }

        // predict
        if (wants[exp] != null) {
          wants[exp] = (state);

          if (completed.containsKey(exp)) {
            var nulls = completed[exp];
            for (var i = 0; i < nulls.length; i++) {
              var right = nulls[i];
              this.complete(state, right);
            }
          }
        } else {
          wants[exp] = [state];
          this.predict(exp);
        }
      }
    }
  }

  predict(exp) {
    var rules = <Rule>[...this.grammar.byName[exp]] ?? [];

    for (var i = 0; i < rules.length; i++) {
      var r = rules[i];
      var wantedBy = this.wants[exp];
      var s = new State(r, 0, this.index, wantedBy);
      this.states.add(s);
    }
  }

  complete(left, right) {
    var copy = left.nextState(right);
    this.states.add(copy);
  }
}

class State {
  var rule;
  var dot;
  var reference;
  var data;
  var wantedBy;
  bool isComplete;
  var left;
  var right;

  State(rule, dot, reference, wantedBy) {
    this.rule = rule;
    this.dot = dot;
    this.reference = reference;
    this.data = [];
    this.wantedBy = wantedBy;
    this.isComplete = this.dot == rule.symbols.length;
  }

  toString() {
    return "{" +
        this.rule.toString(this.dot) +
        "}, from: " +
        (this.reference ?? 0);
  }

  nextState(child) {
    var state =
        new State(this.rule, this.dot + 1, this.reference, this.wantedBy);
    state.left = this;
    state.right = child;
    if (state.isComplete) {
      state.data = state.build();
      // Having right set here will prevent the right state and its children
      // form being garbage collected
      state.right = null;
    }
    return state;
  }

  build() {
    var children = [];
    var node = this;
    do {
      children.add(node.right is State ? node.right.data : node.right['data']);
      node = node.left;
    } while (node.left != null);
    children = children.reversed.toList();
    return children;
  }

  finish() {
    if (this.rule.postprocess != null) {
      this.data = this.rule.postprocess(this.data);
    }
  }
}
