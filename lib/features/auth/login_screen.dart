import '../../shared/widgets/otp_code_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/workspace_widgets.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.message});
  final String? message;
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final phone = TextEditingController();
  final code = TextEditingController();
  final form = GlobalKey<FormState>();
  String? challenge, error, developmentCode;
  bool busy = false;
  bool registration = false;
  @override
  void dispose() {
    phone.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (challenge == null) {
        final id = await ref
            .read(authRepositoryProvider)
            .requestOtp('+91${phone.text.trim()}', registration: registration);
        if (mounted) {
          setState(() {
            challenge = id.id;
            developmentCode = id.developmentCode;
            code.clear();
          });
        }
      } else {
        await ref
            .read(authProvider.notifier)
            .verify(challenge!, code.text, registration: registration);
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Form(
        key: form,
        child: FormPage(
          children: [
            const SizedBox(height: 28),
            const Brand(),
            const SizedBox(height: 20),
            Text(
              registration ? 'Register as Doctor' : 'Doctor workspace',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              challenge == null
                  ? registration
                        ? 'Verify your mobile number to begin your professional application. Approval is required before Doctor services are available.'
                        : 'Welcome back. Sign in with the mobile number linked to your doctor account.'
                  : 'Check your phone. Enter the six-digit verification code.',
            ),
            if (widget.message != null) Notice(widget.message!),
            if (kDebugMode &&
                const bool.fromEnvironment('SHOW_DEVELOPMENT_OTP') &&
                developmentCode != null &&
                challenge != null)
              Notice('Local development code: $developmentCode'),
            if (challenge == null)
              TextFormField(
                controller: phone,
                enabled: !busy,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
                    if (digits.length == 12 && digits.startsWith('91')) {
                      digits = digits.substring(2);
                    }
                    if (digits == newValue.text) return newValue;
                    return TextEditingValue(
                      text: digits,
                      selection: TextSelection.collapsed(offset: digits.length),
                    );
                  }),
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  prefixText: '+91 ',
                  hintText: '9876543210',
                ),
                validator: (value) =>
                    RegExp(r'^[6-9]\d{9}$').hasMatch(value!.trim())
                    ? null
                    : 'Enter a valid 10-digit mobile number.',
                onFieldSubmitted: (_) => busy ? null : submit(),
              )
            else
              OtpCodeField(
                controller: code,
                enabled: !busy,
                onSubmitted: (_) => busy ? null : submit(),
              ),
            if (error != null) Notice(error!, error: true),
            FilledButton(
              onPressed: busy ? null : submit,
              child: Text(
                busy
                    ? 'Please wait…'
                    : challenge == null
                    ? 'Send verification code'
                    : 'Verify & continue',
              ),
            ),
            if (challenge != null)
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                        challenge = null;
                        error = null;
                        code.clear();
                      }),
                child: const Text('Use another number'),
              ),
            if (challenge == null)
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                        registration = !registration;
                        error = null;
                      }),
                child: Text(
                  registration
                      ? 'Existing doctor? Sign in'
                      : 'Register as Doctor',
                ),
              ),
            if (widget.message != null)
              TextButton(
                onPressed: busy
                    ? null
                    : () => ref.read(authProvider.notifier).restore(),
                child: const Text('Retry session restoration'),
              ),
          ],
        ),
      ),
    ),
  );
}
