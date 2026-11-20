import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _delay = TextEditingController(
    text: '${widget.settings.delayMs}',
  );
  String? _error;

  @override
  void dispose() {
    _delay.dispose();
    super.dispose();
  }

  void _onDelayChanged(String text) {
    final value = int.tryParse(text);
    setState(() {
      if (value == null || !AppSettings.isValidDelay(value)) {
        _error = 'Enter a whole number from 1 to 4999';
      } else {
        _error = null;
        widget.settings.delayMs = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) => ListView(
          children: [
            ListTile(
              title: const Text('Fake delay'),
              subtitle: const Text('How long the dice roll, in milliseconds'),
              trailing: SizedBox(
                width: 120,
                child: TextField(
                  key: const Key('delayField'),
                  controller: _delay,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.end,
                  // Only the red underline shows in the field; the message
                  // goes under the whole row, where it has room to read.
                  decoration: InputDecoration(
                    isDense: true,
                    suffixText: 'ms',
                    error: _error == null ? null : const SizedBox.shrink(),
                  ),
                  onChanged: _onDelayChanged,
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  _error!,
                  key: const Key('delayError'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            SwitchListTile(
              key: const Key('vibrateSwitch'),
              title: const Text('Vibrate'),
              subtitle: const Text('Vibrate while the dice roll'),
              value: widget.settings.vibrate,
              onChanged: (on) => widget.settings.vibrate = on,
            ),
          ],
        ),
      ),
    );
  }
}
