import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SqliteApp());
}

class SqliteApp extends StatelessWidget {
  const SqliteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}

class Home extends StatefulWidget {
  @override
  _SqliteAppState createState() => _SqliteAppState();
}

class _SqliteAppState extends State<Home> {
  int? selectedId;
  String? selectedList;
  final textController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future search() async{
    final dropDownlist = await DatabaseHelper._database!.rawQuery('SELECT * FROM listNames');
    print(dropDownlist);

        
    //return dropDownlist;


  }


  @override
  Widget build(BuildContext context) {
    List? testing;
    return MaterialApp(

      debugShowCheckedModeBanner: false,
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            "List Application"
          ),

        ),
        body: Center(
          child: FutureBuilder<List<listContents>>(
            future: DatabaseHelper.instance.getList(),
            builder: (BuildContext context, AsyncSnapshot<List<listContents>> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: Text('Loading...'));

              }
              return snapshot.data!.isEmpty
                  ? Center(child: Text('No items in List'))
                : ListView(
                children: snapshot.data!.map((listContents) {
                  return Center(
                    child: Card(
                      child: ListTile(
                        leading: Card(
                          child: Text(listContents.name),
                        ),
                        trailing: Card(
                          child: Text(listContents.listName),
                        ),
                        onLongPress: () {
                          setState(() {
                            DatabaseHelper.instance.remove(listContents.id!);
                          });
                        },
                        onTap: () {
                          setState(() {
                            textController.text = listContents.name;
                            selectedId = listContents.id;
                            selectedList = listContents.listName;
                          });
                          this
                              ._scaffoldKey
                              .currentState!
                              .showBottomSheet((ctx) => _buildBottomSheet(ctx))
                          ;
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            }
          ),
        ),
        drawer: Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text('Beta List Application'),
              ),
              Card(
                child: ListTile(
                  title: const Text("Item 1 (Doesn't Work"),
                  onTap: () {
                    // Update the state of the app
                    // ...
                    // Then close the drawer
                    Navigator.pop(context);
                  },
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('New List'),

                  onTap: () {
                    // Update the state of the app
                    // ...
                    // Then close the drawer
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),



        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () => this
            ._scaffoldKey
            .currentState!
            .showBottomSheet((ctx) => _buildBottomSheet(ctx)),
            heroTag: search()


        ),

      ),
    );
  }

  Container _buildBottomSheet(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        height: 225,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2.0),
            borderRadius: BorderRadius.circular(8.0),

      ),
        child:
            Container(
                child: ListView(
                  children: [
                    const ListTile(
                      title: Text("Bottom Sheet",
                      textAlign: TextAlign.center,),
                    ),
                    Column(
                      children: [
                        TextField(
                          controller: textController,
                          textAlign: TextAlign.center,
                          decoration:
                          InputDecoration(
                            labelText: "Please enter what to add",
                          ),
                        ),
                        DropdownButton(


                        items: [],
                      ),
                      ]
                    ),

                    Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton.icon(
                                onPressed: () async {
                                  print("add button pressed");
                                  selectedId != null
                                      ? await DatabaseHelper.instance.update(
                                          listContents(
                                              id: selectedId,
                                              name: textController.text,
                                              listName: "something"),
                                        )
                                      : await DatabaseHelper.instance.add(
                                          listContents(name: textController.text, listName: "something"),
                                        );
                                  print("await DatabaseHelper.instance.add");
                                  setState(() {
                                    textController.clear();
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("Save")),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                                label: const Text("Close")),
                          ),
                        ],
                      ),
                    )
                  ],
                )
              )



    );

  }

}




class listContents {
  final int? id;
  final String name;
  final String listName;

  listContents({this.id, required this.name, required this.listName});

  factory listContents.fromMap(Map<String, dynamic> json) => new listContents(
      id: json['id'],
      name: json['name'],
      listName: json['listName']
  );

  Map<String, dynamic> toMap() {
    return {
      'id' : id,
      'name' : name,
      'listName' : listName,
    };
  }

}

class listNames {
  final int? id;
  final String listName;

  listNames({this.id, required this.listName});

  factory listNames.fromMap(Map<String, dynamic> json) => new listNames(
      id: json['id'],
      listName: json['listName']
  );

  Map<String, dynamic> toMap() {
    return {
      'id' : id,
      'listName' : listName,
    };
  }

}





class DatabaseHelper {

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    print("initializing database");
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'listApp2.db');
    return await openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      await db.execute('''CREATE TABLE listNames (id INTEGER PRIMARY KEY, listName TEXT)''');
        await db.execute('''
          CREATE TABLE itemList(
          id INTEGER PRIMARY KEY,
          name TEXT,
          listName TEXT
          )''');
        print("itemList table created");
      }
    );

  }

/*
  Future newList() async {
    await db.insert();
  }

  Add new list name to listNames table from user input

*/



  Future<List<listContents>> getList() async {
    Database db = await instance.database;
    var organizedContent = await db.query('itemList', orderBy: 'name');
    List<listContents> groceryList = organizedContent.isNotEmpty
      ? organizedContent.map((c) => listContents.fromMap(c)).toList()
      : [];
    return groceryList;
  }

  Future<int> add(listContents listcontents) async {
    Database db = await instance.database;
    return await db.insert('itemList', listcontents.toMap());
  }

  Future<int> remove(int id) async {
    Database db = await instance.database;
    return await db.delete('itemList', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(listContents grocery) async {
    Database db = await instance.database;
    return await db.update('itemList', grocery.toMap(), where: 'id = ?', whereArgs: [grocery.id]);
  }

  Future<List<listNames>> getListNames() async {
    Database db = await instance.database;
    var organizedListContent = await db.query('listNames', orderBy: 'listName');
    List<listNames> listnames = organizedListContent.isNotEmpty
        ? organizedListContent.map((c) => listNames.fromMap(c)).toList()
        : [];
    return listnames;
  }


}