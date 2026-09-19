import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matlobgo/core/theme/app_colors.dart';
import 'package:matlobgo/models/app_user.dart';
import 'package:matlobgo/models/user_role.dart';
import 'package:matlobgo/repositories/user_repository.dart';

/// اختيار عملاء متعددين — لحملات specificUsers.
Future<List<AppUser>?> showAdminUserMultiPicker(
  BuildContext context, {
  List<AppUser> initial = const [],
}) {
  return showModalBottomSheet<List<AppUser>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _UserMultiPickerSheet(initial: initial),
  );
}

class _UserMultiPickerSheet extends StatefulWidget {
  const _UserMultiPickerSheet({required this.initial});

  final List<AppUser> initial;

  @override
  State<_UserMultiPickerSheet> createState() => _UserMultiPickerSheetState();
}

class _UserMultiPickerSheetState extends State<_UserMultiPickerSheet> {
  final _repo = UserRepository();
  final _search = TextEditingController();
  late final Map<String, AppUser> _selected = {
    for (final u in widget.initial) u.uid: u,
  };
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'اختر العملاء',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${_selected.length} محدّد',
                    style: GoogleFonts.cairo(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'بحث...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<AppUser>>(
                stream: _repo.watchUsersByRole(UserRole.customer),
                builder: (context, snap) {
                  var users = snap.data ?? [];
                  if (_query.isNotEmpty) {
                    users = users
                        .where(
                          (u) =>
                              u.name.toLowerCase().contains(_query) ||
                              u.email.toLowerCase().contains(_query) ||
                              u.phone.contains(_query),
                        )
                        .toList();
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final u = users[i];
                      final checked = _selected.containsKey(u.uid);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected[u.uid] = u;
                            } else {
                              _selected.remove(u.uid);
                            }
                          });
                        },
                        title: Text(
                          u.name.isEmpty ? u.email : u.name,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          u.email,
                          style: GoogleFonts.cairo(fontSize: 11),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('إلغاء', style: GoogleFonts.cairo()),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _selected.values.toList()),
                    child: Text('تأكيد', style: GoogleFonts.cairo()),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
