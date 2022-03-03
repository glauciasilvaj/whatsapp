import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whatsapp/model/Conversa.dart';
import 'package:whatsapp/model/Mensagem.dart';
import 'model/Usuario.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class Mensagens extends StatefulWidget {
  Usuario contato;
  Mensagens(this.contato);

  @override
  _MensagensState createState() => _MensagensState();
}

class _MensagensState extends State<Mensagens> {
  @override
  late File _imagem;
  bool _subindoImagem = false;
  String _idUsuarioLogado = "";
  String _idUsuarioDestinatario = "";
  FirebaseFirestore db = FirebaseFirestore.instance;

  TextEditingController _controllerMensagem = TextEditingController();
  final _controller = StreamController<QuerySnapshot>.broadcast();
  ScrollController _scrollController = ScrollController();

  _enviarMensagem() {
    String textoMensagem = _controllerMensagem.text;
    if (textoMensagem.isNotEmpty) {
      Mensagem mensagem = Mensagem();
      mensagem.idUsuario = _idUsuarioLogado;
      mensagem.mensagem = textoMensagem;
      mensagem.urlImagem = "";
      mensagem.data = Timestamp.now().toString();
      mensagem.tipo = "texto";

      _salvarMensagem(_idUsuarioLogado, _idUsuarioDestinatario,
          mensagem); //salvar mensagem para o remetente
      _salvarMensagem(_idUsuarioDestinatario, _idUsuarioLogado,
          mensagem); //salvar msg para o destinatario

      _salvarConversa(mensagem);
    }
  }

  _salvarConversa(Mensagem msg) {
    //Salvar conversa remetente
    Conversa cRemetente = Conversa();
    cRemetente.idRemetente = _idUsuarioLogado;
    cRemetente.idDestinatario = _idUsuarioDestinatario;
    cRemetente.mensagem = msg.mensagem;
    cRemetente.nome = widget.contato.nome;
    cRemetente.caminhoFoto = widget.contato.urlImagem;
    cRemetente.tipoMensagem = msg.tipo;
    cRemetente.salvar();

    //Salvar conversa destinatario
    Conversa cDestinatario = Conversa();
    cDestinatario.idRemetente = _idUsuarioDestinatario;
    cDestinatario.idDestinatario = _idUsuarioLogado;
    cDestinatario.mensagem = msg.mensagem;
    cDestinatario.nome = widget.contato.nome;
    cDestinatario.caminhoFoto = widget.contato.urlImagem;
    cDestinatario.tipoMensagem = msg.tipo;
    cDestinatario.salvar();
  }

  _salvarMensagem(
      String idRemetente, String idDestinatario, Mensagem msg) async {
    await db
        .collection("mensagens")
        .doc(idRemetente)
        .collection(idDestinatario)
        .add(msg.toMap());

    _controllerMensagem.clear();
  }

