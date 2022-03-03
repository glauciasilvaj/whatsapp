import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp/Login.dart';
import 'package:whatsapp/RouteGenerator.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(MaterialApp(
    home: Login(),
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Color(0xff075E54)),
      primaryColor: const Color(0xff075E54),
      accentColor: const Color(0xff25d366),
      appBarTheme: AppBarTheme(color: Color(0xff075E54)),
    ),
    initialRoute: "/",
    onGenerateRoute: RouteGenerator.generateRoute,
    debugShowCheckedModeBanner: false,
  ));
}