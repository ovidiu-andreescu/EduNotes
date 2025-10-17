import 'package:flutter/material.dart';
import '../../../data/models.dart';

class FileCard extends StatelessWidget {
  final EntryBase entry;
  final String ownerEmail;
  final VoidCallback? onOpen;
  final VoidCallback? onShare;
  final VoidCallback? onUnshare;
  final VoidCallback? onDelete;

  const FileCard({
    super.key,
    required this.entry,
    required this.ownerEmail,
    this.onOpen,
    this.onShare,
    this.onUnshare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final icon = entry.type == EntryType.note ? Icons.description : Icons.image;
    final sub = 'Owner: $ownerEmail • Shared: ${entry.sharedWith.length}';
    final bool hasActions = onShare != null || onUnshare != null || onDelete != null;
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(entry.title),
        subtitle: Text(sub),
        onTap: onOpen,
        trailing: hasActions
          ? PopupMenuButton<String>(
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
          itemBuilder: (context) {
            final List<PopupMenuEntry<String>> items = [];
            if (onShare != null) {
              items.add(const PopupMenuItem(value: 'share', child: Text('Share...')));
            }
            if (onUnshare != null) {
              items.add(const PopupMenuItem(value: 'unshare', child: Text('Disable sharing...')));
            }
            if (onDelete != null) {
              items.add(const PopupMenuItem(value: 'delete', child: Text('Delete')));
            }
            return items;
          },
        ) : null,
      ),
    );
  }
}
