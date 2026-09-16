import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/grade/application/grade_list_controller.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:flutter/material.dart';

class GradeListPage extends StatefulWidget {
  const GradeListPage({
    required this.controller,
    required this.onAuthenticationRequired,
    this.bottomNavigationBar,
    super.key,
  });

  final GradeListController controller;
  final VoidCallback onAuthenticationRequired;
  final Widget? bottomNavigationBar;

  @override
  State<GradeListPage> createState() => _GradeListPageState();
}

class _GradeListPageState extends State<GradeListPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.load();
    });
  }

  @override
  void didUpdateWidget(covariant GradeListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_refresh);
    widget.controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.load();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('grade-list-page'),
      appBar: AppBar(titleSpacing: 24, title: const Text('성적')),
      bottomNavigationBar: widget.bottomNavigationBar,
      body: SafeArea(
        top: false,
        child: switch (widget.controller.state) {
          GradeListInitial() || GradeListLoading() => const _LoadingView(),
          GradeListReady state => _GradeList(grades: state.grades),
          GradeListEmpty() => const _EmptyView(),
          GradeListFailure state => _FailureView(
            message: state.message,
            onRetry: widget.controller.retry,
          ),
          GradeListAuthenticationRequired() => _AuthenticationRequiredView(
            onReturnToLogin: widget.onAuthenticationRequired,
          ),
        },
      ),
    );
  }
}

class _GradeList extends StatelessWidget {
  const _GradeList({required this.grades});

  final List<GradeRecord> grades;

  @override
  Widget build(BuildContext context) {
    final groups = _groupGrades(grades);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WhitespaceWrappedText(
                '학기별 성적을 확인하세요',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              WhitespaceWrappedText(
                '입력한 성적을 최신 학기부터 모아 보여드려요.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              for (var index = 0; index < groups.length; index++) ...[
                _GradeTermSection(group: groups[index]),
                if (index != groups.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeTermSection extends StatelessWidget {
  const _GradeTermSection({required this.group});

  final _GradeGroup group;

  @override
  Widget build(BuildContext context) {
    final title = '${group.academicYear}년 ${group.term.label}';
    return Semantics(
      label: '$title 성적',
      container: true,
      child: Container(
        key: Key('grade-term-${group.academicYear}-${group.term.apiName}'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            for (var index = 0; index < group.grades.length; index++) ...[
              _GradeRow(grade: group.grades[index]),
              if (index != group.grades.length - 1) const Divider(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.grade});

  final GradeRecord grade;

  @override
  Widget build(BuildContext context) {
    final metadata = [
      grade.course.code,
      '${_formatNumber(grade.credit)}학점',
      if (grade.retake) '재수강',
    ].join(' · ');
    final semantics = [
      grade.course.name,
      metadata,
      '성적 ${grade.gradeLabel}',
      if (grade.gradePoint case final point?) '평점 ${_formatNumber(point)}',
    ].join(', ');

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Row(
        key: Key('grade-row-${grade.entityId}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.course.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  metadata,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                grade.gradeLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (grade.gradePoint case final point?) ...[
                const SizedBox(height: 2),
                Text(
                  '${_formatNumber(point)}점',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          WhitespaceWrappedText('성적을 불러오는 중이에요…'),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.school_outlined,
      title: '아직 등록된 성적이 없어요',
      message: '성적을 등록하면 학기별 이력을 여기서 확인할 수 있어요.',
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.cloud_off_outlined,
      title: '성적을 불러오지 못했어요',
      message: message,
      action: FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
    );
  }
}

class _AuthenticationRequiredView extends StatelessWidget {
  const _AuthenticationRequiredView({required this.onReturnToLogin});

  final VoidCallback onReturnToLogin;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.lock_outline_rounded,
      title: '다시 로그인이 필요해요',
      message: '로그인이 만료되었습니다. 다시 로그인해 주세요.',
      action: FilledButton(
        onPressed: onReturnToLogin,
        child: const Text('로그인으로 돌아가기'),
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, minHeight: 360),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  WhitespaceWrappedText(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  WhitespaceWrappedText(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (action case final value?) ...[
                    const SizedBox(height: 24),
                    value,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeGroup {
  const _GradeGroup({
    required this.academicYear,
    required this.term,
    required this.grades,
  });

  final int academicYear;
  final AcademicTerm term;
  final List<GradeRecord> grades;
}

List<_GradeGroup> _groupGrades(List<GradeRecord> grades) {
  final grouped = <(int, AcademicTerm), List<GradeRecord>>{};
  for (final grade in grades) {
    grouped.putIfAbsent((grade.academicYear, grade.term), () => []).add(grade);
  }
  return grouped.entries
      .map(
        (entry) => _GradeGroup(
          academicYear: entry.key.$1,
          term: entry.key.$2,
          grades: entry.value,
        ),
      )
      .toList(growable: false);
}

String _formatNumber(double value) {
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}
