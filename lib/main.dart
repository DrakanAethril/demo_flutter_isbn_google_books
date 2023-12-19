import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  String manualISBN = '';
  String bookTitle = '';
  String author = '';
  String imageURL = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ISBN Book Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 300,
              width: 300,
              child: QRView(
                key: qrKey,
                onQRViewCreated: (controller) {
                  this.controller = controller;
                  controller.scannedDataStream.listen((scanData) async {
                    // Handle scanned data if needed
                    if (scanData.code != null) {
                      await getBookInfo(scanData.code.toString());
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text('OR'),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) {
                manualISBN = value;
              },
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Enter ISBN'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (manualISBN.isNotEmpty) {
                  await getBookInfo(manualISBN);
                }
              },
              child: const Text('Search'),
            ),
            const SizedBox(height: 20),
            Text('Title: $bookTitle'),
            Text('Author: $author'),
            const SizedBox(height: 20),
            imageURL.isNotEmpty
                ? Image.network(
                    imageURL,
                    height: 200,
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Future<void> getBookInfo(String isbn) async {
    final response = await http.get(
      Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);

      if (data.containsKey('items')) {
        var bookInfo = data['items'][0]['volumeInfo'];
        setState(() {
          bookTitle = bookInfo['title'];
          author = bookInfo['authors'] != null ? bookInfo['authors'][0] : '';
          //imageURL = bookInfo['imageLinks']['thumbnail'] ?? '';
        });
      } else {
        setState(() {
          bookTitle = 'Book not found';
          author = '';
          imageURL = '';
        });
      }
    } else {
      setState(() {
        bookTitle = 'Error fetching book information';
        author = '';
        imageURL = '';
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}