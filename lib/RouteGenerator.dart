import 'package:flutter/material.dart';
import 'package:whatsapp/Cadastro.dart';
import 'package:whatsapp/Configuracoes.dart';
import 'package:whatsapp/Home.dart';
import 'package:whatsapp/Login.dart';
import 'package:whatsapp/Mensagens.dart';

class RouteGenerator {
  static var args;
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    args = settings.arguments;

    switch (settings.name) {
      case "/":
        return MaterialPageRoute(builder: (_) => Login());
      case "/login":
        return MaterialPageRoute(builder: (_) => Login());
      case "/cadastro":
        return MaterialPageRoute(builder: (_) => Cadastro());
      case "/home":
        return MaterialPageRoute(builder: (_) => Home());
      case "/configuracoes":
        return MaterialPageRoute(builder: (_) => Configuracoes());
      case "/mensagens":
        return MaterialPageRoute(builder: (_) => Mensagens(args));
      default:
        _erroRota();
    }
  }
  static Route<dynamic> _erroRota(){
    return MaterialPageRoute(builder: (_){
      return Scaffold(
        appBar: AppBar(title: const Text("Tela não encontrada!"),),
        body: const Center(
          child: Text("Tela não encontrada!"),
        ),
      );
    });
  }
}
