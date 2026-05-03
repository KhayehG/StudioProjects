import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/vocabulary.dart';
import '../../services/vocabulary_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/word_form_dialog.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  List<VocabularyWord> _allWords = <VocabularyWord>[];
  List<VocabularyWord> _filteredWords = <VocabularyWord>[];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedLanguage = 'All';
  String _sortBy = 'alphabetical';
  String? _uid;

  final TextEditingController _searchController = TextEditingController();
  final VocabularyService _vocabService = VocabularyService();

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _searchController.addListener(_onSearchChanged);
    _loadWords();
  }

  void _onSearchChanged() {
    _searchQuery = _searchController.text;
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    final String? uid = _uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        context.go('/login');
      }
      return;
    }
    _uid = uid;

    setState(() => _isLoading = true);

    try {
      final List<VocabularyWord> words = await _vocabService.fetchAll(uid);
      if (!mounted) {
        return;
      }
      setState(() {
        _allWords = words;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load words: $e')),
      );
    }
  }

  void _applyFilters() {
    List<VocabularyWord> result = List<VocabularyWord>.from(_allWords);

    if (_selectedLanguage != 'All') {
      result = result
          .where((VocabularyWord w) => w.language == _selectedLanguage)
          .toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final String q = _searchQuery.trim().toLowerCase();
      result = result
          .where(
            (VocabularyWord w) =>
                w.word.toLowerCase().contains(q) ||
                w.translation.toLowerCase().contains(q),
          )
          .toList();
    }

    switch (_sortBy) {
      case 'alphabetical':
        result.sort(
          (VocabularyWord a, VocabularyWord b) =>
              a.word.toLowerCase().compareTo(b.word.toLowerCase()),
        );
        break;
      case 'language':
        result.sort((VocabularyWord a, VocabularyWord b) {
          final int c = a.language.compareTo(b.language);
          if (c != 0) {
            return c;
          }
          return a.word.toLowerCase().compareTo(b.word.toLowerCase());
        });
        break;
      case 'due_date':
        result.sort(
          (VocabularyWord a, VocabularyWord b) =>
              a.nextReviewDate.compareTo(b.nextReviewDate),
        );
        break;
      case 'date_added':
        result.sort(
          (VocabularyWord a, VocabularyWord b) =>
              b.lastReviewed.compareTo(a.lastReviewed),
        );
        break;
      default:
        break;
    }

    setState(() => _filteredWords = result);
  }

  Future<void> _showAddDialog() async {
    final String? uid = _uid;
    if (uid == null) {
      return;
    }
    final Object? result = await showDialog<Object>(
      context: context,
      builder: (BuildContext context) => const WordFormDialog(),
    );
    if (result is Map<String, dynamic>) {
      try {
        await _vocabService.addWord(uid, result);
        await _loadWords();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Word added successfully! 🎉')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not add word: $e')),
          );
        }
      }
    }
  }

  Future<void> _showEditDialog(VocabularyWord word) async {
    final String? uid = _uid;
    if (uid == null) {
      return;
    }
    final Object? result = await showDialog<Object>(
      context: context,
      builder: (BuildContext context) =>
          WordFormDialog(existingWord: word),
    );
    if (result is Map<String, dynamic>) {
      try {
        await _vocabService.updateWord(uid, word.id, result);
        await _loadWords();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Word updated successfully! ✏️')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not update word: $e')),
          );
        }
      }
    }
  }

  Future<bool> _showDeleteConfirmation(VocabularyWord word) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Word'),
          content: Text(
            "Delete '${word.word}' from your vocabulary? This cannot be undone.",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFe74c3c),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return ok == true;
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF0F2F8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Sort by',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1a1d2e),
                ),
              ),
              const SizedBox(height: 16),
              _sortOption(ctx, 'A to Z', 'alphabetical', Icons.sort_by_alpha),
              _sortOption(ctx, 'By Language', 'language', Icons.language),
              _sortOption(ctx, 'Due for Review', 'due_date', Icons.schedule),
              _sortOption(
                ctx,
                'Recently Added',
                'date_added',
                Icons.new_releases,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sortOption(
    BuildContext sheetContext,
    String title,
    String value,
    IconData icon,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF6C5CE7), size: 22),
      ),
      title: Text(title),
      trailing: _sortBy == value
          ? const Icon(Icons.check, color: Color(0xFF6C5CE7))
          : null,
      onTap: () {
        setState(() => _sortBy = value);
        _applyFilters();
        Navigator.of(sheetContext).pop();
      },
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Expanded(
      child: NeuCard(
        small: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              '',
              style: TextStyle(fontSize: 1),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7c82a0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final DateTime now = DateTime.now();
    final int diff = date.difference(now).inDays;
    if (diff == 0) {
      return 'today';
    }
    if (diff == 1) {
      return 'tomorrow';
    }
    if (diff < 7) {
      return 'in $diff days';
    }
    return '${date.day}/${date.month}';
  }

  Color _languageColor(String lang) {
    switch (lang) {
      case 'English':
        return const Color(0xFF6C5CE7);
      case 'isiZulu':
        return const Color(0xFF00b894);
      case 'French':
        return const Color(0xFFe67e22);
      case 'Spanish':
        return const Color(0xFFe74c3c);
      default:
        return const Color(0xFF7c82a0);
    }
  }

  bool _isDue(VocabularyWord word) =>
      word.nextReviewDate.isBefore(DateTime.now());

  Widget _languageFilterPill(String language) {
    final bool selected = _selectedLanguage == language;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedLanguage = language);
          _applyFilters();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6C5CE7) : const Color(0xFFF0F2F8),
            borderRadius: BorderRadius.circular(50),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                      offset: const Offset(3, 3),
                      blurRadius: 8,
                    ),
                  ]
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0xFFd0d3de),
                      offset: Offset(3, 3),
                      blurRadius: 6,
                    ),
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-3, -3),
                      blurRadius: 6,
                    ),
                  ],
          ),
          child: Text(
            language,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF7c82a0),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sortPill() {
    return GestureDetector(
      onTap: _showSortSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F8),
          borderRadius: BorderRadius.circular(50),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0xFFd0d3de),
              offset: Offset(3, 3),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.white,
              offset: Offset(-3, -3),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.sort, size: 14, color: Color(0xFF6C5CE7)),
            SizedBox(width: 4),
            Text(
              'Sort',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6C5CE7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = _uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: const Text('Vocabulary'),
        backgroundColor: const Color(0xFFF0F2F8),
        foregroundColor: const Color(0xFF1a1d2e),
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0xFFd0d3de),
                    offset: Offset(3, 3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search words or translations...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF7c82a0)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Color(0xFF7c82a0)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _applyFilters();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                ...<String>['All', 'English', 'isiZulu', 'French', 'Spanish']
                    .map(_languageFilterPill),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: const Color(0xFFd0d3de),
                ),
                _sortPill(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _statChip(
                  '${_allWords.length}',
                  'Total Words',
                  const Color(0xFF6C5CE7),
                ),
                const SizedBox(width: 8),
                _statChip(
                  '${_filteredWords.where((VocabularyWord w) => w.nextReviewDate.isBefore(DateTime.now())).length}',
                  'Due Today',
                  const Color(0xFFe74c3c),
                ),
                const SizedBox(width: 8),
                _statChip(
                  '${_filteredWords.length}',
                  'Showing',
                  const Color(0xFF00b894),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.translate,
                              size: 64,
                              color: Color(0xFF7c82a0),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'No words match your search'
                                    : _selectedLanguage != 'All'
                                        ? 'No $_selectedLanguage words yet'
                                        : 'No words yet. Tap + to add your first word!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF7c82a0),
                                ),
                              ),
                            ),
                            if (_searchQuery.isEmpty &&
                                _selectedLanguage == 'All') ...<Widget>[
                              const SizedBox(height: 16),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: GradientButton(
                                  label: 'Add First Word',
                                  color: const Color(0xFF6C5CE7),
                                  onPressed: _showAddDialog,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredWords.length,
                        itemBuilder: (BuildContext context, int index) {
                          final VocabularyWord word = _filteredWords[index];
                          final Color langColor = _languageColor(word.language);
                          final bool isDue = _isDue(word);

                          return Dismissible(
                            key: Key(word.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              return _showDeleteConfirmation(word);
                            },
                            onDismissed: (_) async {
                              if (uid == null) {
                                return;
                              }
                              final VocabularyWord removed = word;
                              setState(() {
                                _allWords.removeWhere(
                                  (VocabularyWord w) => w.id == removed.id,
                                );
                              });
                              _applyFilters();
                              try {
                                await _vocabService.deleteWord(uid, removed.id);
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${removed.word} deleted'),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      onPressed: () async {
                                        try {
                                          await _vocabService.addWord(
                                            uid,
                                            removed.toMap(),
                                          );
                                          if (context.mounted) {
                                            await _loadWords();
                                          }
                                        } catch (_) {}
                                      },
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Delete failed: $e'),
                                  ),
                                );
                                await _loadWords();
                              }
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE8E8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(Icons.delete, color: Color(0xFFe74c3c)),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFe74c3c),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            child: NeuCard(
                              small: true,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Container(
                                            width: 10,
                                            height: 10,
                                            margin: const EdgeInsets.only(
                                                top: 5),
                                            decoration: BoxDecoration(
                                              color: langColor,
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  word.word,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1a1d2e),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  word.translation,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF7c82a0),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (word.exampleSentence
                                                    .isNotEmpty) ...<Widget>[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '"${word.exampleSentence}"',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontStyle: FontStyle.italic,
                                                      color: Color(0xFF9ba0b8),
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: <Widget>[
                                                    Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: langColor
                                                            .withValues(
                                                                alpha: 0.12),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(50),
                                                      ),
                                                      child: Text(
                                                        word.language,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: langColor,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isDue
                                                            ? const Color(
                                                                0xFFFFE8E8)
                                                            : const Color(
                                                                0xFFF0F2F8),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(50),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: <Widget>[
                                                          Icon(
                                                            Icons.schedule,
                                                            size: 10,
                                                            color: isDue
                                                                ? const Color(
                                                                    0xFFe74c3c)
                                                                : const Color(
                                                                    0xFF7c82a0),
                                                          ),
                                                          const SizedBox(
                                                              width: 3),
                                                          Text(
                                                            isDue
                                                                ? 'Due now'
                                                                : 'Due ${_formatDate(word.nextReviewDate)}',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: isDue
                                                                  ? const Color(
                                                                      0xFFe74c3c)
                                                                  : const Color(
                                                                      0xFF7c82a0),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        GestureDetector(
                                          onTap: () => _showEditDialog(word),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            child: const Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: Color(0xFF6C5CE7),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () =>
                                              context.push('/flashcards'),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            child: const Icon(
                                              Icons.style_outlined,
                                              size: 18,
                                              color: Color(0xFF00b894),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
