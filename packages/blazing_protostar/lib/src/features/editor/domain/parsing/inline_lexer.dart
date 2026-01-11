enum TokenType {
  text,
  star, // *
  underscore, // _
  openBracket, // [
  closeBracket, // ]
  openParen, // (
  closeParen, // )
  backtick, // ` (code)
  escape, // \
}

class Token {
  final TokenType type;
  final String content;
  final int start;
  final int end;

  const Token({
    required this.type,
    required this.content,
    required this.start,
    required this.end,
  });

  @override
  String toString() => 'Token($type, "$content", $start-$end)';
}

/// Scans a raw string into a list of Tokens.
class InlineLexer {
  final String text;
  final int baseOffset; // Absolute offset of this text in the document

  InlineLexer(this.text, {this.baseOffset = 0});

  List<Token> scan() {
    final tokens = <Token>[];
    int index = 0;
    int length = text.length;

    while (index < length) {
      final char = text[index];

      // 1. Escapes: \ + char
      if (char == '\\' && index + 1 < length) {
        // CommonMark: A backslash escapes the following punctuation character.
        // We'll treat it as an EscapeToken containing the full sequence "\c"
        // The parser will decide how to render it (usually just "c").
        // Note: For now, we capture "\c".
        final fullEscape = text.substring(index, index + 2);
        tokens.add(
          Token(
            type: TokenType.escape,
            content: fullEscape,
            start: baseOffset + index,
            end: baseOffset + index + 2,
          ),
        );
        index += 2;
        continue;
      }

      // 2. Delimiters
      TokenType? type;
      if (char == '*') {
        type = TokenType.star;
      } else if (char == '_') {
        type = TokenType.underscore;
      } else if (char == '[') {
        type = TokenType.openBracket;
      } else if (char == ']') {
        type = TokenType.closeBracket;
      } else if (char == '(') {
        type = TokenType.openParen;
      } else if (char == ')') {
        type = TokenType.closeParen;
      } else if (char == '`') {
        type = TokenType.backtick;
      }

      if (type != null) {
        // Emit delimiter token
        tokens.add(
          Token(
            type: type,
            content: char,
            start: baseOffset + index,
            end: baseOffset + index + 1,
          ),
        );
        index++;
        continue;
      }

      // 3. Text
      // Accumulate text until next special char or EOF
      int textEnd = index + 1;
      while (textEnd < length) {
        final nextChar = text[textEnd];
        if (nextChar == '\\' ||
            nextChar == '*' ||
            nextChar == '_' ||
            nextChar == '[' ||
            nextChar == ']' ||
            nextChar == '(' ||
            nextChar == ')' ||
            nextChar == '`') {
          break;
        }
        textEnd++;
      }

      tokens.add(
        Token(
          type: TokenType.text,
          content: text.substring(index, textEnd),
          start: baseOffset + index,
          end: baseOffset + textEnd,
        ),
      );
      index = textEnd;
    }

    return tokens;
  }
}
