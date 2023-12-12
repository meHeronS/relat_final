//import 'dart:js';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // inicialização do Firebase: como é um prog. de Internet, usar async/awit
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relatório Final - Bloco de Notas',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FirebaseFirestore db =
      FirebaseFirestore.instance; // obtem uma instãncia da conexão com o BD
  final TextEditingController _textController = TextEditingController();
  List<String> listNotas = [];
  String _notaId = ""; // Adicione esta linha para declarar _notaId

  @override
  void initState() {
    refresh(); // initState roda no início do App e obtém  os dados da lista e mostra na tela

    // assim que começar o App coloca-se um ouvinte (listen) de todos os snapshots que acontecerem na coleção
    // listen fica "ouvindo" todos os snapshots. Assim se algo for atulizado, chega um snapshot, que será "ouvido"
    db.collection("Notas").snapshots().listen((snapshot) {
      setState(() {
        listNotas = []; // zera a lista
        for (var document in snapshot.docs) {
          // atualiza a lisa com o novo snapshot
          listNotas.add(document.get(
              "_nota")); // O App deve ser reiniciado pois initState só roda no começo
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                ),
                child: Text(
                  'TRABALHO FINAL DAM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Página Inicial'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Informações'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const AlertDialog(
                        title: Text('Informações'),
                        content: Text(
                          'Trabalho Relatório Final\n'
                              'Versão: 1.0\n'
                              'Data: 13/12/2023\n'
                              'Link: https://github.com/meHeronS/relat_final',
                        ),
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.perm_contact_cal_outlined),
                title: const Text('Integrantes'),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          title: Text('Integrantes'),
                          content: Text(
                              'Heron Silva\nLuiza Dutra\nMaurilio Frade\nRobson Oliveira'),
                        );
                      });
                },
              ),
              ListTile(
                leading: const Icon(Icons.highlight_remove_sharp),
                title: const Text('Limpar Banco'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Informações'),
                        content: const Text('Deseja Remover todos os dados?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              excludeAllNotas();
                              Navigator.of(context).pop();
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.delete_forever_rounded),
                                SizedBox(
                                  width: 8,
                                ),
                                Text('Remover'),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancelar'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        appBar: AppBar(
          title: const Text("MINHAS NOTAS"),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => refresh(),
          child: const Icon(Icons.refresh),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 130),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Salvar suas notas!",
                    style: TextStyle(
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        color: Colors.pink,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  TextField(
                    controller: _textController,
                    decoration:
                    const InputDecoration(labelText: "Insira nova nota"),
                  ),
                  ElevatedButton(
                    onPressed: () => sendData(),
                    child: const Text("Salvar"),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  (listNotas.isEmpty)
                      ? const Text(
                    "Nenhuma Nota Registrada",
                    style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.pink,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  )
                      : Column(
                    children: [
                      for (String s in listNotas)
                        ListTile(
                          title: Text(s),
                          onTap: () {
                            onTapNota(context, s, db);
                            },
                            trailing: IconButton(
                            onPressed: () {
                              excludeLastNotas();
                              },
                            icon: const Icon(Icons.delete),
                          ),
                        ),
                    ],
                  ),
                ]
            ),
          ),
        ));
  }

  void refresh() async {
    QuerySnapshot query = await db
        .collection("Notas")
        .get(); // Snapshot é como uma foto do BD no momento que é chamado

    listNotas = []; // zera a lista

    for (var document in query.docs) {
      // obtem cada elemento da lista
      print(document.id); //Mostrar o id que escolhemos
      String data =
      document.get("_notas"); // pega o valor do campo "name" de cada linha
      setState(() {
        listNotas.add(
            data); // adiciona o valor do campo "name" na lista, zerada previamente
      });
    }
  }

  void editNota(String id, String newNota) async {
    await db.collection("Notas").doc(id).update({
      "_nota": newNota,
    });
  }

  void excludeAllNotas() async {
    QuerySnapshot query = await db.collection("Notas").get();

    if (query.docs.isNotEmpty) {
      // Itera sobre os documentos e os exclui
      query.docs.forEach((documento) async {
        await documento.reference.delete();
      });

      // Atualiza o estado para refletir as alterações na interface
      setState(() {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          const SnackBar(
            content: Text("Documentos excluídos com sucesso!"),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(
          content: Text("Banco já está vazio!"),
        ),
      );
    }
  }

  void excludeLastNotas() async {
    QuerySnapshot query = await db.collection("Notas").get();

    if (query.docs.isNotEmpty) {
      // Obtém o último documento da coleção
      DocumentSnapshot lastDocument = query.docs.last;

      // Exclui o último documento, se existir
      await lastDocument.reference.delete();

      // Atualiza o estado para refletir as alterações na interface
      setState(() {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          const SnackBar(
            content: Text("Último documento excluído com sucesso!"),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(
          content: Text("Banco já está vazio!"),
        ),
      );
    }
  }

  void sendData() {
    String id = const Uuid()
        .v1(); // esta função gera um ID único sempre que é chamada, para ser usada no doc do banco
    // para usar o Uuid tem que ter uma dependência adicionada no pubspec.yaml: uuid:^3.0.
    // É necessário criar uma coleção. Se ela não existir, será criada. No caso "contacts"
    // É necessário trabalhar com um documento.
    // Se for passado um ID deste documento que já existe, o doc será alterado no Firestore.
    // Se for passado um ID deste documento que não existe, o doc será criado no Firestore.
    // Deve ser passado para set um MAP. No caso o campo "name", que vem do controller criado anteriormente

    db.collection("Notas").doc(id).set({
      "_nota": _textController.text
    }); // confira no Firestore a atualização do BC

    //Visual Feedback
    _textController.text = ""; // limpa o Text e mostra a SnackBar
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      const SnackBar(
        content: Text(
            "Salvo na nuvem!"), // SnackBar é uma  barrinha que aparece na tela com a msg contida em Text
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Não foi possível abrir o link $url';
    }
  }

  void showPopup(BuildContext context, String nota) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController textController = TextEditingController(text: nota);

        return AlertDialog(
          title: const Text('Informações da Nota'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(labelText: "Nota:"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
            TextButton(
              onPressed: () {
                // Salvar a edição
                Navigator.of(context).pop(); // Fechar o primeiro diálogo

                // Abrir um segundo diálogo para confirmar a edição
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirmação de Edição'),
                      content: const Text('Deseja salvar as alterações realizadas?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            // Salvar as alterações no banco de dados
                            // Aqui você pode chamar uma função para salvar as alterações no Firestore
                            // por exemplo, db.collection("Notas").doc(id).update({...})
                            Navigator.of(context).pop(); // Fechar o segundo diálogo
                          },
                          child: const Text('Sim'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Fechar o segundo diálogo
                          },
                          child: const Text('Cancelar'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Editar'),
            ),
          ],
        );
      },
    );
  }

  void onTapNota(BuildContext context, String nota, FirebaseFirestore db) {
    TextEditingController textController = TextEditingController(text: nota);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detalhes da Nota'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(labelText: "Editar nota"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fechar o diálogo de edição
              },
              child: const Text('Fechar'),
            ),
            TextButton(
              onPressed: () async {
                // Salvar as alterações no banco de dados
                await db.collection("Notas").doc(_notaId).update({
                  "_notas": textController.text,
                });

                Navigator.of(context).pop(); // Fechar o diálogo de edição
              },
              child: const Text('Salvar'),
            ),
            TextButton(
              onPressed: () async {
                // Salvar as alterações no banco de dados
                await db.collection("Notas").doc(_notaId).delete();

                Navigator.of(context).pop(); // Fechar o diálogo de edição
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
