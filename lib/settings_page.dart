import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'settings.dart';
import 'vibrator.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.vibrator,
  });

  final AppSettings settings;
  final Vibrator vibrator;

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
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ListTile(
              title: const Text('Number of dice'),
              subtitle: const Text('How many dice to roll'),
              trailing: DropdownButton<int>(
                key: const Key('diceCountField'),
                value: widget.settings.diceCount,
                items: [
                  for (
                    var n = AppSettings.minDiceCount;
                    n <= AppSettings.maxDiceCount;
                    n++
                  )
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (n) {
                  if (n != null) widget.settings.diceCount = n;
                },
              ),
            ),
            SwitchListTile(
              key: const Key('showSumSwitch'),
              title: const Text('Sum of dice'),
              subtitle: const Text('Show the total in a circle below the dice'),
              value: widget.settings.showSum,
              onChanged: (on) => widget.settings.showSum = on,
            ),
            SwitchListTile(
              key: const Key('threeDSwitch'),
              title: const Text('3D'),
              subtitle: const Text('Draw 3D dice that tumble when rolled'),
              value: widget.settings.threeD,
              onChanged: (on) => widget.settings.threeD = on,
            ),
            SwitchListTile(
              key: const Key('statsSwitch'),
              title: const Text('Stats'),
              subtitle: const Text(
                'Show histograms of the rolls under the dice: one per face, '
                'and one per total when "Sum of dice" is on. Tap to reset',
              ),
              value: widget.settings.showStats,
              onChanged: (on) => widget.settings.showStats = on,
            ),
            SwitchListTile(
              key: const Key('vibrateSwitch'),
              title: const Text('Vibrate'),
              subtitle: Text(
                widget.vibrator.isSupported
                    ? 'Vibrate while the dice roll'
                    : "This browser can't vibrate. Firefox and iPhone "
                          "browsers don't support it: try Chrome on Android.",
              ),
              value: widget.vibrator.isSupported && widget.settings.vibrate,
              onChanged: widget.vibrator.isSupported
                  ? (on) => widget.settings.vibrate = on
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
