/// IRC numeric reply codes.
///
/// See: https://modern.ircdocs.horse/#numerics
abstract class IrcNumerics {
  // ===== Registration (001-005) =====

  /// Welcome message with full client identifier.
  static const rplWelcome = 001;

  /// Server host info.
  static const rplYourHost = 002;

  /// Server creation date.
  static const rplCreated = 003;

  /// Server info: name, version, user modes, channel modes.
  static const rplMyInfo = 004;

  /// ISUPPORT tokens describing server capabilities.
  static const rplISupport = 005;

  // ===== Command responses =====

  /// User mode string.
  static const rplUModeIs = 221;

  /// Start of LUSERS output.
  static const rplLUserClient = 251;

  /// Number of operators online.
  static const rplLUserOp = 252;

  /// Number of unknown connections.
  static const rplLUserUnknown = 253;

  /// Number of channels.
  static const rplLUserChannels = 254;

  /// Server client/server count.
  static const rplLUserMe = 255;

  /// Away message.
  static const rplAway = 301;

  /// User host info.
  static const rplUserHost = 302;

  /// User is on IRC.
  static const rplIsOn = 303;

  /// Unaway confirmation.
  static const rplUnaway = 305;

  /// Now marked as away.
  static const rplNowAway = 306;

  /// WHOIS reply: user info.
  static const rplWhoisUser = 311;

  /// WHOIS reply: server.
  static const rplWhoisServer = 312;

  /// WHOIS reply: operator.
  static const rplWhoisOperator = 313;

  /// WHOWAS reply.
  static const rplWhoWasUser = 314;

  /// End of WHO.
  static const rplEndOfWho = 315;

  /// WHOIS reply: idle time.
  static const rplWhoisIdle = 317;

  /// End of WHOIS.
  static const rplEndOfWhois = 318;

  /// WHOIS reply: channels.
  static const rplWhoisChannels = 319;

  /// List mode entry.
  static const rplList = 322;

  /// End of LIST.
  static const rplListEnd = 323;

  /// Channel modes.
  static const rplChannelModeIs = 324;

  /// No topic set.
  static const rplNoTopic = 331;

  /// Channel topic.
  static const rplTopic = 332;

  /// Topic set by (who and when).
  static const rplTopicWhoTime = 333;

  /// Invite confirmation.
  static const rplInviting = 341;

  /// WHO reply line.
  static const rplWhoReply = 352;

  /// Names list.
  static const rplNamReply = 353;

  /// End of names list.
  static const rplEndOfNames = 366;

  /// End of ban list.
  static const rplEndOfBanList = 368;

  /// End of WHOWAS.
  static const rplEndOfWhoWas = 369;

  /// MOTD line.
  static const rplMotd = 372;

  /// Start of MOTD.
  static const rplMotdStart = 375;

  /// End of MOTD.
  static const rplEndOfMotd = 376;

  // ===== Errors (4xx) =====

  /// No such nick/channel.
  static const errNoSuchNick = 401;

  /// No such server.
  static const errNoSuchServer = 402;

  /// No such channel.
  static const errNoSuchChannel = 403;

  /// Cannot send to channel.
  static const errCannotSendToChan = 404;

  /// Too many channels joined.
  static const errTooManyChannels = 405;

  /// Was no such nick.
  static const errWasNoSuchNick = 406;

  /// Too many targets.
  static const errTooManyTargets = 407;

  /// No origin specified.
  static const errNoOrigin = 409;

  /// No recipient given.
  static const errNoRecipient = 411;

  /// No text to send.
  static const errNoTextToSend = 412;

  /// Input line too long.
  static const errInputTooLong = 417;

  /// Unknown command.
  static const errUnknownCommand = 421;

  /// No MOTD.
  static const errNoMotd = 422;

  /// No nickname given.
  static const errNoNicknameGiven = 431;

  /// Erroneous nickname.
  static const errErroneusNickname = 432;

  /// Nickname in use.
  static const errNicknameInUse = 433;

  /// Nick collision.
  static const errNickCollision = 436;

  /// User not in channel.
  static const errUserNotInChannel = 441;

  /// Not on channel.
  static const errNotOnChannel = 442;

  /// User already on channel.
  static const errUserOnChannel = 443;

  /// Not registered.
  static const errNotRegistered = 451;

  /// Need more params.
  static const errNeedMoreParams = 461;

  /// Already registered.
  static const errAlreadyRegistered = 462;

  /// Password mismatch.
  static const errPasswdMismatch = 464;

  /// Banned from server.
  static const errYoureBannedCreep = 465;

  /// Channel is full.
  static const errChannelIsFull = 471;

  /// Unknown mode.
  static const errUnknownMode = 472;

  /// Invite only channel.
  static const errInviteOnlyChan = 473;

  /// Banned from channel.
  static const errBannedFromChan = 474;

  /// Bad channel key.
  static const errBadChannelKey = 475;

  /// Bad channel mask.
  static const errBadChanMask = 476;

  /// No privileges.
  static const errNoPrivileges = 481;

  /// Channel operator privileges needed.
  static const errChanOpPrivsNeeded = 482;

  /// Can't kill server.
  static const errCantKillServer = 483;

  // ===== SASL =====

  /// SASL logged in.
  static const rplLoggedIn = 900;

  /// SASL logged out.
  static const rplLoggedOut = 901;

  /// SASL successful.
  static const rplSaslSuccess = 903;

  /// SASL failed.
  static const errSaslFail = 904;

  /// SASL too long.
  static const errSaslTooLong = 905;

  /// SASL aborted.
  static const errSaslAborted = 906;

  /// SASL already authenticated.
  static const errSaslAlready = 907;

  /// SASL mechanisms available.
  static const rplSaslMechs = 908;

  /// Returns true if the numeric is an error (4xx or 9xx errors).
  static bool isError(int numeric) {
    return (numeric >= 400 && numeric < 600) ||
        (numeric >= 900 && numeric < 1000 && numeric != 900 && numeric != 901 && numeric != 903 && numeric != 908);
  }
}
