import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:image_picker/image_picker.dart";
import "package:provider/provider.dart";

import "../../../../core/constants/roles.dart";
import "../../../auth/providers/auth_provider.dart";
import "../../../../shared/widgets/modal.dart";
import "../../providers/create_event_provider.dart";
import "../../providers/event_dashboard_provider.dart";
import "../../providers/event_list_provider.dart";

/// Opens the New Event modal. Captures the ambient list/dashboard providers so
/// the feed can be refreshed after a successful create, and scopes a
/// [CreateEventProvider] to the modal subtree.
void createNewEvent(BuildContext context) {
  final listProvider = context.read<EventListProvider>();
  final dashProvider = context.read<EventDashboardProvider>();
  final role = context.read<AuthProvider>().currentUser?.role;

  ModalContainer.show(
    context: context,
    child: ChangeNotifierProvider(
      create: (_) => CreateEventProvider(),
      child: _CreateEventModal(
        creatorRole: role,
        onCreated: () {
          listProvider.load();
          dashProvider.loadFeatured();
        },
      ),
    ),
  );
}

class _CreateEventModal extends StatefulWidget {
  const _CreateEventModal({this.creatorRole, this.onCreated});

  final String? creatorRole;
  final VoidCallback? onCreated;

  @override
  State<_CreateEventModal> createState() => _CreateEventModalState();
}

class _CreateEventModalState extends State<_CreateEventModal> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _hostController = TextEditingController();
  final _guestSpeakerController = TextEditingController();
  final _locationController = TextEditingController();
  final _streamLinkController = TextEditingController();
  final _contactController = TextEditingController();
  final _slotsController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;
  String? _imageMime;

  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  String _eventMode = 'offline';
  bool _allDay = false;
  bool _isOpenToGuests = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _hostController.dispose();
    _guestSpeakerController.dispose();
    _locationController.dispose();
    _streamLinkController.dispose();
    _contactController.dispose();
    _slotsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageName = file.name;
      _imageMime = file.mimeType ?? _mimeFromName(file.name);
    });
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ??
          const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  String _formatDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  List<String> _splitCsv(String raw) =>
      raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _submit() async {
    final provider = context.read<CreateEventProvider>();
    if (provider.isBusy) return;

    // Captured up front so the success message survives the Navigator.pop that
    // removes this widget (and its context) from the tree.
    final messenger = ScaffoldMessenger.of(context);

    if (_imageBytes == null) {
      _snack('Please add a cover image.', error: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      _snack('Please select an event date.', error: true);
      return;
    }

    final TimeOfDay start;
    final TimeOfDay end;
    if (_allDay) {
      start = const TimeOfDay(hour: 0, minute: 0);
      end = const TimeOfDay(hour: 23, minute: 59);
    } else {
      if (_startTime == null || _endTime == null) {
        _snack('Please select start and end times.', error: true);
        return;
      }
      if (_minutesOf(_endTime!) <= _minutesOf(_startTime!)) {
        _snack('End time must be after start time.', error: true);
        return;
      }
      start = _startTime!;
      end = _endTime!;
    }

    final tags = _splitCsv(_categoryController.text);
    if (tags.isEmpty) {
      _snack('Please add at least one category.', error: true);
      return;
    }
    final emails = _splitCsv(_contactController.text);
    if (emails.isEmpty) {
      _snack('Please add at least one contact email.', error: true);
      return;
    }
    final slots = int.tryParse(_slotsController.text.trim()) ?? 0;

    final ok = await provider.submit(
      imageBytes: _imageBytes!,
      imageFilename: _imageName ?? 'cover.jpg',
      imageMimeType: _imageMime ?? 'image/jpeg',
      title: _titleController.text,
      description: _descriptionController.text,
      date: _formatDate(_date!),
      startTime: _formatTime(start),
      endTime: _formatTime(end),
      eventMode: _eventMode,
      location: _locationController.text,
      streamLink: _streamLinkController.text,
      hostName: _hostController.text,
      guestSpeaker: _guestSpeakerController.text,
      contactEmails: emails,
      tags: tags,
      isOpenToGuests: _isOpenToGuests,
      slotsTotal: slots,
    );

    if (!mounted) return;
    if (ok) {
      widget.onCreated?.call();
      Navigator.pop(context);
      final isOrganizer = widget.creatorRole == Roles.organizer;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isOrganizer ? 'Event submitted for approval.' : 'Event created.',
          ),
        ),
      );
    } else {
      _snack(
        provider.errorMessage ?? 'Could not create the event.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.watch<CreateEventProvider>().isBusy;
    final isOnline = _eventMode == 'online';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "New Event",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15.0),
            Center(child: _buildImagePicker()),
            const SizedBox(height: 15.0),
            _field(_titleController, "Event Title"),
            const SizedBox(height: 10.0),
            _field(
              _descriptionController,
              "Description",
              minLines: 2,
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 10.0),
            _field(
              _categoryController,
              "Category (comma-separated)",
              hint: "e.g. Technology, Students Only",
            ),
            const SizedBox(height: 10.0),
            _buildModeSelector(),
            const SizedBox(height: 10.0),
            if (isOnline)
              _field(_streamLinkController, "Stream Link")
            else
              _field(
                _locationController,
                "Location",
                minLines: 2,
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
            const SizedBox(height: 10.0),
            _buildAllDayToggle(),
            const SizedBox(height: 10.0),
            _buildDateRow(),
            if (!_allDay) ...[
              const SizedBox(height: 10.0),
              _buildTimeRow(),
            ],
            const SizedBox(height: 10.0),
            _field(_hostController, "Host Name"),
            const SizedBox(height: 10.0),
            _field(
              _guestSpeakerController,
              "Guest Speaker (optional)",
              required: false,
            ),
            const SizedBox(height: 10.0),
            _field(
              _contactController,
              "Contact Emails (comma-separated)",
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10.0),
            _field(
              _slotsController,
              "Total Slots",
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final n = int.tryParse((value ?? '').trim());
                if (n == null || n <= 0) {
                  return 'Enter a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Open to guests",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch.adaptive(
                  value: _isOpenToGuests,
                  onChanged: (value) => setState(() => _isOpenToGuests = value),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            const Divider(height: 1),
            const SizedBox(height: 15.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: isBusy ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isBusy ? null : _submit,
                  child: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Add Event"),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.0),
        child: Container(
          width: 150,
          height: 150,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: _imageBytes != null
              ? Image.memory(_imageBytes!, fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 6),
                    Text("Add cover",
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        const Text("Mode", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 16),
        Expanded(
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'offline', label: Text("Offline")),
              ButtonSegment(value: 'online', label: Text("Online")),
            ],
            selected: {_eventMode},
            onSelectionChanged: (selection) =>
                setState(() => _eventMode = selection.first),
          ),
        ),
      ],
    );
  }

  Widget _buildAllDayToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("All Day", style: TextStyle(fontWeight: FontWeight.bold)),
        Switch.adaptive(
          value: _allDay,
          onChanged: (value) => setState(() => _allDay = value),
        ),
      ],
    );
  }

  Widget _buildDateRow() {
    return OutlinedButton.icon(
      onPressed: _pickDate,
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(_date == null ? "Select Date" : _formatDate(_date!)),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _buildTimeRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickTime(isStart: true),
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(
              _startTime == null ? "Start Time" : _formatTime(_startTime!),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickTime(isStart: false),
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(
              _endTime == null ? "End Time" : _formatTime(_endTime!),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int? minLines,
    int? maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator ??
          (required
              ? (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null
              : null),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
      ),
    );
  }
}
