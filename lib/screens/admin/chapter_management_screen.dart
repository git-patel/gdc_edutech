import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

/// Full CRUD for chapters. Filter by subject, then list chapters; Add/Edit/Delete.
class ChapterManagementScreen extends StatefulWidget {
  const ChapterManagementScreen({super.key});

  @override
  State<ChapterManagementScreen> createState() => _ChapterManagementScreenState();
}

class _ChapterManagementScreenState extends State<ChapterManagementScreen> {
  String? _selectedSubjectId;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _subjectDocs = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final snap = await FirebaseService.subjectsStream().first;
    if (mounted) setState(() {
      _subjectDocs = snap.docs;
      if (_selectedSubjectId == null && _subjectDocs.isNotEmpty) {
        _selectedSubjectId = _subjectDocs.first.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Manage Chapters',
        showBackButton: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSubjectFilter(context),
          Expanded(
            child: _selectedSubjectId == null
                ? const Center(child: BodyText('Select a subject above'))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseService.chaptersStream(subjectId: _selectedSubjectId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return EmptyState(
                          icon: Icons.error_outline_rounded,
                          title: 'Error loading chapters',
                          subtitle: snapshot.error.toString(),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: LoadingWidget(message: 'Loading chapters...'));
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return EmptyState(
                          icon: Icons.menu_book_rounded,
                          title: 'No chapters yet',
                          subtitle: 'Tap + to add a chapter for this subject.',
                          buttonText: 'Add chapter',
                          onButtonPressed: () => _showAddChapter(context),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          return _ChapterListTile(
                            title: data['title']?.toString() ?? '',
                            description: data['description']?.toString() ?? '',
                            order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
                            onEdit: () => _showEditChapter(context, doc.id, data),
                            onDelete: () => _confirmDeleteChapter(context, doc.id, data['title']?.toString() ?? ''),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedSubjectId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddChapter(context),
              icon: const Icon(Icons.add_rounded),
              label: const BodyText('Add chapter'),
            )
          : null,
    );
  }

  Widget _buildSubjectFilter(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_subjectDocs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: BodySmall('No subjects yet. Add subjects first.'),
      );
    }
    final dropdownDecoration = InputDecoration(
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.dividerColor)),
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Subject'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSubjectId,
            decoration: dropdownDecoration,
            items: _subjectDocs.map((d) {
              final name = d.data()['name']?.toString() ?? d.id;
              return DropdownMenuItem(value: d.id, child: Text(name));
            }).toList(),
            onChanged: (v) => setState(() => _selectedSubjectId = v),
          ),
        ],
      ),
    );
  }

  void _showAddChapter(BuildContext context) {
    if (_selectedSubjectId == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ChapterFormSheet(
        chapterId: null,
        subjectId: _selectedSubjectId!,
        subjectDocs: _subjectDocs,
        initialTitle: '',
        initialDescription: '',
        initialOrder: 0,
        onSave: (subjectId, title, description, order) async {
          await FirebaseService.addChapter({
            'subjectId': subjectId,
            'title': title,
            'description': description.trim().isEmpty ? null : description.trim(),
            'order': order,
          });
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showEditChapter(BuildContext context, String id, Map<String, dynamic> data) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ChapterFormSheet(
        chapterId: id,
        subjectId: data['subjectId']?.toString() ?? _selectedSubjectId ?? '',
        subjectDocs: _subjectDocs,
        initialTitle: data['title']?.toString() ?? '',
        initialDescription: data['description']?.toString() ?? '',
        initialOrder: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
        onSave: (subjectId, title, description, order) async {
          await FirebaseService.updateChapter(id, {
            'subjectId': subjectId,
            'title': title,
            'description': description.trim().isEmpty ? null : description.trim(),
            'order': order,
          });
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _confirmDeleteChapter(BuildContext context, String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const SectionTitle('Delete chapter'),
        content: BodyText('Delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const BodyText('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: BodyText('Delete', color: Theme.of(ctx).colorScheme.error)),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await FirebaseService.deleteChapter(id);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chapter deleted')));
    }
  }
}

class _ChapterListTile extends StatelessWidget {
  const _ChapterListTile({
    required this.title,
    required this.description,
    required this.order,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String description;
  final int order;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(8)),
            child: Center(child: BodySmall('$order', style: TextStyle(fontWeight: FontWeight.w600, color: colors.primary))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardTitle(title),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  BodySmall(description, maxLines: 2, style: TextStyle(color: colors.onSurface.withValues(alpha: 0.75))),
                ],
              ],
            ),
          ),
          IconButton(icon: Icon(Icons.edit_rounded, color: colors.primary), onPressed: onEdit),
          IconButton(icon: Icon(Icons.delete_outline_rounded, color: colors.error), onPressed: onDelete),
        ],
      ),
    );
  }
}

class _ChapterFormSheet extends StatefulWidget {
  const _ChapterFormSheet({
    this.chapterId,
    required this.subjectId,
    required this.subjectDocs,
    required this.initialTitle,
    required this.initialDescription,
    required this.initialOrder,
    required this.onSave,
  });

  final String? chapterId;
  final String subjectId;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> subjectDocs;
  final String initialTitle;
  final String initialDescription;
  final int initialOrder;
  final Future<void> Function(String subjectId, String title, String description, int order) onSave;

  @override
  State<_ChapterFormSheet> createState() => _ChapterFormSheetState();
}

class _ChapterFormSheetState extends State<_ChapterFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _orderController;
  late String _subjectId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _orderController = TextEditingController(text: widget.initialOrder.toString());
    _subjectId = widget.subjectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(widget.chapterId == null ? 'Add chapter' : 'Edit chapter'),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _subjectId,
              decoration: dropdownDecoration,
              items: widget.subjectDocs.map((d) {
                final name = d.data()['name']?.toString() ?? d.id;
                return DropdownMenuItem(value: d.id, child: Text(name));
              }).toList(),
              onChanged: (v) => setState(() => _subjectId = v ?? _subjectId),
            ),
            const SizedBox(height: 16),
            CustomTextField(controller: _titleController, label: 'Title', hint: 'Chapter title'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              label: 'Description (optional)',
              hint: 'Short description',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            CustomTextField(controller: _orderController, label: 'Order', hint: '0', keyboardType: TextInputType.number),
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

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppToast.show(context, message: 'Enter title', type: ToastType.error);
      return;
    }
    final order = int.tryParse(_orderController.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      await widget.onSave(_subjectId, title, _descriptionController.text.trim(), order);
      if (mounted) AppToast.show(context, message: 'Saved', type: ToastType.success);
    } catch (e) {
      if (mounted) AppToast.show(context, message: 'Failed: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
