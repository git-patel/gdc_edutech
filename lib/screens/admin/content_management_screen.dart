import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

const _kLibraryFilter = 'library';
const List<String> _contentTypes = ['pdf', 'video', 'audio', 'image', 'html', 'mindmap', 'quiz'];
const List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
const List<String> _tagOptions = ['JEE', 'NEET', 'Motivation', 'Olympiad', 'School exams', 'General knowledge', 'Formula', 'PYQ'];

/// Full CRUD for contents. Filter by chapter; list with thumbnail, type, isPremium; Add/Edit with file upload.
class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  State<ContentManagementScreen> createState() => _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  String? _filterChapterId;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _subjectDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _chapterDocs = [];
  final Map<String, String> _subjectNames = {};

  @override
  void initState() {
    super.initState();
    _loadSubjectsAndChapters();
  }

  Future<void> _loadSubjectsAndChapters() async {
    final subSnap = await FirebaseService.subjectsStream().first;
    final chapSnap = await FirebaseService.chaptersStream().first;
    final subjectList = subSnap.docs;
    final subjectNames = {for (var d in subjectList) d.id: d.data()['name']?.toString() ?? d.id};
    if (mounted) {
      setState(() {
        _subjectDocs = subjectList;
        _chapterDocs = chapSnap.docs;
        _subjectNames.addAll(subjectNames);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Manage Contents', showBackButton: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilter(context),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _filterChapterId == null
                  ? FirebaseService.contentsStream()
                  : _filterChapterId == _kLibraryFilter
                      ? FirebaseService.contentsStream(libraryOnly: true)
                      : FirebaseService.contentsStream(chapterId: _filterChapterId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return EmptyState(icon: Icons.error_outline_rounded, title: 'Error', subtitle: snapshot.error.toString());
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingWidget(message: 'Loading contents...'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return EmptyState(
                    icon: Icons.library_books_rounded,
                    title: 'No contents',
                    subtitle: _filterChapterId != null ? 'Try another filter.' : 'Tap + to add content.',
                    buttonText: 'Add content',
                    onButtonPressed: () => _showAddContent(context),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final chapterId = data['chapterId']?.toString();
                    final chapterTitle = chapterId != null ? _chapterTitle(chapterId) : 'Library';
                    return _ContentListTile(
                      title: data['title']?.toString() ?? '',
                      type: data['type']?.toString() ?? 'pdf',
                      thumbnailUrl: data['thumbnailUrl']?.toString(),
                      chapterTitle: chapterTitle,
                      isPremium: data['isPremium'] == true,
                      onEdit: () => _showEditContent(context, doc.id, data),
                      onDelete: () => _confirmDeleteContent(context, doc.id, data['title']?.toString() ?? ''),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContent(context),
        icon: const Icon(Icons.add_rounded),
        label: const BodyText('Add content'),
      ),
    );
  }

  String _chapterTitle(String chapterId) {
    final list = _chapterDocs.where((d) => d.id == chapterId).toList();
    if (list.isEmpty) return chapterId;
    final ch = list.first;
    final subId = ch.data()['subjectId']?.toString();
    final subName = _subjectNames[subId] ?? subId ?? '';
    final title = ch.data()['title']?.toString() ?? '';
    return subName.isEmpty ? title : '$subName – $title';
  }

  Widget _buildFilter(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dropdownDecoration = InputDecoration(
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.dividerColor)),
    );
    final options = <String?, String>{null: 'All', _kLibraryFilter: 'Library only'};
    for (final d in _chapterDocs) {
      options[d.id] = _chapterTitle(d.id);
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Filter by chapter'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: _filterChapterId,
            decoration: dropdownDecoration,
            items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _filterChapterId = v),
          ),
        ],
      ),
    );
  }

  void _showAddContent(BuildContext context) {
    _showContentForm(context, contentId: null, initialData: null);
  }

  void _showEditContent(BuildContext context, String id, Map<String, dynamic> data) {
    _showContentForm(context, contentId: id, initialData: data);
  }

  void _showContentForm(BuildContext context, {String? contentId, Map<String, dynamic>? initialData}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ContentFormSheet(
        contentId: contentId,
        initialData: initialData,
        chapterDocs: _chapterDocs,
        subjectNames: _subjectNames,
        onSave: (data) async {
          if (contentId == null) {
            await FirebaseService.addContent(data);
          } else {
            await FirebaseService.updateContent(contentId, data);
          }
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _confirmDeleteContent(BuildContext context, String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const SectionTitle('Delete content'),
        content: BodyText('Delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const BodyText('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: BodyText('Delete', color: Theme.of(ctx).colorScheme.error)),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await FirebaseService.deleteContent(id);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Content deleted')));
    }
  }
}

class _ContentListTile extends StatelessWidget {
  const _ContentListTile({
    required this.title,
    required this.type,
    this.thumbnailUrl,
    required this.chapterTitle,
    required this.isPremium,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String type;
  final String? thumbnailUrl;
  final String chapterTitle;
  final bool isPremium;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video': return Icons.video_library_rounded;
      case 'audio': return Icons.audiotrack_rounded;
      case 'image': return Icons.image_rounded;
      case 'html': return Icons.code_rounded;
      case 'mindmap': return Icons.account_tree_rounded;
      case 'quiz': return Icons.quiz_rounded;
      default: return Icons.picture_as_pdf_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.dividerColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                ? Image.network(thumbnailUrl!, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(colors))
                : _placeholder(colors),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_typeIcon(type), size: 18, color: colors.primary),
                    const SizedBox(width: 6),
                    Expanded(child: CardTitle(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (isPremium) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(6)),
                      child: Caption('Premium', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                BodySmall(chapterTitle, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7))),
              ],
            ),
          ),
          IconButton(icon: Icon(Icons.edit_rounded, color: colors.primary), onPressed: onEdit),
          IconButton(icon: Icon(Icons.delete_outline_rounded, color: colors.error), onPressed: onDelete),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme colors) {
    return Container(width: 56, height: 56, color: colors.primaryContainer, child: Icon(_typeIcon(type), color: colors.primary));
  }
}

