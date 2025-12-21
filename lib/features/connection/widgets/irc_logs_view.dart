import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Descriptions for IRC commands and numerics.
const Map<String, String> ircCommandDescriptions = {
  // Named commands
  'PING': 'Test de connexion (serveur)',
  'PONG': 'Reponse au test de connexion',
  'JOIN': 'Rejoindre un canal',
  'PART': 'Quitter un canal',
  'QUIT': 'Deconnexion du serveur',
  'PRIVMSG': 'Message prive ou de canal',
  'NOTICE': 'Notice (message systeme)',
  'NICK': 'Changement de pseudo',
  'MODE': 'Changement de mode',
  'KICK': 'Expulsion d\'un canal',
  'INVITE': 'Invitation a un canal',
  'TOPIC': 'Sujet du canal',
  'CAP': 'Negociation des capacites',
  'AUTHENTICATE': 'Authentification SASL',
  'ACCOUNT': 'Changement de compte',
  'CHGHOST': 'Changement d\'hote',
  'SETNAME': 'Changement de realname',
  'AWAY': 'Statut absence',
  'BATCH': 'Lot de messages',
  'TAGMSG': 'Message avec tags uniquement',
  'MARKREAD': 'Marqueur de lecture',
  'CHATHISTORY': 'Historique des messages',
  'WHO': 'Information utilisateur',
  'WHOIS': 'Information detaillee utilisateur',
  'LIST': 'Liste des canaux',
  'NAMES': 'Liste des utilisateurs du canal',
  'MONITOR': 'Surveillance de connexion',
  'ACK': 'Accusé de reception',
  // Numerics - Registration
  '001': 'RPL_WELCOME - Message de bienvenue',
  '002': 'RPL_YOURHOST - Info serveur hote',
  '003': 'RPL_CREATED - Date creation serveur',
  '004': 'RPL_MYINFO - Info serveur',
  '005': 'RPL_ISUPPORT - Capacites du serveur',
  // Numerics - Stats
  '221': 'RPL_UMODEIS - Modes utilisateur',
  '251': 'RPL_LUSERCLIENT - Stats clients',
  '252': 'RPL_LUSEROP - Nombre d\'operateurs',
  '253': 'RPL_LUSERUNKNOWN - Connexions inconnues',
  '254': 'RPL_LUSERCHANNELS - Nombre de canaux',
  '255': 'RPL_LUSERME - Stats serveur local',
  // Numerics - Away/User
  '301': 'RPL_AWAY - Message d\'absence',
  '302': 'RPL_USERHOST - Info hote utilisateur',
  '303': 'RPL_ISON - Utilisateur en ligne',
  '305': 'RPL_UNAWAY - Plus absent',
  '306': 'RPL_NOWAWAY - Maintenant absent',
  '311': 'RPL_WHOISUSER - WHOIS info utilisateur',
  '312': 'RPL_WHOISSERVER - WHOIS serveur',
  '313': 'RPL_WHOISOPERATOR - WHOIS operateur',
  '314': 'RPL_WHOWASUSER - WHOWAS info',
  '315': 'RPL_ENDOFWHO - Fin de WHO',
  '317': 'RPL_WHOISIDLE - WHOIS temps inactif',
  '318': 'RPL_ENDOFWHOIS - Fin de WHOIS',
  '319': 'RPL_WHOISCHANNELS - WHOIS canaux',
  // Numerics - Channel
  '322': 'RPL_LIST - Liste des canaux',
  '323': 'RPL_LISTEND - Fin de liste',
  '324': 'RPL_CHANNELMODEIS - Modes du canal',
  '331': 'RPL_NOTOPIC - Pas de sujet',
  '332': 'RPL_TOPIC - Sujet du canal',
  '333': 'RPL_TOPICWHOTIME - Info sujet',
  '341': 'RPL_INVITING - Confirmation invitation',
  '352': 'RPL_WHOREPLY - Reponse WHO',
  '353': 'RPL_NAMREPLY - Liste des noms',
  '354': 'RPL_WHOSPCRPL - Reponse WHOX',
  '366': 'RPL_ENDOFNAMES - Fin des noms',
  '368': 'RPL_ENDOFBANLIST - Fin liste bans',
  '369': 'RPL_ENDOFWHOWAS - Fin de WHOWAS',
  // Numerics - MOTD
  '372': 'RPL_MOTD - Ligne MOTD',
  '375': 'RPL_MOTDSTART - Debut MOTD',
  '376': 'RPL_ENDOFMOTD - Fin MOTD',
  // Numerics - Ergo specific
  '379': 'RPL_WHOISMODES - Modes utilisateur WHOIS',
  // Numerics - Errors
  '401': 'ERR_NOSUCHNICK - Nick inexistant',
  '402': 'ERR_NOSUCHSERVER - Serveur inexistant',
  '403': 'ERR_NOSUCHCHANNEL - Canal inexistant',
  '404': 'ERR_CANNOTSENDTOCHAN - Envoi impossible',
  '405': 'ERR_TOOMANYCHANNELS - Trop de canaux',
  '421': 'ERR_UNKNOWNCOMMAND - Commande inconnue',
  '422': 'ERR_NOMOTD - Pas de MOTD',
  '432': 'ERR_ERRONEUSNICKNAME - Nick invalide',
  '433': 'ERR_NICKNAMEINUSE - Nick deja utilise',
  '442': 'ERR_NOTONCHANNEL - Pas sur le canal',
  '451': 'ERR_NOTREGISTERED - Non enregistre',
  '461': 'ERR_NEEDMOREPARAMS - Parametres manquants',
  '462': 'ERR_ALREADYREGISTERED - Deja enregistre',
  '473': 'ERR_INVITEONLYCHAN - Canal sur invitation',
  '474': 'ERR_BANNEDFROMCHAN - Banni du canal',
  '475': 'ERR_BADCHANNELKEY - Mauvais mot de passe',
  '482': 'ERR_CHANOPRIVSNEEDED - Droits op requis',
  // Numerics - SASL
  '900': 'RPL_LOGGEDIN - Connecte au compte',
  '901': 'RPL_LOGGEDOUT - Deconnecte du compte',
  '903': 'RPL_SASLSUCCESS - SASL reussi',
  '904': 'ERR_SASLFAIL - SASL echoue',
  '905': 'ERR_SASLTOOLONG - SASL trop long',
  '906': 'ERR_SASLABORTED - SASL annule',
  '907': 'ERR_SASLALREADY - Deja authentifie',
  '908': 'RPL_SASLMECHS - Mecanismes SASL',
};

