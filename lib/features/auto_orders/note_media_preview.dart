import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';

void showNoteMediaPreview(BuildContext context, NoteMedia media) {
  showDialog<void>(
    context: context,
    builder: (_) {
      if (_isAudio(media)) {
        return _AudioPreviewDialog(media: media);
      }
      if (_isVideo(media)) {
        return _VideoPreviewDialog(media: media);
      }
      return Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(media.url),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                tooltip: 'Close',
                color: Colors.white,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      );
    },
  );
}

bool _isAudio(NoteMedia media) {
  final mime = media.mimeType.toLowerCase();
  if (mime.startsWith('audio/')) return true;
  final url = media.url.toLowerCase();
  return url.contains('.mp3') ||
      url.contains('.wav') ||
      url.contains('.m4a') ||
      url.contains('.aac') ||
      url.contains('.ogg') ||
      url.contains('.flac');
}

bool _isVideo(NoteMedia media) {
  final mime = media.mimeType.toLowerCase();
  if (mime.startsWith('video/')) return true;
  final url = media.url.toLowerCase();
  return url.contains('.mp4') ||
      url.contains('.mov') ||
      url.contains('.webm') ||
      url.contains('.mkv') ||
      url.contains('.avi');
}

class _AudioPreviewDialog extends StatelessWidget {
  const _AudioPreviewDialog({required this.media});

  final NoteMedia media;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(media.originalName.isEmpty
          ? 'Audio attachment'
          : media.originalName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.audiotrack, size: 48),
          const SizedBox(height: 12),
          Text(
            'Open the audio in your default player.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _openExternal(context, media.url),
          child: const Text('Open'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _openExternal(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open audio')),
      );
    }
  }
}

class _VideoPreviewDialog extends StatelessWidget {
  const _VideoPreviewDialog({required this.media});

  final NoteMedia media;

  @override
  Widget build(BuildContext context) {
    final title =
        media.originalName.isEmpty ? 'Video attachment' : media.originalName;
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.movie, size: 48),
          const SizedBox(height: 12),
          Text(
            'Open the video in your default player.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _openExternal(context, media.url),
          child: const Text('Open'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _openExternal(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open video')),
      );
    }
  }
}
