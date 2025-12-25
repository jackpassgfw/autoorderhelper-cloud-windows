import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../core/api_client.dart';
import 'auto_orders_repository.dart';
import 'models.dart';
import 'note_media_preview.dart';

class ScheduleNoteEditorPage extends ConsumerStatefulWidget {
  const ScheduleNoteEditorPage({
    super.key,
    required this.scheduleId,
    required this.initialNote,
    required this.initialNoteMedia,
  });

  final int scheduleId;
  final String? initialNote;
  final List<NoteMedia> initialNoteMedia;

  @override
  ConsumerState<ScheduleNoteEditorPage> createState() =>
      _ScheduleNoteEditorPageState();
}

class _ScheduleNoteEditorPageState
    extends ConsumerState<ScheduleNoteEditorPage> {
  late final TextEditingController _noteController;
  late List<NoteMedia> _attachments;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _attachments = List<NoteMedia>.from(widget.initialNoteMedia);
    _syncSortOrder();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      child: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
              const _PasteImageIntent(),
        },
        child: Actions(
          actions: {
            _PasteImageIntent: CallbackAction<_PasteImageIntent>(
              onInvoke: (_) {
                _handlePaste();
                return null;
              },
            ),
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      IconButton(
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    Text(
                      'Schedule Note',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      TextField(
                        controller: _noteController,
                        minLines: 6,
                        maxLines: 12,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Attachments',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 8),
                          if (_isUploading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('TODO: Add file picker'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Add file'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_attachments.isEmpty)
                        Text(
                          'Paste an image with Ctrl+V to attach.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _attachments.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemBuilder: (context, index) {
                            final media = _attachments[index];
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      showNoteMediaPreview(context, media),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      color: Colors.black12,
                                      child: Image.network(
                                        media.url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _attachments = [
                                          for (final item in _attachments)
                                            if (item.url != media.url) item,
                                        ];
                                        _syncSortOrder();
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePaste() async {
    if (_isUploading) return;
    if (kIsWeb || !Platform.isWindows) {
      await _pastePlainText();
      return;
    }
    final clipboardImage = await _readClipboardImage();
    if (clipboardImage == null) {
      await _pastePlainText();
      return;
    }
    setState(() => _isUploading = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'clipboard_${DateTime.now().millisecondsSinceEpoch}.${clipboardImage.extension}';
      final file = File(
        '${tempDir.path}${Platform.pathSeparator}$fileName',
      );
      await file.writeAsBytes(clipboardImage.bytes, flush: true);
      final repository = ref.read(autoOrdersRepositoryProvider);
      final uploaded = await repository.uploadNoteMedia(file);
      setState(() {
        _attachments = [..._attachments, uploaded];
        _syncSortOrder();
      });
    } on DioException catch (error) {
      _showError(normalizeErrorMessage(error));
    } catch (_) {
      _showError('Failed to paste image');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pastePlainText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    final selection = _noteController.selection;
    final existing = _noteController.text;
    if (!selection.isValid) {
      _noteController.text = '$existing$text';
      _noteController.selection = TextSelection.collapsed(
        offset: _noteController.text.length,
      );
      return;
    }
    final updated =
        existing.replaceRange(selection.start, selection.end, text);
    final offset = selection.start + text.length;
    _noteController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  Future<_ClipboardImage?> _readClipboardImage() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return null;
    final reader = await clipboard.read();
    return await _readImageFile(reader, Formats.png, 'png') ??
        await _readImageFile(reader, Formats.jpeg, 'jpg');
  }

  Future<_ClipboardImage?> _readImageFile(
    ClipboardReader reader,
    FileFormat format,
    String extension,
  ) async {
    if (!reader.canProvide(format)) return null;
    final completer = Completer<_ClipboardImage?>();
    final progress = reader.getFile(format, (file) async {
      try {
        final bytes = await file.readAll();
        completer.complete(_ClipboardImage(bytes, extension));
      } catch (_) {
        completer.complete(null);
      }
    });
    if (progress == null) return null;
    return completer.future;
  }

  void _syncSortOrder() {
    _attachments = [
      for (var i = 0; i < _attachments.length; i++)
        NoteMedia(
          id: _attachments[i].id,
          url: _attachments[i].url,
          mimeType: _attachments[i].mimeType,
          sizeBytes: _attachments[i].sizeBytes,
          originalName: _attachments[i].originalName,
          sortOrder: i,
        ),
    ];
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      _syncSortOrder();
      final repository = ref.read(autoOrdersRepositoryProvider);
      await repository.updateScheduleNote(
        id: widget.scheduleId,
        note: _noteController.text,
        noteMedia: _attachments,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule note saved')),
      );
      Navigator.of(context).maybePop(true);
    } on DioException catch (error) {
      _showError(normalizeErrorMessage(error));
    } catch (_) {
      _showError('Failed to save schedule note');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _ClipboardImage {
  const _ClipboardImage(this.bytes, this.extension);

  final Uint8List bytes;
  final String extension;
}

class _PasteImageIntent extends Intent {
  const _PasteImageIntent();
}
