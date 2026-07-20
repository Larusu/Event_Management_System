import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:image/image.dart" as img;
import "package:image_picker/image_picker.dart";
import "package:provider/provider.dart";

import "../../../../core/constants/roles.dart";
import "../../../auth/providers/auth_provider.dart";
import "../../../../shared/widgets/app_dialog.dart";
import "../../../../shared/widgets/modal.dart";
import "../../data/campus_map_data.dart";
import "../../models/campus_map.dart";
import '../../models/event.dart';
import "../../providers/create_event_provider.dart";
import "../../providers/created_events_provider.dart";
import "../../providers/event_dashboard_provider.dart";
import "../../providers/event_list_provider.dart";

/// Opens the New Event modal. Captures the ambient list/dashboard providers so
/// the feed can be refreshed after a successful create, and scopes a
/// [CreateEventProvider] to the modal subtree.
void createNewEvent(BuildContext context) {
  final listProvider = context.read<EventListProvider>();
  final dashProvider = context.read<EventDashboardProvider>();
  final createdProvider = context.read<CreatedEventsProvider>();
  ModalContainer.show(
    context: context,
    child: ChangeNotifierProvider(
      create: (_) => CreateEventProvider(),
      child: _CreateEventModal(
        onCreated: () {
          listProvider.load();
          dashProvider.loadFeatured();
          // Keep the owned-events list (and the modal's ownership check) current
          // after creating an event.
          createdProvider.load();
        },
      ),
    ),
  );
}

/// Opens the event form pre-filled for an existing event.
void editEvent(
  BuildContext context, {
  required Event event,
  required VoidCallback onUpdated,
}) {
  ModalContainer.show(
    context: context,
    child: ChangeNotifierProvider(
      create: (_) => CreateEventProvider(),
      child: _CreateEventModal(
        initialEvent: event,
        onCreated: onUpdated,
      ),
    ),
  );
}

class _CreateEventModal extends StatefulWidget {
  const _CreateEventModal({
    this.initialEvent,
    this.onCreated,
  });

  final Event? initialEvent;
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

  // Offline location is picked from the campus map registry (floor -> room) so
  // it always resolves to a known room for the wayfinding map. The room's name
  // is what gets stored as the free-text `location`.
  String? _selectedFloorId;
  String? _selectedRoomId;

  bool get _isEditing => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();
    final event = widget.initialEvent;
    if (event == null) return;
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _categoryController.text = event.tags.join(', ');
    _hostController.text = event.hostName;
    _guestSpeakerController.text = event.guestSpeaker ?? '';
    _streamLinkController.text = event.streamLink ?? '';
    final location = event.location;
    if (location != null && location.isNotEmpty) {
      final room = resolveRoomFromLocation(location);
      if (room != null) {
        _selectedFloorId = room.floorId;
        _selectedRoomId = room.id;
      }
    }
    _contactController.text = event.contactEmails.join(', ');
    _slotsController.text =
        (event.registeredCount + event.slotsRemaining).toString();
    _date = DateTime.tryParse(event.date);
    _startTime = _parseTime(event.startTime);
    _endTime = _parseTime(event.endTime);
    _eventMode = event.eventMode;
    _allDay = event.startTime == '00:00' && event.endTime == '23:59';
    _isOpenToGuests = event.isOpenToGuests;
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _hostController.dispose();
    _guestSpeakerController.dispose();
    _streamLinkController.dispose();
    _contactController.dispose();
    _slotsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final raw = await file.readAsBytes();

    // The backend caps cover images at 5 MB. `image_picker`'s `imageQuality`
    // only shrinks JPEGs, so a large PNG (e.g. a full-res poster) would sail
    // past it and be rejected server-side. Re-encode to JPEG here — downscaling
    // and stepping quality down — so any picked image fits under the cap.
    final compressed = await _compressToJpeg(raw);
    if (!mounted) return;

