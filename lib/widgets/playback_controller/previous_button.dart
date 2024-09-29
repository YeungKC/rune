import 'package:fluent_ui/fluent_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../utils/api/play_previous.dart';

class PreviousButton extends StatelessWidget {
  final bool disabled;

  const PreviousButton({required this.disabled, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: disabled ? null : playPrevious,
      icon: const Icon(Symbols.skip_previous),
    );
  }
}
