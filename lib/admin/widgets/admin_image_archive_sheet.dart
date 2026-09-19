import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/core/widgets/catalog_network_image.dart';
import 'package:matlobgo/services/image_archive_service.dart';

/// عرض أرشيف صور كيان — من نماذج التعديل.
class AdminImageArchiveSheet extends StatelessWidget {
  const AdminImageArchiveSheet({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.title,
  });

  final String entityType;
  final String entityId;
  final String title;

  static Future<void> show(
    BuildContext context, {
    required String entityType,
    required String entityId,
    required String title,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AdminImageArchiveSheet(
        entityType: entityType,
        entityId: entityId,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ImageArchiveService();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'أرشيف الصور — $title',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<ImageArchiveEntry>>(
                  stream: service.watchByEntity(
                    entityType: entityType,
                    entityId: entityId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final entries = snapshot.data ?? [];
                    if (entries.isEmpty) {
                      return Center(
                        child: Text(
                          'لا توجد صور مؤرشفة لهذا العنصر.',
                          style: GoogleFonts.cairo(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        return Card(
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: CatalogNetworkImage(
                                  imageUrl: e.imageUrl.isNotEmpty
                                      ? e.imageUrl
                                      : e.thumbUrl,
                                  fallback: const Icon(Icons.image_outlined),
                                ),
                              ),
                            ),
                            title: Text(
                              e.field,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              e.archivedAt.toString().substring(0, 16),
                              style: GoogleFonts.cairo(fontSize: 11),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
