import 'package:flutter/material.dart';
import '../../../data/models.dart';

class FileCard extends StatelessWidget {
  final EntryBase entry;
  final VoidCallback? onOpen;
  final VoidCallback? onShare;
  final VoidCallback? onUnshare;
  final VoidCallback? onDelete;

  const FileCard({
    super.key,
    required this.entry,
    this.onOpen,
    this.onShare,
    this.onUnshare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final icon = entry.type == EntryType.note ? Icons.description : Icons.image;
    final sub = 'Owner: ${entry.ownerId} • Shared: ${entry.sharedWith.length}';
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(entry.title),
        subtitle: Text(sub),
        onTap: onOpen,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'share':
                onShare?.call();
                break;
              case 'unshare':
                onUnshare?.call();
                break;
              case 'delete':
                onDelete?.call();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'share', child: Text('Share...')),
            const PopupMenuItem(value: 'unshare', child: Text('Disable sharing...')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
