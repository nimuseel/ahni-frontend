import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/graduation/application/graduation_controller.dart';
import 'package:ahni_mobile/features/graduation/domain/graduation_overview.dart';
import 'package:flutter/material.dart';

class GraduationPage extends StatefulWidget {
  const GraduationPage({
    required this.controller,
    required this.onAuthenticationRequired,
    required this.bottomNavigationBar,
    super.key,
  });
  final GraduationController controller;
  final VoidCallback onAuthenticationRequired;
  final Widget bottomNavigationBar;
  @override
  State<GraduationPage> createState() => _GraduationPageState();
}

class _GraduationPageState extends State<GraduationPage> {
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
    if (widget.controller.status == GraduationStatus.unauthorized) {
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

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      key: const Key('graduation-progress-page'),
      appBar: AppBar(
        title: const Text('졸업 준비'),
        actions: [
          IconButton(
            onPressed: controller.status == GraduationStatus.loading
                ? null
                : controller.load,
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const WhitespaceWrappedText(
                  '등록한 성적과 학과 기준을 비교해 봐요. 학교의 최종 졸업 판정과는 다를 수 있어요.',
                ),
                const SizedBox(height: 24),
                if (controller.status == GraduationStatus.loading ||
                    controller.status == GraduationStatus.initial)
                  const Center(child: CircularProgressIndicator()),
                if (controller.status == GraduationStatus.missing ||
                    controller.status == GraduationStatus.failure) ...[
                  WhitespaceWrappedText(
                    controller.message ??
                        '아직 등록된 졸업 기준이 없어요. 학과와 입학연도를 확인해 주세요.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: controller.load,
                    child: const Text('다시 시도'),
                  ),
                ],
                for (final item in controller.overview)
                  _OverviewCard(item: item),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.item});
  final GraduationOverview item;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WhitespaceWrappedText(
            '${item.majorLabel} · ${item.departmentName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          WhitespaceWrappedText(
            '${item.admissionYear}년 입학 기준 · ${item.creditsMet ? '학점 기준 충족' : '학점 확인 필요'}',
          ),
          const SizedBox(height: 20),
          _CreditRow(label: '총 학점', credit: item.total),
          _CreditRow(label: '전공 학점', credit: item.department),
          _CreditRow(label: '교양 학점', credit: item.general),
          const Divider(height: 32),
          WhitespaceWrappedText(
            '기준 출처: ${item.sourceTitle}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (item.sourceUrl case final url?)
            SelectableText(url, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({required this.label, required this.credit});
  final String label;
  final CreditProgress credit;
  String _format(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${_format(credit.completed)} / ${_format(credit.required)}학점',
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: credit.required == 0
              ? 1
              : (credit.completed / credit.required).clamp(0, 1),
          semanticsLabel:
              '$label · ${credit.met ? "충족" : "${_format(credit.remaining)}학점 남음"}',
        ),
        const SizedBox(height: 8),
        Text(
          credit.met ? '충족' : '${_format(credit.remaining)}학점 남았어요',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
