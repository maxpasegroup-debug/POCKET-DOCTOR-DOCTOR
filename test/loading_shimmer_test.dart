import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_doctor_doctor/shared/widgets/loading_shimmer.dart';

void main() {
  testWidgets('shimmer loads accessibly on a small screen without spinners', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LoadingShimmer(label: 'Loading workspace')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(find.bySemanticsLabel('Loading workspace'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows a static image placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: LoadingShimmer(label: 'Loading profile photo', height: 120),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.bySemanticsLabel('Loading profile photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
