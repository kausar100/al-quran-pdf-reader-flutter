import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AL Quran',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyPDFReader(),
    );
  }
}

class MyPDFReader extends StatefulWidget {
  const MyPDFReader({super.key});

  @override
  State<MyPDFReader> createState() => _MyPDFReaderState();
}

class _MyPDFReaderState extends State<MyPDFReader> with WidgetsBindingObserver {
  String pathPDF = "";
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();

  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  Future<File> fromAsset(String asset, String filename) async {
    // To open from assets, you can copy them to the app storage folder, and the access them "locally"
    Completer<File> completer = Completer();

    try {
      var dir = await getApplicationDocumentsDirectory();
      debugPrint(dir.toString());

      File file = File("${dir.path}/$filename");
      var data = await rootBundle.load(asset);
      var bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
      completer.complete(file);
    } catch (e) {
      throw Exception('Error parsing asset file!');
    }

    return completer.future;
  }

  @override
  void initState() {
    super.initState();
    fromAsset('assets/al_quran.pdf', 'al_quran.pdf').then((f) {
      setState(() {
        pathPDF = f.path;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Al Quran'),
        actions: <Widget>[
          FutureBuilder<PDFViewController>(
            future: _controller.future,
            builder: (context, AsyncSnapshot<PDFViewController> snapshot) {
              if (snapshot.hasData) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Visibility(
                      visible: currentPage != 0,
                      child: IconButton(
                        tooltip: 'Go to previous page',
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () async {
                          await snapshot.data!
                              .setPage((currentPage! - 1) % pages!);
                        },
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Visibility(
                      visible: currentPage != 0,
                      child: IconButton(
                        tooltip: 'Go to next page',
                        icon: const Icon(Icons.arrow_forward_rounded),
                        onPressed: () async {
                          await snapshot.data!
                              .setPage((currentPage! + 1) % pages!);
                        },
                      ),
                    ),
                  ],
                );
              }

              return Container();
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: pathPDF.isNotEmpty
          ? Stack(
              children: <Widget>[
                PDFView(
                  filePath: pathPDF,
                  enableSwipe: true,
                  swipeHorizontal: true,
                  autoSpacing: false,
                  pageFling: true,
                  pageSnap: true,
                  defaultPage: currentPage!,
                  fitPolicy: FitPolicy.BOTH,
                  preventLinkNavigation:
                      false, // if set to true the link is handled in flutter
                  onRender: (_pages) {
                    setState(() {
                      pages = _pages;
                      isReady = true;
                    });
                  },
                  onError: (error) {
                    setState(() {
                      errorMessage = error.toString();
                    });
                    print(error.toString());
                  },
                  onPageError: (page, error) {
                    setState(() {
                      errorMessage = '$page: ${error.toString()}';
                    });
                    print('$page: ${error.toString()}');
                  },
                  onViewCreated: (PDFViewController pdfViewController) {
                    _controller.complete(pdfViewController);
                  },
                  onPageChanged: (int? page, int? total) {
                    print('page change: $page/$total');
                    setState(() {
                      currentPage = page;
                    });
                  },
                ),
                errorMessage.isEmpty
                    ? !isReady
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : Container()
                    : Center(
                        child: Text(errorMessage),
                      )
              ],
            )
          : const Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}
