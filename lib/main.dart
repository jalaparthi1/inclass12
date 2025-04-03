import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(InventoryApp());
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.tealAccent,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(
            color: Colors.tealAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.tealAccent,
        ),
      ),
      home: InventoryHomePage(),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final CollectionReference inventory =
      FirebaseFirestore.instance.collection('inventory');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Inventory Items',
              style: Theme.of(context).textTheme.headline6?.copyWith(
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: inventory.snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No items found.'));
                  }
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3 / 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var document = snapshot.data!.docs[index];
                      return _buildInventoryCard(document);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(),
        child: Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildInventoryCard(QueryDocumentSnapshot document) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document['name'],
              style: TextStyle(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  fontWeight: FontWeight.bold),
            ),
            Text(
              'Quantity: ${document['quantity']}',
              style: TextStyle(color: Colors.white70),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.tealAccent),
                  onPressed: () => _showItemDialog(document: document),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteItem(document.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDialog({QueryDocumentSnapshot? document}) {
    final TextEditingController nameController =
        TextEditingController(text: document?.get('name') ?? '');
    final TextEditingController quantityController = TextEditingController(
        text: document?.get('quantity')?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(document == null ? 'Add Item' : 'Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Item Name'),
              ),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _saveItem(
                nameController.text,
                quantityController.text,
                document?.id,
              ),
              child: Text(document == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  void _saveItem(String name, String quantity, String? id) async {
    if (name.isNotEmpty && quantity.isNotEmpty) {
      try {
        int qty = int.parse(quantity);
        if (id == null) {
          await inventory.add({'name': name, 'quantity': qty});
        } else {
          await inventory.doc(id).update({'name': name, 'quantity': qty});
        }
      } catch (e) {
        print("Error saving item: $e");
      }
    }
    Navigator.of(context).pop();
  }

  void _deleteItem(String id) async {
    try {
      await inventory.doc(id).delete();
    } catch (e) {
      print("Error deleting item: $e");
    }
  }
}
