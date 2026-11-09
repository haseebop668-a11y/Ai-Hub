import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../data/local_database.dart';

class PdfLibraryPage extends StatefulWidget {
  const PdfLibraryPage({super.key});

  @override
  State<PdfLibraryPage> createState() => _PdfLibraryPageState();
}

class _PdfLibraryPageState extends State<PdfLibraryPage> {
  late Future<List<Map<String, Object?>>> _books;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _books = LocalDatabase.instance.importedBooks();
  }

  Future<void> _importPdf() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        allowMultiple: false,
        withData: false,
      );
      if (selection == null || selection.files.isEmpty) return;
      final selected = selection.files.single;
      final sourcePath = selected.path;
      if (sourcePath == null || sourcePath.isEmpty) {
        throw StateError('The selected PDF is not available as a local file.');
      }

      final source = File(sourcePath);
      if (!await source.exists()) {
        throw StateError('The selected PDF could not be read.');
      }
      final size = await source.length();
      if (size == 0) throw StateError('The selected PDF is empty.');
      if (size > 250 * 1024 * 1024) {
        throw StateError('PDFs larger than 250 MB are not supported.');
      }

      final appDirectory = await getApplicationDocumentsDirectory();
      final libraryDirectory = Directory(p.join(appDirectory.path, 'books'));
      await libraryDirectory.create(recursive: true);
      final safeName = '${DateTime.now().microsecondsSinceEpoch}_${p.basename(selected.name)}';
      final destination = await source.copy(p.join(libraryDirectory.path, safeName));
      final title = p.basenameWithoutExtension(selected.name).trim();
      await LocalDatabase.instance.addImportedBook(
        title: title.isEmpty ? 'Imported PDF' : title,
        localPath: destination.path,
      );
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF copied to your offline library.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF import failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _removeBook(Map<String, Object?> book) async {
    final id = book['id']! as int;
    final path = book['local_path']! as String;
    await LocalDatabase.instance.removeImportedBook(id);
    final file = File(path);
    if (await file.exists()) await file.delete();
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline PDF library')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _importing ? null : _importPdf,
        icon: _importing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.file_upload_outlined),
        label: Text(_importing ? 'Importing…' : 'Import a PDF'),
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _books,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load library: ${snapshot.error}'));
          }
          final books = snapshot.data ?? const [];
          if (books.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 56),
                    SizedBox(height: 14),
                    Text('Your offline library is empty',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                    SizedBox(height: 8),
                    Text(
                      'Import a PDF you own or have permission to use. '
                      'The file is copied into this app and can be opened without internet.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final book = books[index];
              final path = book['local_path']! as String;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                  title: Text(book['title']! as String),
                  subtitle: const Text('Stored on this device · PDF'),
                  onTap: () {
                    if (!File(path).existsSync()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('This PDF file is missing.')),
                      );
                      return;
                    }
                    Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => _PdfReaderPage(
                        title: book['title']! as String,
                        path: path,
                      ),
                    ));
                  },
                  trailing: IconButton(
                    tooltip: 'Remove PDF',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeBook(book),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PdfReaderPage extends StatefulWidget {
  const _PdfReaderPage({required this.title, required this.path});

  final String title;
  final String path;

  @override
  State<_PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<_PdfReaderPage> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openFile(widget.path),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: PdfViewPinch(controller: _controller),
    );
  }
}
