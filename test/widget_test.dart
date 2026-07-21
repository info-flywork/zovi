import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zovi/app.dart';
import 'package:zovi/core/init/app_init.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppInit.init();
  });

  testWidgets('Splash shows zovi brand', (tester) async {
    await tester.pumpWidget(const ZoviApp());
    await tester.pump();
    expect(find.text('zovi'), findsOneWidget);
    expect(find.text('be here, share now'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
