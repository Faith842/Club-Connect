import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../models/event.dart';
import '../../theme/app_theme.dart';
import '../../utils/mock_data.dart';

class CreateEditEventScreen extends StatefulWidget {
  final String clubId;
  final String clubName;
  final Event? event;
  const CreateEditEventScreen({super.key, required this.clubId, required this.clubName, this.event});

  @override
  State<CreateEditEventScreen> createState() => _CreateEditEventScreenState();
}

class _CreateEditEventScreenState extends State<CreateEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _maxCtrl;
  late String _category;
  late String _format;
  late String _emoji;
  late String _colorHex;
  late DateTime _date;
  bool _saving = false;

  bool get _isEditing => widget.event != null;

  static const _formats = ['In-Person', 'Virtual', 'Hybrid'];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _timeCtrl = TextEditingController(text: e?.time ?? '');
    _maxCtrl = TextEditingController(text: e?.maxAttendees == 0 ? '' : '${e?.maxAttendees ?? ''}');
    _category = e?.category ?? MockData.eventCategories[1];
    _format = e?.format ?? 'In-Person';
    _emoji = e?.emoji ?? '🎯';
    _colorHex = e?.colorHex ?? '#1565C0';
    _date = e?.date ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _timeCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();
    final eventProv = context.read<EventProvider>();
    final user = auth.currentUser!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await Future.delayed(const Duration(milliseconds: 400));

    if (_isEditing) {
      final updated = widget.event!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        date: _date,
        time: _timeCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        format: _format,
        maxAttendees: int.tryParse(_maxCtrl.text) ?? 0,
        emoji: _emoji,
        colorHex: _colorHex,
      );
      eventProv.updateEvent(updated);
    } else {
      final newEvent = Event(
        id: eventProv.generateId(),
        clubId: widget.clubId,
        clubName: widget.clubName,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        date: _date,
        time: _timeCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        format: _format,
        maxAttendees: int.tryParse(_maxCtrl.text) ?? 0,
        rsvpdUserIds: [],
        organizerId: user.id,
        organizerName: user.name,
        emoji: _emoji,
        colorHex: _colorHex,
      );
      eventProv.createEvent(newEvent);
      auth.addPoints(150);
    }

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Event updated!' : 'Event posted! +150 points 🎉'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      navigator.pop();
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Post Event'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0x1F1565C0),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 40))),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(child: Text('Tap to change emoji', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              const SizedBox(height: 24),
              _label('Event Title *'),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(hintText: 'e.g. ALU Hackathon 2026'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              _label('Description *'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Describe the event, agenda, and what attendees can expect'),
                validator: (v) => v == null || v.trim().length < 20 ? 'Please add a longer description (min 20 chars)' : null,
              ),
              const SizedBox(height: 16),
              _label('Date *'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(_date),
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _label('Time *'),
              TextFormField(
                controller: _timeCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. 2:00 PM – 5:00 PM',
                  prefixIcon: Icon(Icons.access_time_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Time is required' : null,
              ),
              const SizedBox(height: 16),
              _label('Location *'),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. Innovation Lab, Block C',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Category'),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          items: MockData.eventCategories
                              .where((c) => c != 'All')
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (v) => setState(() => _category = v!),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Format'),
                        DropdownButtonFormField<String>(
                          initialValue: _format,
                          items: _formats.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) => setState(() => _format = v!),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label('Max Attendees (leave blank for unlimited)'),
              TextFormField(
                controller: _maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 100',
                  prefixIcon: Icon(Icons.people_outline),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_isEditing ? 'Update Event' : 'Post Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickEmoji() {
    final emojis = ['🎯', '🏆', '🤖', '🎭', '🌍', '🤝', '🧘', '🏃', '🗣️', '🌳', '🚀', '💻', '🎓', '🎵', '🔬', '⚽'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Event Emoji', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis.map((e) => GestureDetector(
                onTap: () { setState(() => _emoji = e); Navigator.pop(context); },
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _emoji == e ? const Color(0x1F1565C0) : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: _emoji == e ? Border.all(color: AppColors.primary) : null,
                  ),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 26))),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('This will remove the event and all RSVPs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<EventProvider>().deleteEvent(widget.event!.id);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event deleted'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
  );
}