    final base = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
    setState(() {
      _imageBytes = compressed;
      _imageName = '$base.jpg';
      _imageMime = 'image/jpeg';
    });
  }

  /// Decodes [bytes], downscales the longest side to at most 1600px, and encodes
  /// as JPEG, lowering quality until the result is under the 5 MB backend cap.
  Future<Uint8List> _compressToJpeg(Uint8List bytes) async {
    const maxBytes = 5 * 1024 * 1024;
    const maxDimension = 1600;

    var decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      decoded = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxDimension : null,
        height: decoded.height > decoded.width ? maxDimension : null,
      );
    }

    for (final quality in [85, 70, 55, 40]) {
      final out = img.encodeJpg(decoded, quality: quality);
      if (out.length <= maxBytes) return out;
    }
    return img.encodeJpg(decoded, quality: 40);
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

  void _showError(String message) {
    AppDialog.info(
      context: context,
      icon: Icons.error_outline_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      message: message,
    );
  }

  Future<void> _submit() async {
    final provider = context.read<CreateEventProvider>();
    if (provider.isBusy) return;

    final role = context.read<AuthProvider>().currentUser?.role;
    final autoApproves = role == Roles.faculty || role == Roles.superAdmin;

    // A cover image is required when creating; when editing, the existing
    // cover is kept if no new image is picked.
    if (_imageBytes == null && !_isEditing) {
      _showError('Please add a cover image.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      _showError('Please select an event date.');
      return;
    }

    final TimeOfDay start;
    final TimeOfDay end;
    if (_allDay) {
      start = const TimeOfDay(hour: 0, minute: 0);
      end = const TimeOfDay(hour: 23, minute: 59);
    } else {
      if (_startTime == null || _endTime == null) {
        _showError('Please select start and end times.');
        return;
      }
      if (_minutesOf(_endTime!) <= _minutesOf(_startTime!)) {
        _showError('End time must be after start time.');
        return;
      }
      start = _startTime!;
      end = _endTime!;
    }

    final tags = _splitCsv(_categoryController.text);
    if (tags.isEmpty) {
      _showError('Please add at least one category.');
      return;
    }
    final emails = _splitCsv(_contactController.text);
    if (emails.isEmpty) {
      _showError('Please add at least one contact email.');
      return;
    }
    final slots = int.tryParse(_slotsController.text.trim()) ?? 0;

    // Warn organizers before an edit that will bounce an approved event back to
    // the review queue. Only approval-reset fields trigger this, and only for
    // organizers (faculty/super_admin edits never reset status).
    var willResubmit = false;
    final editedEvent = widget.initialEvent;
    if (editedEvent != null &&
        role == Roles.organizer &&
        editedEvent.status == 'approved') {
      final changed = changedEventFields(
        existing: editedEvent,
        title: _titleController.text,
        description: _descriptionController.text,
        coverImageUrl: editedEvent.coverImageUrl,
        imagePicked: _imageBytes != null,
        date: _formatDate(_date!),
        startTime: _formatTime(start),
        endTime: _formatTime(end),
        eventMode: _eventMode,
        location: _selectedRoomName() ?? '',
        streamLink: _streamLinkController.text,
        hostName: _hostController.text,
        guestSpeaker: _guestSpeakerController.text,
        contactEmails: emails,
        tags: tags,
        slotsTotal: slots,
      );
      if (changed.keys.any(approvalResetFields.contains)) {
        final proceed = await AppDialog.confirm(
          context: context,
          icon: Icons.warning_amber_rounded,
          title: 'Send back for review?',
          message:
              'Editing key details (title, date, time, location, mode, or '
              'slots) sends this approved event back to the review queue until '
              'it is approved again.',
          confirmLabel: 'Save & resubmit',
        );
        if (!proceed) return;
        if (!mounted) return;
        willResubmit = true;
      }
    }

    final ok = await provider.submit(
      imageBytes: _imageBytes,
      imageFilename: _imageName,
      imageMimeType: _imageMime,
      existingEvent: widget.initialEvent,
      title: _titleController.text,
      description: _descriptionController.text,
      date: _formatDate(_date!),
      startTime: _formatTime(start),
      endTime: _formatTime(end),
      eventMode: _eventMode,
      location: _selectedRoomName() ?? '',
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
      await AppDialog.info(
        context: context,
        icon: Icons.check_circle,
        title: _isEditing ? 'Event Updated' : 'Event Created',
        message: _isEditing
            ? (willResubmit
                ? 'Event updated and sent back for review.'
                : 'Event updated.')
            : (autoApproves
                ? 'Event created.'
                : 'Event submitted for approval.'),
      );
      if (mounted) Navigator.pop(context);
    } else {
      _showError(
        provider.errorMessage ??
            'Could not ${_isEditing ? 'update' : 'create'} the event.',
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
            Text(
              _isEditing ? 'Edit Event' : 'New Event',
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
              _buildLocationSelectors(),
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
                  onChanged: _isEditing
                      ? null
                      : (value) => setState(() => _isOpenToGuests = value),
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
                      : Text(_isEditing ? 'Save Changes' : 'Add Event'),
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
              : _isEditing && widget.initialEvent!.coverImageUrl.isNotEmpty
                  ? Image.network(
                      widget.initialEvent!.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined, size: 48),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo,
                            size: 48,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
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

  /// Resolves the name of the currently selected room (stored as `location`),
  /// or null when nothing is selected.
  String? _selectedRoomName() {
    final floorId = _selectedFloorId;
    final roomId = _selectedRoomId;
    if (floorId == null || roomId == null) return null;
    final floor = floorById(floorId);
    if (floor == null) return null;
    for (final room in floor.rooms) {
      if (room.id == roomId) return room.name;
    }
    return null;
  }

  Widget _buildLocationSelectors() {
    final floor =
        _selectedFloorId == null ? null : floorById(_selectedFloorId!);
    final rooms = floor?.rooms ?? const <MapRoom>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedFloorId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "Location - Floor",
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
          ),
          items: [
            for (final f in campusMapRegistry)
              DropdownMenuItem(value: f.id, child: Text(f.displayName)),
          ],
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Select a floor' : null,
          onChanged: (value) => setState(() {
            _selectedFloorId = value;
            _selectedRoomId = null;
          }),
        ),
        const SizedBox(height: 10.0),
        DropdownButtonFormField<String>(
          initialValue: _selectedRoomId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "Location - Room / Area",
            border: OutlineInputBorder(),
            contentPadding:
                EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
          ),
          items: [
            for (final room in rooms)
              DropdownMenuItem(value: room.id, child: Text(room.name)),
          ],
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Select a room / area' : null,
          onChanged: floor == null
              ? null
              : (value) => setState(() => _selectedRoomId = value),
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
