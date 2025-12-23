import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/channels_provider.dart';

/// Dialog for joining a channel.
class JoinChannelDialog extends ConsumerStatefulWidget {
  const JoinChannelDialog({super.key});

  /// Shows the join channel dialog.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const JoinChannelDialog(),
    );
  }

  @override
  ConsumerState<JoinChannelDialog> createState() => _JoinChannelDialogState();
}

class _JoinChannelDialogState extends ConsumerState<JoinChannelDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _joinChannel() {
    final value = _controller.text;
    if (value.isNotEmpty) {
      final channel = value.startsWith('#') ? value : '#$value';
      ref.read(channelsProvider.notifier).joinChannel(channel);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rejoindre un canal'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '#canal',
          labelText: 'Nom du canal',
        ),
        onSubmitted: (_) => _joinChannel(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _joinChannel,
          child: const Text('Rejoindre'),
        ),
      ],
    );
  }
}
