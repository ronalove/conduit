import 'package:flutter_test/flutter_test.dart';
import 'package:conduit/core/irc/parser/irc_message.dart';

Matcher isNumeric(int numeric) => _IsNumericMatcher(numeric);

Matcher isCommand(String command) => _IsCommandMatcher(command);

Matcher hasParams(List<String> params) => _HasParamsMatcher(params);

Matcher hasCapability(String cap) => _HasCapabilityMatcher(cap);

class _IsNumericMatcher extends Matcher {
  final int expected;

  _IsNumericMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is IrcMessage) {
      return item.numericValue == expected;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is numeric $expected');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is IrcMessage) {
      return mismatchDescription.add('has command ${item.command}');
    }
    return mismatchDescription.add('is not an IrcMessage');
  }
}

class _IsCommandMatcher extends Matcher {
  final String expected;

  _IsCommandMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is IrcMessage) {
      return item.command.toUpperCase() == expected.toUpperCase();
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is command $expected');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is IrcMessage) {
      return mismatchDescription.add('has command ${item.command}');
    }
    return mismatchDescription.add('is not an IrcMessage');
  }
}

class _HasParamsMatcher extends Matcher {
  final List<String> expected;

  _HasParamsMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is IrcMessage) {
      if (item.params.length < expected.length) return false;
      for (var i = 0; i < expected.length; i++) {
        if (item.params[i] != expected[i]) return false;
      }
      return true;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('has params $expected');
  }
}

class _HasCapabilityMatcher extends Matcher {
  final String expected;

  _HasCapabilityMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is IrcMessage && item.command.toUpperCase() == 'CAP') {
      // CAP responses have capabilities in last param
      if (item.params.length >= 3) {
        final caps = item.params.last.split(' ');
        return caps.any((c) => c == expected || c.startsWith('$expected='));
      }
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('has capability $expected');
  }
}
