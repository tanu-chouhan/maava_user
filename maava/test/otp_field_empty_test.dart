import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maava/src/presentation/auth/screens/otp_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The OTP boxes must open empty.
///
/// They used to be prefilled from the backend's echoed dev OTP, falling back to
/// a literal '1234' when there was none — which in production meant every user
/// was handed a wrong code that looked like a real one, and a single tap on
/// Verify failed. This asserts on the rendered fields rather than on the absent
/// `devOtp` parameter, so re-adding prefill by any other route still fails.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('every OTP box is empty when the screen opens', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => const MaterialApp(
            home: OtpScreen(phoneNumber: '9301988718'),
          ),
        ),
      ),
    );
    await tester.pump();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(6));

    for (var i = 0; i < 6; i++) {
      final controller = tester.widget<TextField>(fields.at(i)).controller;
      expect(controller?.text, isEmpty, reason: 'box $i must start empty');
    }
  });

  testWidgets('an autofilled code is dealt across the boxes in order',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => const MaterialApp(
            home: OtpScreen(phoneNumber: '9301988718'),
          ),
        ),
      ),
    );
    await tester.pump();

    final fields = find.byType(TextField);
    // Autofill and paste both deliver the whole code into one box — here the
    // first — rather than one keystroke per box.
    // One short of a full code on purpose: a complete code auto-submits, and the failed
    // verification (no backend under test) clears the boxes before we can look
    // at them. Ordering and one-digit-per-box are what this asserts.
    await tester.enterText(fields.first, '14463');
    await tester.pump();

    String boxText(int i) =>
        tester.widget<TextField>(fields.at(i)).controller!.text;

    expect([for (var i = 0; i < 6; i++) boxText(i)],
        ['1', '4', '4', '6', '3', ''],
        reason: 'repeated digits are where an off-by-one would surface, and '
            'the unfilled box must stay empty rather than duplicate one');
  });
}
