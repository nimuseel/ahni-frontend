import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/inquiry/application/inquiry_controller.dart';
import 'package:ahni_mobile/features/inquiry/domain/inquiry.dart';
import 'package:flutter/material.dart';

class InquiryPage extends StatefulWidget {
  const InquiryPage({
    required this.controller,
    required this.onAuthenticationRequired,
    super.key,
  });

  final InquiryController controller;
  final VoidCallback onAuthenticationRequired;

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.load();
    });
  }

  void _changed() {
    if (!mounted) return;
    if (widget.controller.state is InquiryAuthenticationRequired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onAuthenticationRequired();
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  Future<void> _openForm() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => InquiryFormPage(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    return Scaffold(
      key: const Key('inquiry-page'),
      appBar: AppBar(
        title: const Text('문의사항'),
        actions: [
          IconButton(
            onPressed: state is InquiryLoading ? null : widget.controller.retry,
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('open-inquiry-form'),
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('문의 등록'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: switch (state) {
              InquiryInitial() || InquiryLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              InquiryEmpty() => _EmptyInquiries(onCreate: _openForm),
              InquiryFailure state => _FailureMessage(
                message: state.message,
                onRetry: widget.controller.retry,
              ),
              InquiryReady state => _InquiryList(inquiries: state.inquiries),
              InquiryAuthenticationRequired() => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }
}

class _InquiryList extends StatelessWidget {
  const _InquiryList({required this.inquiries});

  final List<Inquiry> inquiries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      itemCount: inquiries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final inquiry = inquiries[index];
        return _InquiryCard(inquiry: inquiry);
      },
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({required this.inquiry});

  final Inquiry inquiry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => InquiryDetailPage(inquiry: inquiry),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      inquiry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusBadge(label: inquiry.statusLabel),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                inquiry.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Text(
                _formatDate(inquiry.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InquiryFormPage extends StatefulWidget {
  const InquiryFormPage({required this.controller, super.key});

  final InquiryController controller;

  @override
  State<InquiryFormPage> createState() => _InquiryFormPageState();
}

class _InquiryFormPageState extends State<InquiryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final created = await widget.controller.create(
      title: _titleController.text,
      content: _contentController.text,
    );
    if (created && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.controller.isSubmitting;
    return Scaffold(
      key: const Key('inquiry-form-page'),
      appBar: AppBar(title: const Text('문의 등록')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const WhitespaceWrappedText('학사 정보 이용 중 확인이 필요한 내용을 남겨 주세요.'),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('inquiry-title-field'),
                    controller: _titleController,
                    enabled: !isSubmitting,
                    maxLength: 200,
                    decoration: const InputDecoration(labelText: '제목'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '제목을 입력해 주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('inquiry-content-field'),
                    controller: _contentController,
                    enabled: !isSubmitting,
                    minLines: 8,
                    maxLines: 12,
                    maxLength: 4000,
                    decoration: const InputDecoration(labelText: '내용'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '내용을 입력해 주세요.';
                      }
                      return null;
                    },
                  ),
                  if (widget.controller.formMessage case final message?) ...[
                    const SizedBox(height: 12),
                    WhitespaceWrappedText(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('submit-inquiry'),
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('등록'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InquiryDetailPage extends StatelessWidget {
  const InquiryDetailPage({required this.inquiry, super.key});

  final Inquiry inquiry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('inquiry-detail-page'),
      appBar: AppBar(title: const Text('문의 상세')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: WhitespaceWrappedText(
                        inquiry.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusBadge(label: inquiry.statusLabel),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(inquiry.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                _DetailSection(title: '문의 내용', body: inquiry.content),
                const SizedBox(height: 16),
                _DetailSection(
                  title: '답변',
                  body: inquiry.answer?.trim().isNotEmpty == true
                      ? inquiry.answer!
                      : '아직 답변이 등록되지 않았어요.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          WhitespaceWrappedText(body),
        ],
      ),
    );
  }
}

class _EmptyInquiries extends StatelessWidget {
  const _EmptyInquiries({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const WhitespaceWrappedText('등록된 문의가 없어요.'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('문의 등록'),
        ),
      ],
    );
  }
}

class _FailureMessage extends StatelessWidget {
  const _FailureMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        WhitespaceWrappedText(message),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.year}.${_twoDigits(local.month)}.${_twoDigits(local.day)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
