import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Configuracoes extends StatefulWidget {
  const Configuracoes({Key? key}) : super(key: key);

  @override
  _ConfiguracoesState createState() => _ConfiguracoesState();
}

class _ConfiguracoesState extends State<Configuracoes> {
  TextEditingController _controllerNome = TextEditingController();
  late PickedFile _imagem;
  late String _idUsuarioLogado;
  bool _subindoImagem = false;
  late String? _urlImagemRecuperada = null;

  Future _recuperarImagem(String origemImagem) async{
    PickedFile? imagemSelecionada;
    try {
      switch (origemImagem) {
        case "camera":
          imagemSelecionada =
          await ImagePicker.platform.pickImage(source: ImageSource.camera);
          break;
        case "galeria":
          imagemSelecionada =
          await ImagePicker.platform.pickImage(source: ImageSource.gallery);
      }
      setState(() {
        _imagem = imagemSelecionada!;
        if (_imagem != null) {
          _subindoImagem = true;
          _uploadImagem();
        }
      });
    }catch(error){
      print("erro: " + error.toString());
    }
  }

  Future _uploadImagem() async{
    var file = File(_imagem.path);
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference pastaRaiz = storage.ref();
      Reference arquivo = pastaRaiz.child("perfil").child(
          _idUsuarioLogado + ".jpg");
      UploadTask task = arquivo.putFile(file); //upload da imagem
      task.snapshotEvents.listen((
          TaskSnapshot storageEvent) { //controlar progresso do upload
        if (storageEvent.state == TaskState.running) {
          setState(() {
            _subindoImagem = true;
          });
        } else if (storageEvent.state == TaskState.success) {
          setState(() {
            _subindoImagem = false;
          });
        }
      });
      task.then((TaskSnapshot snapshot) async{
        await _recuperarUrlImagem(snapshot);
      }); //recuperar url da imagem
    }catch(error){
      print("erro: " + error.toString());
    }
  }

  Future _recuperarUrlImagem(TaskSnapshot snapshot) async{
    String url = await snapshot.ref.getDownloadURL();
    _atualizarUrlImagemFirestore(url);
    setState(() {
        _urlImagemRecuperada = url;
    });
  }
  _atualizarUrlImagemFirestore(String url) async{
    FirebaseFirestore db = FirebaseFirestore.instance;
    Map<String,dynamic> dadosAtualizar = {
      "urlImagem": url
    };

    db.collection("usuarios").doc(_idUsuarioLogado).update(dadosAtualizar);
  }

  _atualizarNomeFirestore() async{
    String nome = _controllerNome.text;
    FirebaseFirestore db = FirebaseFirestore.instance;
    Map<String,dynamic> dadosAtualizar = {
      "nome": nome
    };

    db.collection("usuarios").doc(_idUsuarioLogado).update(dadosAtualizar);
  }

  _recuperarDadosUsuario() async{
    FirebaseAuth auth = FirebaseAuth.instance;
    User usuarioLogado = await auth.currentUser!;
    _idUsuarioLogado = usuarioLogado.uid;

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot snapshot = await db.collection("usuarios")
        .doc(_idUsuarioLogado).get();

    dynamic dados = await snapshot.data();
    _controllerNome.text = dados["nome"];

    if(dados["urlImagem"] != null){
      setState(() {
        _urlImagemRecuperada = dados["urlImagem"];
        _controllerNome.text = dados["nome"];
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _recuperarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Configurações"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: _subindoImagem ? CircularProgressIndicator() : Container(),
                ),
                CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.grey,
                  backgroundImage:
                  _urlImagemRecuperada == null
                      ? NetworkImage("https://firebasestorage.googleapis.com/v0/b/whatsapp-46b27.appspot.com/o/perfil%2Fperfil3.jpg?alt=media&token=30cc89e1-e907-4e3e-8429-6d909ac321e3")
                      : NetworkImage(_urlImagemRecuperada!)
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FlatButton(
                        onPressed: (){
                          _recuperarImagem("camera");
                        },
                        child: Text("Câmera")
                    ),
                    FlatButton(
                        onPressed: (){
                          _recuperarImagem("galeria");
                        },
                        child: Text("Galeria")
                    ),
                  ],
                ),

                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllerNome,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: "Nome",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32))),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 10),
                  child: RaisedButton(
                    child: const Text(
                      "Salvar",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    color: Colors.green,
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32)),
                    onPressed: () {
                      _atualizarNomeFirestore();

                    },
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
