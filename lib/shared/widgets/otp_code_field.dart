import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Six visual boxes backed by one native input for paste, autofill and deletion.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final focus = FocusNode();

  @override
  void initState() {
    super.initState();
    focus.addListener(refresh);
    widget.controller.addListener(refresh);
  }

  void refresh() => setState(() {});

  @override
  void didUpdateWidget(covariant OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(refresh);
      widget.controller.addListener(refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(refresh);
    focus.removeListener(refresh);
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final value = widget.controller.text;
    final active = widget.controller.selection.extentOffset.clamp(0, 5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExcludeSemantics(child: Text('Verification code')),
        const SizedBox(height: 8),
        Stack(
          children: [
            ExcludeSemantics(
              child: IgnorePointer(
                child: Row(
                  children: [
                    for (var index = 0; index < 6; index++) ...[
                      if (index > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          key: ValueKey('otp-box-$index'),
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  widget.enabled &&
                                      focus.hasFocus &&
                                      active == index
                                  ? colors.primary
                                  : colors.outline,
                              width: focus.hasFocus && active == index ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            index < value.length ? value[index] : '',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Semantics(
              label: 'Verification code',
              child: TextFormField(
                controller: widget.controller,
                focusNode: focus,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                autocorrect: false,
                enableSuggestions: false,
                showCursor: false,
                style: const TextStyle(color: Colors.transparent, fontSize: 24),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onTap: () {
                  widget.controller.selection = TextSelection.collapsed(
                    offset: value.length,
                  );
                },
                validator: (value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
                    ? null
                    : 'Enter all six digits.',
                onFieldSubmitted: widget.onSubmitted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