  _enviarFoto() async {
    //File(imagemSelecionada.path)
    PickedFile? imagemSelecionada;
    imagemSelecionada =
        await ImagePicker.platform.pickImage(source: ImageSource.gallery);

    if (imagemSelecionada != null) {
      _imagem = File(imagemSelecionada.path);

      try {
        _subindoImagem = true;
        String nomeImagem = DateTime.now().millisecondsSinceEpoch.toString();
        FirebaseStorage storage = FirebaseStorage.instance;
        Reference pastaRaiz = storage.ref();
        Reference arquivo = pastaRaiz
            .child("mensagens")
            .child(_idUsuarioLogado)
            .child(nomeImagem + ".jpg");
        UploadTask task = arquivo
            .putData(await imagemSelecionada.readAsBytes()); //upload da imagem
        task.snapshotEvents.listen((TaskSnapshot storageEvent) {
          //controlar progresso do upload
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
        task.then((TaskSnapshot snapshot) async {
          await _recuperarUrlImagem(snapshot);
        }); //recuperar url da imagem
      } catch (error) {
        print("erro: " + error.toString());
      }
    }
  }

  Future _recuperarUrlImagem(TaskSnapshot snapshot) async {
    String url = await snapshot.ref.getDownloadURL();

    Mensagem mensagem = Mensagem();
    mensagem.idUsuario = _idUsuarioLogado;
    mensagem.mensagem = "";
    mensagem.urlImagem = url;
    mensagem.data = Timestamp.now().toString();
    mensagem.tipo = "imagem";

    _salvarMensagem(_idUsuarioLogado, _idUsuarioDestinatario, mensagem);
    _salvarMensagem(_idUsuarioDestinatario, _idUsuarioLogado, mensagem);
  }

  _recuperarDadosUsuario() {
    FirebaseAuth auth = FirebaseAuth.instance;
    User usuarioLogado = auth.currentUser!;
    _idUsuarioLogado = usuarioLogado.uid;
    _idUsuarioDestinatario = widget.contato.idUsuario;
    _adicionarListenerMensagens();
  }

  Stream<QuerySnapshot>? _adicionarListenerMensagens(){
    final stream = db
        .collection("mensagens")
        .doc(_idUsuarioLogado)
        .collection(_idUsuarioDestinatario)
        .orderBy("data", descending: false)
        .snapshots();

    stream.listen((dados) {
      _controller.add(dados);
      Timer(
          Duration(seconds: 1),
          (){
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();
  }

  Widget build(BuildContext context) {
    var caixaMensagem = Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextField(
                controller: _controllerMensagem,
                autofocus: true,
                keyboardType: TextInputType.text,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                    contentPadding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
                    hintText: "Digite uma mensagem",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32)),
                    prefixIcon: _subindoImagem
                        ? CircularProgressIndicator()
                        : IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: _enviarFoto,
                          )),
              ),
            ),
          ),
          FloatingActionButton(
              backgroundColor: const Color(0xff075E54),
              child: const Icon(
                Icons.send,
                color: Colors.white,
              ),
              mini: true,
              onPressed: _enviarMensagem)
        ],
      ),
    );

    var stream = StreamBuilder(
        stream: _controller.stream,
        builder: (context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(
                child: Column(
                  children: const [
                    Text("Carregando mensagens"),
                    CircularProgressIndicator()
                  ],
                ),
              );
              break;
            case ConnectionState.active:
            case ConnectionState.done:
              QuerySnapshot querySnapshot = snapshot.data;
              if (snapshot.hasError) {
                return const Expanded(
                  child: Text("Erro ao carregar os dados!"),
                );
              } else {
                return Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                      itemCount: querySnapshot.docs.length,
                      itemBuilder: (context, indice) {
                        //recuperar mensagens
                        List<DocumentSnapshot> mensagens =
                            querySnapshot.docs.toList();
                        DocumentSnapshot item = mensagens[indice];

                        double larguraContainer =
                            MediaQuery.of(context).size.width * 0.8;

                        Alignment alinhamento = Alignment.centerRight;
                        Color cor = Color(0xffd2ffa5);

                        if (_idUsuarioLogado != item["idUsuario"]) {
                          cor = Colors.white;
                          alinhamento = Alignment.centerLeft;
                        }

                        return Align(
                          alignment: alinhamento,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Container(
                              width: larguraContainer,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: cor,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8))),
                              child: item["tipo"] == "texto"
                                  ? Text(
                                      item["mensagem"],
                                      style: TextStyle(fontSize: 18),
                                    )
                                  : Image.network(item["urlImagem"]),
                            ),
                          ),
                        );
                      }),
                );
              }
              break;
          }
          return Container();
        });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              maxRadius: 20,
              backgroundColor: Colors.grey,
              backgroundImage: NetworkImage(widget.contato.urlImagem),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(widget.contato.nome),
            )
          ],
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("imagens/bg.png"), fit: BoxFit.cover)),
        child: SafeArea(
            child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              stream,
              caixaMensagem,
            ],
          ),
        )),
      ),
    );
  }
}
