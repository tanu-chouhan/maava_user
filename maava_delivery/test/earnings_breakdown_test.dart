import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maava_delivery/core/presentation/widgets/vertical_breakdown_sheet.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('shows Food and Mart separately with the combined total',
      (tester) async {
    await tester.pumpWidget(_host(const VerticalBreakdownSheet(
      title: "Today's Earnings",
      rows: [
        VerticalBreakdownRow(
          label: 'Maava Food',
          value: '₹500.00',
          icon: Icons.restaurant_rounded,
          tint: Colors.green,
        ),
        VerticalBreakdownRow(
          label: 'Maava Mart',
          value: '₹300.00',
          icon: Icons.storefront_rounded,
          tint: Colors.teal,
        ),
      ],
      totalLabel: 'Total Earnings',
      totalValue: '₹800.00',
    )));
    await tester.pump();

    expect(find.text('Maava Food'), findsOneWidget);
    expect(find.text('₹500.00'), findsOneWidget);
    expect(find.text('Maava Mart'), findsOneWidget);
    expect(find.text('₹300.00'), findsOneWidget);
    // The two must never be merged into one figure.
    expect(find.text('₹800.00'), findsOneWidget);
    expect(find.text('Total Earnings'), findsOneWidget);
  });

  testWidgets('renders counts, not just currency', (tester) async {
    await tester.pumpWidget(_host(const VerticalBreakdownSheet(
      title: "Today's Orders",
      rows: [
        VerticalBreakdownRow(
          label: 'Maava Food',
          value: '8',
          icon: Icons.restaurant_rounded,
          tint: Colors.green,
        ),
        VerticalBreakdownRow(
          label: 'Maava Mart',
          value: '5',
          icon: Icons.storefront_rounded,
          tint: Colors.teal,
        ),
      ],
      totalLabel: 'Total Orders',
      totalValue: '13',
    )));
    await tester.pump();

    expect(find.text('8'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
  });

  testWidgets('a rider with no Mart trips still sees a Mart row at zero',
      (tester) async {
    // Hiding the row would read as "Mart does not exist" rather than
    // "no Mart orders today".
    await tester.pumpWidget(_host(const VerticalBreakdownSheet(
      title: "Today's Earnings",
      rows: [
        VerticalBreakdownRow(
          label: 'Maava Food',
          value: '₹120.00',
          icon: Icons.restaurant_rounded,
          tint: Colors.green,
        ),
        VerticalBreakdownRow(
          label: 'Maava Mart',
          value: '₹0.00',
          icon: Icons.storefront_rounded,
          tint: Colors.teal,
        ),
      ],
      totalLabel: 'Total Earnings',
      totalValue: '₹120.00',
    )));
    await tester.pump();

    expect(find.text('Maava Mart'), findsOneWidget);
    expect(find.text('₹0.00'), findsOneWidget);
  });
}
