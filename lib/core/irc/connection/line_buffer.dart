/// Buffers incoming data and extracts complete IRC lines.
///
/// IRC lines are terminated by CRLF (`\r\n`) or just LF (`\n`) for leniency.
class LineBuffer {
  final StringBuffer _buffer = StringBuffer();

  /// Adds data and returns any complete lines.
  ///
  /// Lines are extracted when terminated by LF or CRLF.
  /// Any trailing CR before LF is stripped.
  List<String> addData(String data) {
    _buffer.write(data);
    final content = _buffer.toString();
    final lines = <String>[];

    var start = 0;
    for (var i = 0; i < content.length; i++) {
      if (content[i] == '\n') {
        var end = i;
        // Strip trailing CR if present
        if (end > start && content[end - 1] == '\r') {
          end--;
        }
        lines.add(content.substring(start, end));
        start = i + 1;
      }
    }

    // Keep remaining partial data in buffer
    _buffer.clear();
    if (start < content.length) {
      _buffer.write(content.substring(start));
    }

    return lines;
  }

  /// Clears any buffered partial data.
  void clear() {
    _buffer.clear();
  }

  /// Whether there is partial line data buffered.
  bool get hasPartialLine => _buffer.isNotEmpty;
}
