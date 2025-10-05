import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:scalex_innovation/services/conversation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SummariesScreen extends StatefulWidget {
  const SummariesScreen({Key? key}) : super(key: key);

  @override
  State<SummariesScreen> createState() => _SummariesScreenState();
}

class _SummariesScreenState extends State<SummariesScreen> {
  late Future<List<Map<String, dynamic>>> _futureSummaries;
  final convService = ConversationService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _futureSummaries = uid == null ? Future.value([]) : convService.listRemoteSummaries(firebaseUid: uid);
    setState(() {});
  }

  Future<void> _refresh() async {
    _load();
    await _futureSummaries;
  }

  void _showDetail(Map<String, dynamic> s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text('summaries.detail_title'.tr(), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (s['context'] != null && (s['context'] as String).isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [Icon(Icons.label_outline, size: 16, color: Colors.blue.shade700), const SizedBox(width: 8), Expanded(child: Text(s['context'], style: TextStyle(color: Colors.blue.shade900, fontSize: 13)))]),
              ),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: Text(s['summary'] ?? '', style: const TextStyle(fontSize: 15, height: 1.6)))),
            const SizedBox(height: 16),
            Row(children: [Icon(Icons.access_time, size: 14, color: Colors.grey[600]), const SizedBox(width: 6), Text(_formatDate(s['createdAt']), style: TextStyle(color: Colors.grey[600], fontSize: 12))]),
          ],
        ),
      ),
    );
  }

  static String _formatDate(dynamic v) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(v as String));
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text('summaries.title'.tr(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refresh)],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureSummaries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.error_outline, size: 48, color: Colors.red[300]), const SizedBox(height: 12), Text('summaries.loading_error'.tr(), style: TextStyle(color: Colors.grey[600]))]));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(children: [SizedBox(height: MediaQuery.of(context).size.height * 0.35), Icon(Icons.summarize_outlined, size: 64, color: Colors.grey[300]), const SizedBox(height: 16), Center(child: Text('summaries.no_summaries'.tr(), style: TextStyle(color: Colors.grey[600], fontSize: 16)))]),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final s = list[i];
                final summaryText = (s['summary'] as String?) ?? '';
                final preview = summaryText.length > 100 ? '${summaryText.substring(0, 100)}...' : summaryText;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: InkWell(
                    onTap: () => _showDetail(s),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (s['context'] != null && (s['context'] as String).isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                              child: Text(s['context'], style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                            ),
                          const SizedBox(height: 8),
                          Text(preview, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Row(children: [Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey[400]), const SizedBox(width: 6), Text(s['conversationId']?.toString() ?? '—', style: TextStyle(fontSize: 11, color: Colors.grey[600]))]),
                            Text(_formatDate(s['createdAt']), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ]),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}