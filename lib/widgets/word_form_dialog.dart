import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import 'gradient_button.dart';

class WordFormDialog extends StatefulWidget {
  const WordFormDialog({super.key, this.existingWord});

  final VocabularyWord? existingWord;

  @override
  State<WordFormDialog> createState() => _WordFormDialogState();
}

class _WordFormDialogState extends State<WordFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _wordController;
  late final TextEditingController _translationController;
  late final TextEditingController _exampleController;
  String _selectedLanguage = 'English';

  static const List<String> _languages = <String>[
    'English',
    'isiZulu',
    'French',
    'Spanish',
  ];

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _neuField({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    final VocabularyWord? w = widget.existingWord;
    _wordController = TextEditingController(text: w?.word ?? '');
    _translationController = TextEditingController(text: w?.translation ?? '');
    _exampleController = TextEditingController(text: w?.exampleSentence ?? '');
    if (w != null) {
      _selectedLanguage =
          _languages.contains(w.language) ? w.language : 'English';
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    _translationController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(<String, dynamic>{
      'word': _wordController.text.trim(),
      'translation': _translationController.text.trim(),
      'language': _selectedLanguage,
      'exampleSentence': _exampleController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.existingWord != null;

    return Dialog(
      backgroundColor: const Color(0xFFF0F2F8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                isEdit ? 'Edit Word' : 'Add Word',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1a1d2e),
                ),
              ),
              const SizedBox(height: 18),
              _neuField(
                child: TextFormField(
                  controller: _wordController,
                  decoration: _fieldDecoration('Word'),
                  validator: (String? v) =>
                      (v == null || v.trim().isEmpty) ? 'Word is required' : null,
                ),
              ),
              const SizedBox(height: 12),
              _neuField(
                child: TextFormField(
                  controller: _translationController,
                  decoration: _fieldDecoration('Translation'),
                  validator: (String? v) => (v == null || v.trim().isEmpty)
                      ? 'Translation is required'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              _neuField(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  decoration: _fieldDecoration('Language'),
                  items: _languages
                      .map(
                        (String lang) => DropdownMenuItem<String>(
                          value: lang,
                          child: Text(lang),
                        ),
                      )
                      .toList(),
                  onChanged: (String? v) {
                    if (v != null) {
                      setState(() => _selectedLanguage = v);
                    }
                  },
                  validator: (String? v) =>
                      (v == null || v.isEmpty) ? 'Select a language' : null,
                ),
              ),
              const SizedBox(height: 12),
              _neuField(
                child: TextFormField(
                  controller: _exampleController,
                  maxLines: 3,
                  decoration: _fieldDecoration('Example sentence (optional)'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7c82a0),
                        side: const BorderSide(color: Color(0xFF7c82a0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      label: 'Save',
                      color: const Color(0xFF6C5CE7),
                      onPressed: _onSave,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
