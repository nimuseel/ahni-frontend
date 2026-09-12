import 'package:ahni_mobile/core/network/student_api.dart';
import 'package:ahni_mobile/core/presentation/whitespace_wrapped_text.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.controller, super.key});

  final OnboardingController controller;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.initialize();
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
    return switch (widget.controller.state) {
      AuthenticationRequired state => _AuthenticationView(
        controller: widget.controller,
        state: state,
      ),
      ProfileLoading() => const _LoadingView(),
      RegistrationRequired state => _RegistrationView(
        controller: widget.controller,
        state: state,
      ),
      ProfileReady state => _ProfileView(
        controller: widget.controller,
        profile: state.profile,
      ),
      RetryableFailure state => _RetryView(
        message: state.message,
        onRetry: widget.controller.retry,
      ),
    };
  }
}

class _AuthenticationView extends StatefulWidget {
  const _AuthenticationView({required this.controller, required this.state});

  final OnboardingController controller;
  final AuthenticationRequired state;

  @override
  State<_AuthenticationView> createState() => _AuthenticationViewState();
}

class _AuthenticationViewState extends State<_AuthenticationView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _formKey = GlobalKey<FormState>();
  var _isSignUp = false;
  var _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim().toLowerCase() ?? '';
    if (!RegExp(r'^[^@\s]+@inha\.edu$').hasMatch(email)) {
      return '인하대학교 이메일(@inha.edu)을 입력해 주세요.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) return '비밀번호를 6자 이상 입력해 주세요.';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSignUp) {
      await widget.controller.signUp(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      await widget.controller.signIn(
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  void _selectMode(bool isSignUp) {
    if (_isSignUp == isSignUp) return;
    setState(() {
      _isSignUp = isSignUp;
      _emailController.clear();
      _passwordController.clear();
      _formKey = GlobalKey<FormState>();
    });
    widget.controller.clearAuthenticationFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.state.isSubmitting;
    final description = _isSignUp
        ? '학교 이메일로 가입한 뒤 학생 정보를 등록할 수 있어요.'
        : '학교 이메일로 로그인하면 내 학사 정보를 편하게 확인할 수 있어요.';
    return _PageScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WhitespaceWrappedText(
              '학사 준비, 함께 이어가요',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            WhitespaceWrappedText(
              description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _SectionCard(
              key: const Key('auth-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AuthModeSwitch(
                    isSignUp: _isSignUp,
                    isEnabled: !isSubmitting,
                    onChanged: _selectMode,
                  ),
                  const SizedBox(height: 24),
                  if (widget.state.message case final message?) ...[
                    _StatusMessage(message: message),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const Key('auth-email'),
                    controller: _emailController,
                    enabled: !isSubmitting,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    validator: _validateEmail,
                    decoration: const InputDecoration(
                      labelText: '학교 이메일',
                      hintText: 'student@inha.edu',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('auth-password'),
                    controller: _passwordController,
                    enabled: !isSubmitting,
                    obscureText: _obscurePassword,
                    autofillHints: _isSignUp
                        ? const [AutofillHints.newPassword]
                        : const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: isSubmitting ? null : (_) => _submit(),
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? '비밀번호 표시' : '비밀번호 숨기기',
                        onPressed: isSubmitting
                            ? null
                            : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : _submit,
                      child: _ButtonLabel(
                        isLoading: isSubmitting,
                        label: _isSignUp ? '계정 만들기' : '로그인',
                      ),
                    ),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    WhitespaceWrappedText(
                      '가입하면 학교 이메일로 인증 링크를 보내드려요.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationView extends StatefulWidget {
  const _RegistrationView({required this.controller, required this.state});

  final OnboardingController controller;
  final RegistrationRequired state;

  @override
  State<_RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<_RegistrationView> {
  final _formKey = GlobalKey<FormState>();
  final _admissionYearController = TextEditingController();
  final _nicknameController = TextEditingController();
  String? _departmentId;
  String _enrollmentStatus = 'ENROLLED';

  @override
  void dispose() {
    _admissionYearController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  String? _validateAdmissionYear(String? value) {
    final year = int.tryParse(value ?? '');
    if (year == null || year < 2000 || year > DateTime.now().year) {
      return '2000년부터 현재 연도 사이로 입력해 주세요.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.registerProfile(
      StudentRegistration(
        primaryDepartmentEntityId: _departmentId!,
        admissionYear: int.parse(_admissionYearController.text),
        enrollmentStatus: _enrollmentStatus,
        nickname: _nicknameController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.state.isSubmitting;
    return _PageScaffold(
      title: '학생 정보',
      action: IconButton(
        onPressed: isSubmitting ? null : widget.controller.signOut,
        tooltip: '로그아웃',
        icon: const Icon(Icons.logout_rounded, size: 20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WhitespaceWrappedText(
              '학생 정보를 알려주세요',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            WhitespaceWrappedText(
              '학과, 입학연도와 학적 상태는 맞춤 학사 안내에 사용해요.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _SectionCard(
              key: const Key('registration-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.state.message case final message?) ...[
                    _StatusMessage(message: message, isError: true),
                    const SizedBox(height: 16),
                  ],
                  Text('기본 정보', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const Key('department-field'),
                    initialValue: _departmentId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '주전공 학과'),
                    items: [
                      for (final department in widget.state.departments)
                        DropdownMenuItem(
                          value: department.entityId,
                          child: Text(
                            department.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: isSubmitting
                        ? null
                        : (value) => setState(() => _departmentId = value),
                    validator: (value) =>
                        value == null ? '주전공 학과를 선택해 주세요.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('admission-year'),
                    controller: _admissionYearController,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validateAdmissionYear,
                    decoration: const InputDecoration(
                      labelText: '입학연도',
                      hintText: '2024',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('nickname'),
                    controller: _nicknameController,
                    enabled: !isSubmitting,
                    maxLength: 100,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: isSubmitting ? null : (_) => _submit(),
                    decoration: const InputDecoration(labelText: '닉네임 (선택)'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '현재 학적 상태',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _ValueSegmentedControl(
                    key: const Key('enrollment-status-segments'),
                    value: _enrollmentStatus,
                    isEnabled: !isSubmitting,
                    options: const {'ENROLLED': '재학', 'LEAVE': '휴학'},
                    onChanged: (value) =>
                        setState(() => _enrollmentStatus = value),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : _submit,
                      child: _ButtonLabel(
                        isLoading: isSubmitting,
                        label: '학생 정보 등록',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.controller, required this.profile});

  final OnboardingController controller;
  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    final displayName = profile.nickname?.trim().isNotEmpty == true
        ? profile.nickname!.trim()
        : profile.email.split('@').first;
    final enrollmentLabel = switch (profile.enrollmentStatus) {
      'ENROLLED' => '재학',
      'LEAVE' => '휴학',
      'GRADUATED' => '졸업',
      'WITHDRAWN' => '제적',
      _ => '확인 필요',
    };
    return _PageScaffold(
      maxWidth: 560,
      title: '내 정보',
      action: IconButton(
        onPressed: controller.signOut,
        tooltip: '로그아웃',
        icon: const Icon(Icons.logout_rounded, size: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: const Key('profile-summary'),
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Text(
                    displayName.characters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.primaryDepartment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(label: enrollmentLabel),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            key: const Key('student-information-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('학생 정보', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                _ProfileField(label: '학교 이메일', value: profile.email),
                const Divider(height: 32),
                _ProfileField(
                  label: '입학연도',
                  value: '${profile.admissionYear}년',
                ),
                const Divider(height: 32),
                _ProfileField(label: '학적 상태', value: enrollmentLabel),
                const Divider(height: 32),
                _ProfileField(
                  label: '계정 상태',
                  value: profile.accountStatus == 'ACTIVE' ? '활성' : '이용 제한',
                ),
              ],
            ),
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
    return _PageScaffold(
      fillViewport: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            WhitespaceWrappedText(
              '학생 정보를 불러오는 중이에요…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryView extends StatelessWidget {
  const _RetryView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      fillViewport: true,
      child: Center(
        child: _SectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              WhitespaceWrappedText(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({
    required this.child,
    this.action,
    this.title = 'AHNI',
    this.maxWidth = 400,
    this.fillViewport = false,
  });

  final Widget child;
  final Widget? action;
  final String title;
  final double maxWidth;
  final bool fillViewport;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Text(title),
        actions: action == null
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: action,
                ),
              ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = fillViewport && constraints.maxHeight > 56
                ? constraints.maxHeight - 56
                : 0.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    minHeight: minHeight,
                  ),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}

class _AuthModeSwitch extends StatelessWidget {
  const _AuthModeSwitch({
    required this.isSignUp,
    required this.isEnabled,
    required this.onChanged,
  });

  final bool isSignUp;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ValueSegmentedControl(
      key: const Key('auth-mode-switch'),
      value: isSignUp ? 'sign-up' : 'sign-in',
      isEnabled: isEnabled,
      options: const {'sign-in': '로그인', 'sign-up': '가입'},
      optionKeys: const {
        'sign-in': Key('auth-sign-in-segment'),
        'sign-up': Key('auth-sign-up-segment'),
      },
      onChanged: (value) => onChanged(value == 'sign-up'),
    );
  }
}

class _ValueSegmentedControl extends StatelessWidget {
  const _ValueSegmentedControl({
    required this.value,
    required this.isEnabled,
    required this.options,
    required this.onChanged,
    this.optionKeys = const {},
    super.key,
  });

  final String value;
  final bool isEnabled;
  final Map<String, String> options;
  final Map<String, Key> optionKeys;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final option in options.entries)
            Expanded(
              child: Semantics(
                key: optionKeys[option.key],
                button: true,
                selected: value == option.key,
                enabled: isEnabled,
                child: Material(
                  color: value == option.key
                      ? colorScheme.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: isEnabled ? () => onChanged(option.key) : null,
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Center(
                        child: Text(
                          option.value,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: value == option.key
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isError ? colorScheme.errorContainer : const Color(0xFFEAF2FC),
          borderRadius: BorderRadius.circular(6),
        ),
        child: WhitespaceWrappedText(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isError
                ? colorScheme.onErrorContainer
                : const Color(0xFF18202A),
          ),
        ),
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.isLoading, required this.label});

  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
