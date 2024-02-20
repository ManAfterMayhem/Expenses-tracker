import 'package:expense_tracker_minimal/database/expense_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //init DB
  await ExpenseDatabase.initDB();
  runApp(
    ChangeNotifierProvider(
        create: (context) => ExpenseDatabase(), child: const MainApp()),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make status bar transparent
      statusBarBrightness: Brightness.dark, // Dark text for status bar
      statusBarIconBrightness: Brightness.dark, // Dark icons for status bar
    ));

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
