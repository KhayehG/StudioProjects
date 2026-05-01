import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vocabulary.dart';
import '../../services/vocabulary_service.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final VocabularyService _vocabularyService = VocabularyService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _translationController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();
  final GlobalKey<FormState> _addWordFormKey = GlobalKey<FormState>();

  List<VocabularyWord> _words = <VocabularyWord>[];
  List<VocabularyWord> _dueWords = <VocabularyWord>[];
  bool _isLoading = true;
  String _query = '';
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadWords();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _wordController.dispose();
    _translationController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  Future<String?> _requireUserId() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null && mounted) {
      context.go('/login');
      return null;
    }
    return userId;
  }

  Future<void> _loadWords() async {
    final String? userId = await _requireUserId();
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final List<VocabularyWord> words = await _vocabularyService.fetchAll(userId);
      final List<VocabularyWord> due = await _vocabularyService.fetchDueToday(userId);
      if (!mounted) return;
      setState(() {
        _words = words;
        _dueWords = due;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load words: $error')),
      );
    }
  }

  List<VocabularyWord> get _filteredWords {
    if (_query.isEmpty) return _words;
    return _words
        .where((word) => word.word.toLowerCase().contains(_query))
        .toList();
  }

  Future<void> _showAddWordDialog() async {
    _wordController.clear();
    _translationController.clear();
    _exampleController.clear();
    _selectedLanguage = 'English';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Word'),
              content: Form(
                key: _addWordFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: _wordController,
                        decoration: const InputDecoration(labelText: 'Word'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Word is required'
                                : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _translationController,
                        decoration: const InputDecoration(labelText: 'Translation'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Translation is required'
                                : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLanguage,
                        decoration: const InputDecoration(labelText: 'Language'),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(value: 'English', child: Text('English')),
                          DropdownMenuItem(value: 'isiZulu', child: Text('isiZulu')),
                          DropdownMenuItem(value: 'French', child: Text('French')),
                          DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            _selectedLanguage = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _exampleController,
                        decoration:
                            const InputDecoration(labelText: 'Example Sentence'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Example sentence is required'
                                : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_addWordFormKey.currentState!.validate()) return;
                    final String? userId = await _requireUserId();
                    if (userId == null) return;

                    await _vocabularyService.addWord(userId, <String, dynamic>{
                      'word': _wordController.text.trim(),
                      'translation': _translationController.text.trim(),
                      'language': _selectedLanguage,
                      'exampleSentence': _exampleController.text.trim(),
                    });
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    await _loadWords();
                  },
                  child: const Text('Add Word'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _dueWords.isEmpty
                              ? null
                              : () => context.push('/flashcards'),
                          icon: const Icon(Icons.play_circle_fill),
                          label: Text('Start Review (${_dueWords.length} due)'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SearchBar(
                        controller: _searchController,
                        hintText: 'Search words...',
                        leading: const Icon(Icons.search),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredWords.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.translate, size: 56, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('No words yet. Add one!'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredWords.length,
                          itemBuilder: (context, index) {
                            final VocabularyWord word = _filteredWords[index];
                            final bool isDueToday = !word.nextReviewDate.isAfter(now);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(
                                  word.word,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const SizedBox(height: 4),
                                    Text(word.translation),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: <Widget>[
                                        Chip(label: Text(word.language)),
                                        if (isDueToday)
                                          const Chip(
                                            label: Text('Due Today'),
                                            backgroundColor: Colors.amber,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWordDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
