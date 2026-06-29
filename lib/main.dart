import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/data/notifiers.dart';
import 'package:mobile/views/widget_tree.dart'; // Import file WidgetTree vừa sửa

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff008080),
              brightness: isLightMode ? Brightness.light : Brightness.dark,
            ),
            textTheme: GoogleFonts.robotoTextTheme(),
            useMaterial3: true,
          ),
          // SỬA Ở ĐÂY: Trỏ về WidgetTree để kiểm tra đăng nhập trước
          home: const WidgetTree(),
        );
      },
    );
  }
}
