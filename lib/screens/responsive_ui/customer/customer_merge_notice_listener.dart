import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:scheldule/keys/material_key.dart';
import 'package:scheldule/repositories/api_client.dart';

String mergeReasonLabel(String reason) => switch (reason) {
  'mobile' => 'ίδιο κινητό',
  'email' => 'ίδιο email',
  'mobile_and_email' => 'ίδιο κινητό και email',
  _ => 'επιβεβαίωση ιδιοκτήτη',
};

class CustomerMergeNoticeListener extends StatefulWidget {
  const CustomerMergeNoticeListener({
    super.key,
    required this.apiClient,
    required this.child,
  });
  final ApiClient apiClient;
  final Widget child;
  @override
  State<CustomerMergeNoticeListener> createState() =>
      _CustomerMergeNoticeListenerState();
}

class _CustomerMergeNoticeListenerState
    extends State<CustomerMergeNoticeListener> {
  late StreamSubscription<Map<String, dynamic>> _notices;
  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _notices = widget.apiClient.mergeNotices.listen((notice) {
      final revision = widget.apiClient.sessionRevision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || revision != widget.apiClient.sessionRevision) return;
        AppMaterialKey.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 10),
            showCloseIcon: true,
            content: Text(
              'Η καρτέλα «${notice['source_name']}» συγχωνεύτηκε με την «${notice['target_name']}»: ${mergeReasonLabel(notice['reason'].toString())}. Το ιστορικό διατηρήθηκε.',
            ),
          ),
        );
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    });
  }

  @override
  void didUpdateWidget(CustomerMergeNoticeListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiClient != widget.apiClient) {
      _notices.cancel();
      _listen();
    }
  }

  @override
  void dispose() {
    _notices.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