class _ContentFormSheet extends StatefulWidget {
  const _ContentFormSheet({
    this.contentId,
    this.initialData,
    required this.chapterDocs,
    required this.subjectNames,
    required this.onSave,
  });

  final String? contentId;
  final Map<String, dynamic>? initialData;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> chapterDocs;
  final Map<String, String> subjectNames;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_ContentFormSheet> createState() => _ContentFormSheetState();
}

class _ContentFormSheetState extends State<_ContentFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _thumbnailController;
  late TextEditingController _durationController;
  late String _type;
  late String? _chapterId;
  late String _difficulty;
  late bool _isPremium;
  late List<String> _tags;
  String? _downloadUrl;
  bool _uploading = false;
  double _uploadProgress = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _titleController = TextEditingController(text: d?['title']?.toString() ?? '');
    _thumbnailController = TextEditingController(text: d?['thumbnailUrl']?.toString() ?? '');
    _durationController = TextEditingController(text: (d?['duration'] != null ? (d!['duration'] is num ? (d['duration'] as num).toInt() : d['duration']) : '').toString());
    _type = d?['type']?.toString() ?? 'pdf';
    _chapterId = d?['chapterId']?.toString();
    if (_chapterId != null && _chapterId!.isEmpty) _chapterId = null;
    _difficulty = d?['difficulty']?.toString() ?? 'Easy';
    _isPremium = d?['isPremium'] == true;
    _downloadUrl = d?['url']?.toString();
    final tags = d?['tags'];
    if (tags is List) {
      _tags = tags.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    } else {
      _tags = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _thumbnailController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dropdownDecoration = InputDecoration(
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.dividerColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary, width: 1.5)),
    );
    final chapterOptions = <String?>[null];
    for (final c in widget.chapterDocs) {
      chapterOptions.add(c.id);
    }
    String chapterLabel(String? id) {
      if (id == null) return 'Library (no chapter)';
      final list = widget.chapterDocs.where((d) => d.id == id).toList();
      if (list.isEmpty) return id!;
      final ch = list.first;
      final subId = ch.data()['subjectId']?.toString();
      final subName = widget.subjectNames[subId] ?? '';
      final title = ch.data()['title']?.toString() ?? '';
      return subName.isEmpty ? title : '$subName – $title';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(widget.contentId == null ? 'Add content' : 'Edit content'),
            const SizedBox(height: 16),
            CustomTextField(controller: _titleController, label: 'Title', hint: 'Content title'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: dropdownDecoration,
              items: _contentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: _uploading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, value: _uploadProgress)) : const Icon(Icons.upload_file_rounded),
              label: BodyText(_downloadUrl != null ? 'File: uploaded' : 'Upload file (PDF/video/audio/image)'),
            ),
            if (_uploading) Padding(padding: const EdgeInsets.only(top: 8), child: BodySmall('Uploading... ${(_uploadProgress * 100).toInt()}%')),
            const SizedBox(height: 16),
            CustomTextField(controller: _thumbnailController, label: 'Thumbnail URL (optional)', hint: 'Paste URL'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _chapterId,
              decoration: dropdownDecoration,
              items: chapterOptions.map((id) => DropdownMenuItem(value: id, child: Text(chapterLabel(id)))).toList(),
              onChanged: (v) => setState(() => _chapterId = v),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tagOptions.map((tag) {
                final selected = _tags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) _tags.add(tag); else _tags.remove(tag);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: dropdownDecoration,
              items: _difficulties.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _difficulty = v ?? _difficulty),
            ),
            const SizedBox(height: 16),
            CustomTextField(controller: _durationController, label: 'Duration (minutes)', hint: '0', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            Row(
              children: [
                BodyText('Premium'),
                const SizedBox(width: 12),
                Switch(value: _isPremium, onChanged: (v) => setState(() => _isPremium = v)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: SecondaryButton(text: 'Cancel', onPressed: _saving ? null : () => Navigator.pop(context), size: ButtonSize.medium)),
                const SizedBox(width: 12),
                Expanded(child: PrimaryButton(text: 'Save', onPressed: _saving ? null : _save, isLoading: _saving, size: ButtonSize.medium)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    final file = File(path);
    final name = result.files.single.name;
    final ext = name.contains('.') ? name.split('.').last : 'bin';
    final storagePath = 'contents/${DateTime.now().millisecondsSinceEpoch}.$ext';
    setState(() => _uploading = true);
    try {
      final url = await FirebaseService.uploadFileAndGetUrl(file, storagePath);
      if (mounted) setState(() {
        _downloadUrl = url;
        _uploading = false;
      });
      if (mounted && url != null) AppToast.show(context, message: 'File uploaded', type: ToastType.success);
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        AppToast.show(context, message: 'Upload failed: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppToast.show(context, message: 'Enter title', type: ToastType.error);
      return;
    }
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'title': title,
        'type': _type,
        'url': _downloadUrl ?? widget.initialData?['url'],
        'thumbnailUrl': _thumbnailController.text.trim().isEmpty ? null : _thumbnailController.text.trim(),
        'chapterId': _chapterId,
        'tags': _tags,
        'difficulty': _difficulty,
        'duration': duration,
        'isPremium': _isPremium,
      };
      await widget.onSave(data);
      if (mounted) AppToast.show(context, message: 'Saved', type: ToastType.success);
    } catch (e) {
      if (mounted) AppToast.show(context, message: 'Failed: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
