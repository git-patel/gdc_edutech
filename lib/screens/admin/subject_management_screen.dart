import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/widgets.dart';

const List<String> _boards = ['CBSE', 'ICSE', 'State', 'Others'];
const List<String> _standards = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];

/// Full CRUD for subjects (Firestore). List + Add/Edit dialog + Delete with confirm.
class SubjectManagementScreen extends StatelessWidget {
  const SubjectManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Manage Subjects',
        showBackButton: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseService.subjectsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Error loading subjects',
              subtitle: snapshot.error.toString(),
              buttonText: 'Retry',
              onButtonPressed: () => _showAddSubject(context),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget(message: 'Loading subjects...'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return EmptyState(
              icon: Icons.subject_rounded,
              title: 'No subjects yet',
              subtitle: 'Tap + to add your first subject.',
              buttonText: 'Add subject',
              onButtonPressed: () => _showAddSubject(context),
            );
          }
          return MySafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final name = data['name']?.toString() ?? '';
                final board = data['board']?.toString() ?? '';
                final standard = data['standard']?.toString() ?? '';
                final iconUrl = data['iconUrl']?.toString() ?? '';
                final order = (data['order'] is num) ? (data['order'] as num).toInt() : 0;
                return _SubjectListTile(
                  name: name,
                  board: board,
                  standard: standard,
                  iconUrl: iconUrl,
                  order: order,
                  onEdit: () => _showEditSubject(context, doc.id, data),
                  onDelete: () => _confirmDeleteSubject(context, doc.id, name),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubject(context),
        icon: const Icon(Icons.add_rounded),
        label: const BodyText('Add subject'),
      ),
    );
  }

  static void _showAddSubject(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SubjectFormSheet(
        subjectId: null,
        initialName: '',
        initialBoard: _boards.first,
        initialStandard: _standards.first,
        initialIconUrl: '',
        initialOrder: 0,
        onSave: (name, board, standard, iconUrl, order) async {
          await FirebaseService.addSubject({
            'name': name,
            'board': board,
            'standard': standard,
            'iconUrl': iconUrl.trim().isEmpty ? null : iconUrl.trim(),
            'order': order,
          });
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  static void _showEditSubject(BuildContext context, String id, Map<String, dynamic> data) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SubjectFormSheet(
        subjectId: id,
        initialName: data['name']?.toString() ?? '',
        initialBoard: data['board']?.toString() ?? _boards.first,
        initialStandard: data['standard']?.toString() ?? _standards.first,
        initialIconUrl: data['iconUrl']?.toString() ?? '',
        initialOrder: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
        onSave: (name, board, standard, iconUrl, order) async {
          await FirebaseService.updateSubject(id, {
            'name': name,
            'board': board,
            'standard': standard,
            'iconUrl': iconUrl.trim().isEmpty ? null : iconUrl.trim(),
            'order': order,
          });
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  static Future<void> _confirmDeleteSubject(BuildContext context, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const SectionTitle('Delete subject'),
        content: BodyText('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const BodyText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: BodyText('Delete', color: Theme.of(ctx).colorScheme.error),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await FirebaseService.deleteSubject(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject deleted')));
      }
    }
  }
}

class _SubjectListTile extends StatelessWidget {
  const _SubjectListTile({
    required this.name,
    required this.board,
    required this.standard,
    required this.iconUrl,
    required this.order,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
  final String board;
  final String standard;
  final String iconUrl;
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
          if (iconUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(iconUrl, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderIcon(colors)),
            )
          else
            _placeholderIcon(colors),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardTitle(name),
                const SizedBox(height: 4),
                BodySmall('$board • Class $standard', style: TextStyle(color: colors.onSurface.withValues(alpha: 0.75))),
              ],
            ),
          ),
          IconButton(icon: Icon(Icons.edit_rounded, color: colors.primary), onPressed: onEdit),
          IconButton(icon: Icon(Icons.delete_outline_rounded, color: colors.error), onPressed: onDelete),
        ],
      ),
    );
  }

  Widget _placeholderIcon(ColorScheme colors) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.subject_rounded, color: colors.primary, size: 28),
    );
  }
}

class _SubjectFormSheet extends StatefulWidget {
  const _SubjectFormSheet({
    this.subjectId,
    required this.initialName,
    required this.initialBoard,
    required this.initialStandard,
    required this.initialIconUrl,
    required this.initialOrder,
    required this.onSave,
  });

  final String? subjectId;
  final String initialName;
  final String initialBoard;
  final String initialStandard;
  final String initialIconUrl;
  final int initialOrder;
  final Future<void> Function(String name, String board, String standard, String iconUrl, int order) onSave;

  @override
  State<_SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends State<_SubjectFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _iconUrlController;
  late TextEditingController _orderController;
  late String _board;
  late String _standard;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _iconUrlController = TextEditingController(text: widget.initialIconUrl);
    _orderController = TextEditingController(text: widget.initialOrder.toString());
    _board = widget.initialBoard;
    _standard = widget.initialStandard;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconUrlController.dispose();
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
            SectionTitle(widget.subjectId == null ? 'Add subject' : 'Edit subject'),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'e.g. Maths, Science',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _board,
              decoration: dropdownDecoration,
              items: _boards.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (v) => setState(() => _board = v ?? _board),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _standard,
              decoration: dropdownDecoration,
              items: _standards.map((s) => DropdownMenuItem(value: s, child: Text('Class $s'))).toList(),
              onChanged: (v) => setState(() => _standard = v ?? _standard),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _iconUrlController,
              label: 'Icon URL (optional)',
              hint: 'Paste image URL',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _orderController,
              label: 'Order',
              hint: '0',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Cancel',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    size: ButtonSize.medium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Save',
                    onPressed: _saving ? null : _save,
                    isLoading: _saving,
                    size: ButtonSize.medium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.show(context, message: 'Enter name', type: ToastType.error);
      return;
    }
    final order = int.tryParse(_orderController.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      await widget.onSave(name, _board, _standard, _iconUrlController.text.trim(), order);
      if (mounted) {
        AppToast.show(context, message: 'Saved', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Failed: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
