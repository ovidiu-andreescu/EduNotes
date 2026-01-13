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
    final bool isNote = entry.type == EntryType.note;
    final icon = isNote ? Icons.description : Icons.image;
    final iconColor = isNote ? Colors.blue : Colors.purple;

    final bool hasActions = onShare != null || onUnshare != null || onDelete != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Owner: $ownerEmail',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasActions)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
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
                      items.add(
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 20),
                              SizedBox(width: 12),
                              Text('Share'),
                            ],
                          ),
                        ),
                      );
                    }
                    if (onUnshare != null) {
                      items.add(
                        const PopupMenuItem(
                          value: 'unshare',
                          child: Row(
                            children: [
                              Icon(Icons.person_off, size: 20),
                              SizedBox(width: 12),
                              Text('Disable sharing'),
                            ],
                          ),
                        ),
                      );
                    }
                    if (onDelete != null) {
                      items.add(
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      );
                    }
                    return items;
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}