/// IRC color palette (mIRC colors).
const List<Color> ircColors = [
  Color(0xFFFFFFFF), // 0: white
  Color(0xFF000000), // 1: black
  Color(0xFF00007F), // 2: blue (navy)
  Color(0xFF009300), // 3: green
  Color(0xFFFF0000), // 4: red
  Color(0xFF7F0000), // 5: brown (maroon)
  Color(0xFF9C009C), // 6: purple
  Color(0xFFFC7F00), // 7: orange
  Color(0xFFFFFF00), // 8: yellow
  Color(0xFF00FC00), // 9: light green
  Color(0xFF009393), // 10: cyan (teal)
  Color(0xFF00FFFF), // 11: light cyan
  Color(0xFF0000FC), // 12: light blue
  Color(0xFFFF00FF), // 13: pink
  Color(0xFF7F7F7F), // 14: grey
  Color(0xFFD2D2D2), // 15: light grey
];

/// A segment of formatted IRC text.
class IrcTextSegment {
  final String text;
  final Color? foreground;
  final Color? background;
  final bool bold;
  final bool italic;
  final bool underline;

  const IrcTextSegment({
    required this.text,
    this.foreground,
    this.background,
    this.bold = false,
    this.italic = false,
    this.underline = false,
  });
}

/// Parse IRC formatted text into segments.
List<IrcTextSegment> parseIrcFormatting(String text) {
  final segments = <IrcTextSegment>[];
  final buffer = StringBuffer();

  Color? currentFg;
  Color? currentBg;
  bool bold = false;
  bool italic = false;
  bool underline = false;

  void flushBuffer() {
    if (buffer.isNotEmpty) {
      segments.add(IrcTextSegment(
        text: buffer.toString(),
        foreground: currentFg,
        background: currentBg,
        bold: bold,
        italic: italic,
        underline: underline,
      ));
      buffer.clear();
    }
  }

  int i = 0;
  while (i < text.length) {
    final char = text[i];
    final code = char.codeUnitAt(0);

    switch (code) {
      case 0x02: // Bold
        flushBuffer();
        bold = !bold;
        i++;
      case 0x1D: // Italic
        flushBuffer();
        italic = !italic;
        i++;
      case 0x1F: // Underline
        flushBuffer();
        underline = !underline;
        i++;
      case 0x0F: // Reset
        flushBuffer();
        currentFg = null;
        currentBg = null;
        bold = false;
        italic = false;
        underline = false;
        i++;
      case 0x03: // Color
        flushBuffer();
        i++;
        // Parse foreground color
        String fgStr = '';
        while (i < text.length && text[i].codeUnitAt(0) >= 0x30 && text[i].codeUnitAt(0) <= 0x39 && fgStr.length < 2) {
          fgStr += text[i];
          i++;
        }
        if (fgStr.isNotEmpty) {
          final fg = int.tryParse(fgStr);
          if (fg != null && fg < ircColors.length) {
            currentFg = ircColors[fg];
          }
        } else {
          // Reset colors if no number follows
          currentFg = null;
          currentBg = null;
        }
        // Parse background color if comma present
        if (i < text.length && text[i] == ',') {
          i++;
          String bgStr = '';
          while (i < text.length && text[i].codeUnitAt(0) >= 0x30 && text[i].codeUnitAt(0) <= 0x39 && bgStr.length < 2) {
            bgStr += text[i];
            i++;
          }
          if (bgStr.isNotEmpty) {
            final bg = int.tryParse(bgStr);
            if (bg != null && bg < ircColors.length) {
              currentBg = ircColors[bg];
            }
          }
        }
      case 0x16: // Reverse (swap fg/bg)
        flushBuffer();
        final temp = currentFg;
        currentFg = currentBg;
        currentBg = temp;
        i++;
      case 0x1E: // Strikethrough (ignore for now)
      case 0x11: // Monospace (ignore, already monospace)
        i++;
      default:
        buffer.write(char);
        i++;
    }
  }

  flushBuffer();
  return segments;
}

