import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, _) {
        final status = connectivityService.syncStatus;
        final lastSync = connectivityService.lastSyncedAt;

        IconData icon;
        Color color;
        String text;

        switch (status) {
          case SyncStatus.synced:
            icon = Icons.cloud_done;
            color = Colors.green;
            text = 'Synchronisé';
            break;
          case SyncStatus.syncing:
            icon = Icons.sync;
            color = Colors.orange;
            text = 'Synchronisation...';
            break;
          case SyncStatus.offline:
            icon = Icons.cloud_off;
            color = Colors.grey;
            text = 'Hors ligne';
            break;
          case SyncStatus.error:
            icon = Icons.error_outline;
            color = Colors.red;
            text = 'Erreur de synchronisation';
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == SyncStatus.syncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (lastSync != null && status == SyncStatus.synced) ...[
                const SizedBox(width: 4),
                Text(
                  '• ${_formatLastSync(lastSync)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }
}