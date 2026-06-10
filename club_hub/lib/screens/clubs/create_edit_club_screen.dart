import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../../providers/club_provider.dart';
import '../../models/club.dart';
import '../../theme/app_theme.dart';
import '../../utils/mock_data.dart';

class CreateEditClubScreen extends StatefulWidget {
  final Club? club;
  const CreateEditClubScreen({super.key, this.club});

  @override
  State<CreateEditClubScreen> createState() => _CreateEditClubScreenState();
}

class _CreateEditClubScreenState extends State<CreateEditClubScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _scheduleCtrl;
  late String _category;
  late String _emoji;
  late String _colorHex;
  bool _saving = false;

  bool get _isEditing => widget.club != null;

  @override
  void initState() {
    super.initState();
    final c = widget.club;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _scheduleCtrl = TextEditingController(text: c?.meetingSchedule ?? '');
    _category = c?.category ?? MockData.clubCategories[1];
    _emoji = c?.emoji ?? '💻';
    _colorHex = c?.colorHex ?? MockData.clubColors.first['hex']!;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _scheduleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();
    final clubProv = context.read<ClubProvider>();
    final user = auth.currentUser!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await Future.delayed(const Duration(milliseconds: 400));

    if (_isEditing) {
      final updated = widget.club!.copyWith(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        emoji: _emoji,
        colorHex: _colorHex,
        meetingSchedule: _scheduleCtrl.text.trim(),
      );
      clubProv.updateClub(updated);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Club updated successfully!'), behavior: SnackBarBehavior.floating),
        );
        navigator.pop();
      }
    } else {
      final newClub = Club(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        leaderId: user.id,
        leaderName: user.name,
        memberIds: [user.id],
        pendingMemberIds: [],
        emoji: _emoji,
        colorHex: _colorHex,
        createdAt: DateTime.now(),
        tags: [],
        meetingSchedule: _scheduleCtrl.text.trim(),
      );
      clubProv.createClub(newClub);
      auth.addJoinedClub(newClub.id);
      auth.addBadge('leader');
      auth.addPoints(200);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Club created! +200 points earned 🎉'), behavior: SnackBarBehavior.floating),
        );
        navigator.pop();
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Club' : 'Create Club'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickEmoji,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: _parseColor(_colorHex).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: _parseColor(_colorHex), width: 2),
                    ),
                    child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 44))),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text('Tap to change emoji', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 24),
              _label('Club Name *'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'e.g. ALU Tech Hub'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _label('Description *'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'What is this club about? What do members do?'),
                validator: (v) => v == null || v.trim().length < 20 ? 'Description must be at least 20 characters' : null,
              ),
              const SizedBox(height: 16),
              _label('Category *'),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: MockData.clubCategories
                    .where((c) => c != 'All')
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 16),
              _label('Meeting Schedule'),
              TextFormField(
                controller: _scheduleCtrl,
                decoration: const InputDecoration(hintText: 'e.g. Every Thursday, 5:00 PM'),
              ),
              const SizedBox(height: 20),
              _label('Club Color'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: MockData.clubColors.map((colorMap) {
                  final hex = colorMap['hex']!;
                  final color = _parseColor(hex);
                  final selected = _colorHex == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _colorHex = hex),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: Colors.black, width: 3) : null,
                        boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] : null,
                      ),
                      child: selected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_isEditing ? 'Update Club' : 'Create Club'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickEmoji() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose an Emoji', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: MockData.clubEmojis.map((e) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _emoji = e);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _emoji == e ? const Color(0x1F1565C0) : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: _emoji == e ? Border.all(color: AppColors.primary) : null,
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 26))),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