/// Parsed IRC log line for display.
class ParsedIrcLog {
  final DateTime? timestamp;
  final String? source;
  final String command;
  final String content;
  final String raw;

  ParsedIrcLog({
    this.timestamp,
    this.source,
    required this.command,
    required this.content,
    required this.raw,
  });

  /// Parse a raw IRC line into structured data.
  factory ParsedIrcLog.parse(String line) {
    DateTime? timestamp;
    String? source;
    String command = '';
    String content = '';
    String remaining = line;

    // Extract @time tag
    if (remaining.startsWith('@')) {
      final spaceIdx = remaining.indexOf(' ');
      if (spaceIdx != -1) {
        final tags = remaining.substring(1, spaceIdx);
        remaining = remaining.substring(spaceIdx + 1);

        // Parse time=... tag
        for (final tag in tags.split(';')) {
          if (tag.startsWith('time=')) {
            final timeStr = tag.substring(5);
            try {
              timestamp = DateTime.parse(timeStr);
            } catch (_) {}
          }
        }
      }
    }

    // Extract :source
    if (remaining.startsWith(':')) {
      final spaceIdx = remaining.indexOf(' ');
      if (spaceIdx != -1) {
        source = remaining.substring(1, spaceIdx);
        // Simplify source (remove user!ident@host, keep just nick or server)
        if (source.contains('!')) {
          source = source.split('!').first;
        }
        remaining = remaining.substring(spaceIdx + 1);
      }
    }

    // Extract command and content
    final parts = remaining.split(' ');
    if (parts.isNotEmpty) {
      command = parts.first;
      if (parts.length > 1) {
        content = parts.sublist(1).join(' ');
        // Remove leading : from content if present
        if (content.startsWith(':')) {
          content = content.substring(1);
        }
      }
    }

    return ParsedIrcLog(
      timestamp: timestamp,
      source: source,
      command: command,
      content: content,
      raw: line,
    );
  }

  /// Get color for numeric command.
  Color get commandColor {
    // Try to parse as number
    final num = int.tryParse(command);
    if (num != null) {
      // Color based on numeric range
      if (num >= 001 && num <= 005) return const Color(0xFF4CAF50); // Welcome (green)
      if (num >= 250 && num <= 266) return const Color(0xFF2196F3); // Stats (blue)
      if (num >= 301 && num <= 319) return const Color(0xFF9C27B0); // User info (purple)
      if (num >= 321 && num <= 323) return const Color(0xFFFF9800); // Channel list (orange)
      if (num >= 331 && num <= 333) return const Color(0xFF00BCD4); // Topic (cyan)
      if (num >= 351 && num <= 369) return const Color(0xFF795548); // Version/info (brown)
      if (num >= 371 && num <= 376) return const Color(0xFF607D8B); // MOTD (gray-blue)
      if (num >= 400 && num <= 499) return const Color(0xFFF44336); // Errors (red)
      if (num >= 900 && num <= 999) return const Color(0xFF8BC34A); // SASL (light green)
      // Default for other numerics
      return const Color(0xFF78909C);
    }

    // Named commands
    return switch (command) {
      'PING' || 'PONG' => const Color(0xFF9E9E9E),
      'JOIN' => const Color(0xFF4CAF50),
      'PART' || 'QUIT' => const Color(0xFFF44336),
      'PRIVMSG' => const Color(0xFF2196F3),
      'NOTICE' => const Color(0xFFFF9800),
      'NICK' => const Color(0xFF9C27B0),
      'MODE' => const Color(0xFF00BCD4),
      'CAP' => const Color(0xFF795548),
      'AUTHENTICATE' => const Color(0xFF8BC34A),
      _ => AppColors.textSecondary,
    };
  }

