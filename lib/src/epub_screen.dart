import 'dart:io';
import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EpubScreen extends StatefulWidget {
  final String filePath;

  const EpubScreen({Key? key, required this.filePath}) : super(key: key);

  factory EpubScreen.fromPath({required String filePath}) {
    return EpubScreen(filePath: filePath);
  }

  @override
  State<EpubScreen> createState() => _EpubScreenState();
}

class _EpubScreenState extends State<EpubScreen> {
  late EpubController _epubController;
  late SharedPreferences _prefs;
  double _fontSize = 18.0;
  bool _isDarkMode = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initReader();
  }

  Future<void> _initReader() async {
    _prefs = await SharedPreferences.getInstance();
    _fontSize = _prefs.getDouble('fontSize') ?? 18.0;
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    _currentIndex = _prefs.getInt('lastIndex_${widget.filePath}') ?? 0;

    _epubController = EpubController(
      document: EpubDocument.openFile(File(widget.filePath)),
      epubCfi: _currentIndex > 0 ? 'epubcfi(/0/$_currentIndex)' : null,
    );
  }

  void _saveReaderPreferences() async {
    await _prefs.setDouble('fontSize', _fontSize);
    await _prefs.setBool('isDarkMode', _isDarkMode);
    await _prefs.setInt('lastIndex_${widget.filePath}', _currentIndex);
  }

  void _showReaderSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reader Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Font Size'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (_fontSize > 12) _fontSize -= 2;
                            _saveReaderPreferences();
                          });
                        },
                      ),
                      Text(_fontSize.toString()),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            if (_fontSize < 32) _fontSize += 2;
                            _saveReaderPreferences();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                    _saveReaderPreferences();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _saveReaderPreferences();
              Navigator.pop(context);
            },
          ),
          title: EpubViewActualChapter(
            controller: _epubController,
            builder: (chapterValue) => Text(
              chapterValue?.chapter?.Title?.replaceAll('\n', '') ?? '',
              style: TextStyle(fontSize: _fontSize * 0.8),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showReaderSettings,
            ),
          ],
        ),
        body: EpubView(
          controller: _epubController,
          onChapterChanged: (chapter) {
            setState(() {
              _currentIndex = chapter?.chapterNumber ?? 0;
              _saveReaderPreferences();
            });
          },
          onDocumentLoaded: (document) {
            // Document loaded successfully
          },
          onDocumentError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading document: $error')),
            );
          },
          builders: EpubViewBuilders<DefaultBuilderOptions>(
            options: DefaultBuilderOptions(
              textStyle: TextStyle(
                fontSize: _fontSize,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  void dispose() {
    _saveReaderPreferences();
    _epubController.dispose();
    super.dispose();
  }
}
