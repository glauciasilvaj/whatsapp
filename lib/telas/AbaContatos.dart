import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/Usuario.dart';

class AbaContatos extends StatefulWidget {
  const AbaContatos({Key? key}) : super(key: key);

  @override
  _AbaContatosState createState() => _AbaContatosState();
}

class _AbaContatosState extends State<AbaContatos> {
  late String _idUsuarioLogado;
  late String _emailUsuarioLogado;

  Future<List<Usuario>> _recuperarContatos() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await db.collection("usuarios").get();

    List<Usuario> listaUsuarios = [];
    for (DocumentSnapshot item in querySnapshot.docs) {
      Map dadosMap = {};
      var dados = item.data();
      dadosMap = dados as Map;

      if (dados["email"] == _emailUsuarioLogado) continue;

      Usuario usuario = Usuario();
      usuario.idUsuario = item.id;
      usuario.email = dados["email"];
      usuario.nome = dados["nome"];
      usuario.urlImagem = dados["urlImagem"];

      listaUsuarios.add(usuario);
    }
    return listaUsuarios;
  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User usuarioLogado = await auth.currentUser!;
    _idUsuarioLogado = usuarioLogado.uid;
    _emailUsuarioLogado = usuarioLogado.email!;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _recuperarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Usuario>?>(
        future: _recuperarContatos(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(
                child: Column(
                  children: const [
                    Text("Carregando contatos"),
                    CircularProgressIndicator()
                  ],
                ),
              );
              break;
            case ConnectionState.active:
            case ConnectionState.done:
              return ListView.builder(
                  itemCount: snapshot.data?.length,
                  itemBuilder: (_, indice) {
                    List<Usuario> listaItens = snapshot.data!;
                    Usuario usuario = listaItens[indice];
                    return ListTile(
                      onTap: (){
                        Navigator.pushNamed(context, "/mensagens", arguments: usuario);
                      },
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      leading: CircleAvatar(
                          maxRadius: 30,
                          backgroundColor: Colors.grey,
                          backgroundImage: NetworkImage(usuario.urlImagem)),
                      title: Text(
                        usuario.nome,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    );
                  });
              break;
          }
          return Container();
        });
  }
}