  bool get isNumeric => int.tryParse(command) != null;

  /// Get description for the command.
  String get commandDescription {
    return ircCommandDescriptions[command] ?? command;
  }

  /// Get content with the current nick removed from the beginning.
  String contentWithoutNick(String? currentNick) {
    if (currentNick == null || content.isEmpty) return content;

    // Check if content starts with the current nick (case insensitive)
    final lowerContent = content.toLowerCase();
    final lowerNick = currentNick.toLowerCase();

    if (lowerContent.startsWith(lowerNick)) {
      final afterNick = content.substring(currentNick.length);
      // Remove leading space or colon after nick
      if (afterNick.startsWith(' ')) {
        return afterNick.substring(1);
      }
      if (afterNick.startsWith(':')) {
        return afterNick.substring(1);
      }
      // If nothing follows or next char is part of the nick, return original
      if (afterNick.isEmpty || afterNick[0].contains(RegExp(r'[a-zA-Z0-9]'))) {
        return content;
      }
      return afterNick;
    }

    return content;
  }
}

/// Widget to display IRC logs in a clean format.
class IrcLogsView extends StatelessWidget {
  const IrcLogsView({
    super.key,
    required this.logs,
    this.currentNick,
  });

  final List<String> logs;
  final String? currentNick;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.terminal, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Aucun log',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SelectionArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.sm),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final parsed = ParsedIrcLog.parse(logs[index]);
          return _LogLine(log: parsed, currentNick: currentNick);
        },
      ),
    );
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.log, this.currentNick});

  final ParsedIrcLog log;
  final String? currentNick;

  @override
  Widget build(BuildContext context) {
    final displayContent = log.contentWithoutNick(currentNick);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp icon with tooltip
          if (log.timestamp != null)
            Tooltip(
              message: _formatDateTime(log.timestamp!),
              child: Icon(
                Icons.schedule,
                size: 14,
                color: AppColors.textTertiary,
              ),
            )
          else
            const SizedBox(width: 14),

          const SizedBox(width: 6),

          // Source icon with tooltip
          if (log.source != null)
            Tooltip(
              message: log.source!,
              child: Icon(
                Icons.alternate_email,
                size: 14,
                color: AppColors.textTertiary,
              ),
            )
          else
            const SizedBox(width: 14),

          const SizedBox(width: 6),

          // Command badge with tooltip
          Tooltip(
            message: log.commandDescription,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: log.commandColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                log.command,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const ['Menlo', 'Consolas', 'Courier New', 'Courier'],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: log.commandColor,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Content with IRC formatting
          Expanded(
            child: _buildFormattedContent(displayContent),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String content) {
    final segments = parseIrcFormatting(content);

    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    const monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: ['Menlo', 'Consolas', 'Courier New', 'Courier'],
      fontSize: 11,
      color: AppColors.textSecondary,
    );

    // If no formatting, use simple Text
    if (segments.length == 1 && segments.first.foreground == null && !segments.first.bold) {
      return Text(
        segments.first.text,
        style: monoStyle,
      );
    }

    // Build RichText with formatted spans
    return RichText(
      text: TextSpan(
        style: monoStyle,
        children: segments.map((segment) {
          return TextSpan(
            text: segment.text,
            style: TextStyle(
              color: segment.foreground ?? AppColors.textSecondary,
              backgroundColor: segment.background,
              fontWeight: segment.bold ? FontWeight.bold : FontWeight.normal,
              fontStyle: segment.italic ? FontStyle.italic : FontStyle.normal,
              decoration: segment.underline ? TextDecoration.underline : TextDecoration.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
