import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:scheldule/repositories/api_client.dart';
import 'package:scheldule/repositories/expense_repository.dart';

class FinanceReportButton extends StatefulWidget {
  final int year;
  final int month;
  final Future<void> Function(Uint8List bytes, String filename)? save;
  const FinanceReportButton({
    super.key,
    required this.year,
    required this.month,
    this.save,
  });

  @override
  State<FinanceReportButton> createState() => _FinanceReportButtonState();
}

class _FinanceReportButtonState extends State<FinanceReportButton> {
  bool _busy = false;

  Future<void> _download() async {
    if (_busy) return;
    final year = widget.year, month = widget.month;
    final api = context.read<ApiClient>();
    final revision = api.sessionRevision;
    setState(() => _busy = true);
    try {
      final bytes = await context
          .read<TransactionRepository>()
          .downloadMonthlyReport(year: year, month: month);
      if (!mounted || revision != api.sessionRevision) return;
      final name = 'rantevia-finance-$year-${month.toString().padLeft(2, '0')}';
      if (widget.save != null) {
        await widget.save!(bytes, '$name.pdf');
      } else {
        await FileSaver.instance.saveFile(
          name: name,
          bytes: bytes,
          fileExtension: 'pdf',
          mimeType: MimeType.pdf,
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Δεν έγινε λήψη της αναφοράς. Δοκίμασε ξανά.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: _busy ? null : _download,
    icon: _busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.download_outlined),
    label: Text(_busy ? 'Δημιουργία PDF…' : 'Λήψη μηνιαίας αναφοράς PDF'),
  );
}
