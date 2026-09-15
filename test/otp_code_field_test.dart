import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_doctor_doctor/shared/widgets/otp_code_field.dart';

void main() {
  testWidgets(
    'OTP boxes support full code paste, numeric filtering and backspace',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpCodeField(
              controller: controller,
              enabled: true,
              onSubmitted: (_) {},
            ),
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(ValueKey('otp-box-$i')), findsOneWidget);
      }
      await tester.enterText(find.byType(TextFormField), '12a34567');
      await tester.pump();
      expect(controller.text, '123456');
      expect(find.text('6'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(controller.text, '12345');
      expect(find.text('6'), findsNothing);
      controller.clear();
      await tester.pump();
      expect(find.text('1'), findsNothing);
    },
  );
  testWidgets('OTP incomplete input is rejected and boxes fit a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: key,
              child: OtpCodeField(
                controller: controller,
                enabled: true,
                onSubmitted: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '12');
    expect(key.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Enter all six digits.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
