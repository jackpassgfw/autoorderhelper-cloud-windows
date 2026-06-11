import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

/// Reads an image from the system clipboard and writes it to a temporary
/// file so it can be uploaded. Returns null when the clipboard holds no image.
Future<File?> readClipboardImageFile() async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) return null;
  final reader = await clipboard.read();
  final image =
      await _readImage(reader, Formats.png, 'png') ??
      await _readImage(reader, Formats.jpeg, 'jpg');
  if (image == null) return null;
  final tempDir = await getTemporaryDirectory();
  final fileName =
      'clipboard_${DateTime.now().millisecondsSinceEpoch}.${image.extension}';
  final file = File('${tempDir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(image.bytes, flush: true);
  return file;
}

Future<_ClipboardImage?> _readImage(
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

class _ClipboardImage {
  const _ClipboardImage(this.bytes, this.extension);

  final List<int> bytes;
  final String extension;
}

/// Wraps a text field so that Ctrl+V pastes a clipboard image through
/// [onImage] (Windows only). When the clipboard holds no image, plain text
/// is pasted into [controller] at the current cursor position instead.
class ClipboardImagePaste extends StatelessWidget {
  const ClipboardImagePaste({
    super.key,
    required this.controller,
    required this.onImage,
    required this.child,
  });

  final TextEditingController controller;
  final Future<void> Function(File file) onImage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
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
        child: child,
      ),
    );
  }

  Future<void> _handlePaste() async {
    if (!kIsWeb && Platform.isWindows) {
      File? imageFile;
      try {
        imageFile = await readClipboardImageFile();
      } catch (_) {
        imageFile = null;
      }
      if (imageFile != null) {
        await onImage(imageFile);
        return;
      }
    }
    await _pastePlainText();
  }

  Future<void> _pastePlainText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    final selection = controller.selection;
    final existing = controller.text;
    if (!selection.isValid) {
      controller.text = '$existing$text';
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
      return;
    }
    final updated = existing.replaceRange(selection.start, selection.end, text);
    controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }
}

class _PasteImageIntent extends Intent {
  const _PasteImageIntent();
}
