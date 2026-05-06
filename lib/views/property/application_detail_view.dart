import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/message_templates.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/application_model.dart';
import '../../models/user_model.dart';
import '../../services/lawyer_service.dart';
import '../../services/token_service.dart';
import '../../viewmodels/property/owner_applications_viewmodel.dart';

class ApplicationDetailContent extends StatefulWidget {
  final String applicationId;
  final VoidCallback onBack;

  const ApplicationDetailContent({
    super.key,
    required this.applicationId,
    required this.onBack,
  });

  @override
  State<ApplicationDetailContent> createState() =>
      _ApplicationDetailContentState();
}

class _ApplicationDetailContentState extends State<ApplicationDetailContent>
    with SingleTickerProviderStateMixin {
  final OwnerApplicationsViewModel _vm = OwnerApplicationsViewModel();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  late TabController _tabController;

  static const _steps = [
    ApplicationStatus.pending,
    ApplicationStatus.underReview,
    ApplicationStatus.visitScheduled,
    ApplicationStatus.preApproved,
    ApplicationStatus.accepted,
    ApplicationStatus.negotiation,
    ApplicationStatus.awaitingLawyer,
    ApplicationStatus.contractDrafting,
  ];

  static const _stepLabels = [
    'Pending', 'Review', 'Visit', 'Pre-Approved',
    'Accepted', 'Negotiate', 'Lawyer', 'Contract',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _vm.addListener(_onChanged);
    _vm.selectApplication(widget.applicationId);
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    _currentUserId = await TokenService.getUserId();
    if (mounted) setState(() {});
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_vm.isLoadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }

    final app = _vm.selectedApp;
    if (app == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_vm.actionMessage ?? 'Application not found'),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.back),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: Text(l10n.back),
            ),
          ),
          const SizedBox(height: 8),

          // 1 — Progress stepper
          _buildProgressStepper(app, l10n, isDark),
          const SizedBox(height: 16),

          // 2 — Applicant summary
          _buildApplicantCard(app, l10n, isDark),
          const SizedBox(height: 16),

          // 3 — Next step / action card
          if (app.status.isActive) ...[
            _buildNextStepCard(app, l10n, isDark),
            const SizedBox(height: 16),
          ],

          // Rejection / cancellation reason
          if (app.rejectionReason != null && app.rejectionReason!.isNotEmpty) ...[
            _buildInfoCard(
              icon: Icons.block_rounded,
              title: l10n.rejectReason,
              isDark: isDark,
              child: Text(
                app.rejectionReason!,
                style: const TextStyle(color: AppColors.error, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4 — Conversation
          _buildConversationSection(l10n, isDark),
          const SizedBox(height: 16),

          // 5 — Status history
          if (app.statusHistory.isNotEmpty) ...[
            _buildHistoryTimeline(app, l10n, isDark),
            const SizedBox(height: 16),
          ],

          // Error feedback (success is shown inline via status update)
          if (_vm.actionMessage != null && _vm.actionMessage != 'STATUS_UPDATED')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _vm.actionMessage!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 1. Progress Stepper ────────────────────────────────────────

  Widget _buildProgressStepper(
      ApplicationModel app, AppLocalizations l10n, bool isDark) {
    final isTerminal = app.status == ApplicationStatus.rejected ||
        app.status == ApplicationStatus.cancelled;
    final currentIdx = _steps.indexOf(app.status);
    final statusColor = _statusColor(app.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_statusIcon(app.status), color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizedStatus(l10n, app.status),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      _statusDescription(app.status),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Step dots (hidden for terminal states)
          if (!isTerminal && currentIdx >= 0) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_steps.length, (i) {
                  final done = i < currentIdx;
                  final current = i == currentIdx;
                  final isLast = i == _steps.length - 1;
                  final dotColor = (done || current)
                      ? AppColors.primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.2));

                  return Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor,
                              border: current
                                  ? Border.all(
                                      color: AppColors.primary, width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: done
                                  ? const Icon(Icons.check,
                                      size: 13, color: Colors.white)
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: current
                                            ? Colors.white
                                            : (isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondary),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 52,
                            child: Text(
                              _stepLabels[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: current
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: current
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isLast)
                        Container(
                          width: 18,
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 20),
                          color: done
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.withValues(alpha: 0.2)),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 2. Applicant Card ──────────────────────────────────────────

  Widget _buildApplicantCard(
      ApplicationModel app, AppLocalizations l10n, bool isDark) {
    return _buildInfoCard(
      icon: Icons.person_outline_rounded,
      title: l10n.applicantInfo,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.person_outline, l10n.name, app.applicantName, isDark),
          if (app.applicantEmail != null)
            _infoRow(
                Icons.email_outlined, l10n.email, app.applicantEmail!, isDark),
          if (app.applicantPhone != null)
            _infoRow(Icons.phone_outlined, l10n.phoneNumber,
                app.applicantPhone!, isDark),
          _infoRow(Icons.location_on_outlined, l10n.address,
              app.propertyAddress, isDark),
          _infoRow(
              Icons.category_outlined,
              l10n.applicationType,
              app.type == ApplicationType.rent ? l10n.rent : l10n.buy,
              isDark),
          _infoRow(Icons.calendar_today_outlined, l10n.appliedOn,
              _formatDate(app.createdAt), isDark),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _verificationBadge(l10n.faceRegistered,
                  app.applicantFaceRegistered, Icons.face_rounded, isDark),
              _verificationBadge(l10n.electronicSignature,
                  app.applicantHasSignature, Icons.draw_rounded, isDark),
              _verificationBadge(l10n.identityVerified,
                  app.applicantIsVerified, Icons.badge_rounded, isDark),
            ],
          ),
          if (app.message != null && app.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '"${app.message!}"',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 3. Next Step Card ──────────────────────────────────────────

  Widget _buildNextStepCard(
      ApplicationModel app, AppLocalizations l10n, bool isDark) {
    return _buildInfoCard(
      icon: Icons.arrow_circle_right_outlined,
      title: 'Next Step',
      isDark: isDark,
      child: _buildNextStepBody(app, l10n, isDark),
    );
  }

  Widget _buildNextStepBody(
      ApplicationModel app, AppLocalizations l10n, bool isDark) {
    switch (app.status) {
      case ApplicationStatus.pending:
        return _stepPending(l10n, isDark);
      case ApplicationStatus.underReview:
        return _stepUnderReview(l10n, isDark, _isMeetingAgreed());
      case ApplicationStatus.visitScheduled:
        return _stepVisitScheduled(app, l10n, isDark);
      case ApplicationStatus.preApproved:
        return _stepPreApproved(l10n, isDark);
      case ApplicationStatus.accepted:
        return _stepAccepted(app, l10n, isDark);
      case ApplicationStatus.negotiation:
        return _stepNegotiation(app, l10n, isDark);
      case ApplicationStatus.awaitingLawyer:
        return _stepWaiting(
          Icons.hourglass_top_rounded,
          Colors.indigo,
          'Awaiting Lawyer',
          'The lawyer has been notified and will begin drafting the contract.',
          isDark,
        );
      case ApplicationStatus.contractDrafting:
        return _stepWaiting(
          Icons.description_rounded,
          AppColors.primary,
          'Contract in Progress',
          'The lawyer is preparing the rental contract. You will be notified when it is ready.',
          isDark,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _stepPending(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hint(
          icon: Icons.rate_review_rounded,
          color: AppColors.info,
          text: 'Review the applicant\'s profile and verification status, then decide whether to proceed.',
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _primaryBtn(
                icon: Icons.rate_review_rounded,
                label: 'Start Review',
                color: AppColors.info,
                onTap: () => _vm.markUnderReview(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _rejectBtn(l10n, isDark)),
          ],
        ),
      ],
    );
  }

  Widget _stepUnderReview(
      AppLocalizations l10n, bool isDark, bool meetingAgreed) {
    if (meetingAgreed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hint(
            icon: Icons.handshake_rounded,
            color: Colors.deepPurple,
            text: 'The applicant agreed to a visit. Pick a date and time to confirm.',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _primaryBtn(
              icon: Icons.calendar_month_rounded,
              label: l10n.scheduleVisit,
              color: Colors.deepPurple,
              onTap: () => _showVisitDialog(l10n, isDark),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _outlineBtn(
                  icon: Icons.thumb_up_rounded,
                  label: l10n.preApprove,
                  color: Colors.teal,
                  onTap: () => _showNoteDialog(l10n, isDark, l10n.preApprove,
                      (note) => _vm.preApprove(note: note)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _rejectBtn(l10n, isDark)),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hint(
          icon: Icons.rate_review_rounded,
          color: AppColors.info,
          text: 'Use the conversation to discuss terms. Schedule a visit or pre-approve when ready.',
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _primaryBtn(
                icon: Icons.event_rounded,
                label: l10n.scheduleVisit,
                color: Colors.deepPurple,
                onTap: () => _showVisitDialog(l10n, isDark),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _outlineBtn(
                icon: Icons.thumb_up_rounded,
                label: l10n.preApprove,
                color: Colors.teal,
                onTap: () => _showNoteDialog(l10n, isDark, l10n.preApprove,
                    (note) => _vm.preApprove(note: note)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: _rejectBtn(l10n, isDark)),
      ],
    );
  }

  Widget _stepVisitScheduled(
      ApplicationModel app, AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (app.visitDate != null) ...[
          _buildVisitDateCard(app.visitDate!, isDark),
          const SizedBox(height: 14),
        ],
        _hint(
          icon: Icons.thumb_up_outlined,
          color: Colors.teal,
          text: 'After the visit, pre-approve this applicant to continue the process.',
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _primaryBtn(
                icon: Icons.thumb_up_rounded,
                label: l10n.preApprove,
                color: Colors.teal,
                onTap: () => _showNoteDialog(l10n, isDark, l10n.preApprove,
                    (note) => _vm.preApprove(note: note)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _rejectBtn(l10n, isDark)),
          ],
        ),
      ],
    );
  }

  Widget _stepPreApproved(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hint(
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          text: 'Officially accept this application to begin setting up deal terms.',
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _primaryBtn(
                icon: Icons.check_circle_rounded,
                label: l10n.acceptApplication,
                color: AppColors.success,
                onTap: () => _showNoteDialog(
                    l10n, isDark, l10n.acceptApplication,
                    (note) => _vm.accept(note: note)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _rejectBtn(l10n, isDark)),
          ],
        ),
      ],
    );
  }

  Widget _stepAccepted(
      ApplicationModel app, AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hint(
          icon: Icons.attach_money_rounded,
          color: Colors.orange,
          text: 'Set the agreed monthly rent. This moves the application into negotiation.',
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: _primaryBtn(
            icon: Icons.attach_money_rounded,
            label: l10n.setAmount,
            color: Colors.orange,
            onTap: () => _showSetAmountDialog(l10n, isDark, app),
          ),
        ),
      ],
    );
  }

  Widget _stepNegotiation(
      ApplicationModel app, AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Deal amount pill
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.attach_money_rounded,
                  size: 20, color: Colors.orange),
              const SizedBox(width: 10),
              Text(
                '${l10n.dealAmount}: ${app.dealAmount!.toStringAsFixed(2)} ${l10n.currency}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _hint(
          icon: Icons.gavel_rounded,
          color: AppColors.primary,
          text: 'Select a verified lawyer to draft the rental contract.',
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: _primaryBtn(
            icon: Icons.gavel_rounded,
            label: l10n.selectLawyer,
            color: AppColors.primary,
            onTap: () => _showSelectLawyerDialog(l10n, isDark),
          ),
        ),
        if (app.assignedLawyerName != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                '${l10n.assignLawyer}: ${app.assignedLawyerName}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _stepWaiting(IconData icon, Color color, String title,
      String description, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: color)),
              const SizedBox(height: 4),
              Text(description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Visit date card (reused in Next Step + Conversation) ───────

  Widget _buildVisitDateCard(DateTime visitDate, bool isDark) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final time =
        '${visitDate.hour.toString().padLeft(2, '0')}:${visitDate.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  visitDate.day.toString().padLeft(2, '0'),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(months[visitDate.month - 1],
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Visit Confirmed',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepPurple)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 13,
                        color: Colors.deepPurple.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      '$time  ·  ${visitDate.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.event_available_rounded,
              color: Colors.deepPurple.withValues(alpha: 0.4), size: 26),
        ],
      ),
    );
  }

  // ─── 4. Conversation ────────────────────────────────────────────

  Widget _buildConversationSection(AppLocalizations l10n, bool isDark) {
    final app = _vm.selectedApp;

    return _buildInfoCard(
      icon: Icons.chat_bubble_outline_rounded,
      title: l10n.conversation,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_vm.messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.noMessagesYet,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vm.messages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) =>
                  _buildMessageBubble(_vm.messages[i], isDark),
            ),

          if (app != null &&
              app.status == ApplicationStatus.visitScheduled &&
              app.visitDate != null) ...[
            const SizedBox(height: 12),
            _buildVisitDateCard(app.visitDate!, isDark),
          ],

          const SizedBox(height: 12),
          _buildMessageInputPanel(l10n, isDark),
        ],
      ),
    );
  }

  bool _isMeetingAgreed() {
    const positiveIds = {
      'meeting_ans_yes',
      'meeting_ans_contact',
      'meeting_q2_ans_yes',
      'meeting_q2_ans_contact',
    };
    for (final msg in _vm.messages) {
      final answeredQId = MessageTemplates.getAnsweredQuestionId(msg.content);
      if (answeredQId == null || !answeredQId.startsWith('meeting_')) continue;
      final answerId = MessageTemplates.getAnswerTemplateId(msg.content);
      if (answerId != null && positiveIds.contains(answerId)) return true;
    }
    return false;
  }

  Widget _buildMessageInputPanel(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: MessageCategory.price.displayName),
            Tab(text: MessageCategory.contract.displayName),
            Tab(text: MessageCategory.location.displayName),
            Tab(text: MessageCategory.meeting.displayName),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryPanel(MessageCategory.price, l10n, isDark),
              _buildCategoryPanel(MessageCategory.contract, l10n, isDark),
              _buildCategoryPanel(MessageCategory.location, l10n, isDark),
              _buildCategoryPanel(MessageCategory.meeting, l10n, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPanel(
      MessageCategory category, AppLocalizations l10n, bool isDark) {
    final questions = MessageTemplates.getQuestionsForCategory(category);
    final answerable = _getAnswerableQuestions();
    final categoryAnswerable = answerable.where((qid) {
      try {
        return MessageTemplates.all.firstWhere((t) => t.id == qid).category ==
            category;
      } catch (_) {
        return false;
      }
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (categoryAnswerable.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Reply to a Question',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: categoryAnswerable
                    .map((qid) =>
                        _buildAnswerButtons(qid, l10n, isDark))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Ask a Question',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildQuestionsList(questions, l10n),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildQuestionsList(
      List<ChatMessageTemplate> questions, AppLocalizations l10n) {
    final asked = _getAskedQuestionIds();
    final widgets = <Widget>[];
    for (int i = 0; i < questions.length; i++) {
      final t = questions[i];
      final isAsked = asked.contains(t.id);
      widgets.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isAsked
                ? null
                : () async {
                    await _vm.sendMessage(t.getEncodedContent(l10n));
                    if (mounted) setState(() {});
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAsked ? Colors.grey : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(t.getLocalizedContent(l10n),
                textAlign: TextAlign.center,
                maxLines: null,
                style: const TextStyle(fontSize: 13)),
          ),
        ),
      );
      if (i < questions.length - 1) widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }

  Widget _buildAnswerButtons(
      String questionId, AppLocalizations l10n, bool isDark) {
    final answers = MessageTemplates.getAnswersForQuestion(questionId);
    final isAnswered = _getAnsweredQuestionIds().contains(questionId);

    if (isAnswered) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Chip(
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 16),
              const SizedBox(width: 6),
              Text('Answered',
                  style: TextStyle(color: AppColors.success, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < answers.length; i++) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _vm.isSendingMessage
                    ? null
                    : () async {
                        await _vm
                            .sendMessage(answers[i].getEncodedContent(l10n));
                        if (mounted) setState(() {});
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(answers[i].getLocalizedContent(l10n),
                    textAlign: TextAlign.center,
                    maxLines: null,
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
            if (i < answers.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Set<String> _getAskedQuestionIds() {
    final ids = <String>{};
    for (final msg in _vm.messages) {
      final qId = MessageTemplates.getQuestionId(msg.content);
      if (qId != null) ids.add(qId);
    }
    return ids;
  }

  Set<String> _getAnsweredQuestionIds() {
    final ids = <String>{};
    for (final msg in _vm.messages) {
      final qId = MessageTemplates.getAnsweredQuestionId(msg.content);
      if (qId != null) ids.add(qId);
    }
    return ids;
  }

  List<String> _getAnswerableQuestions() {
    final theirQIds = <String>{};
    final answeredIds = _getAnsweredQuestionIds();
    for (final msg in _vm.messages) {
      if (msg.senderId != _currentUserId) {
        final qId = MessageTemplates.getQuestionId(msg.content);
        if (qId != null) theirQIds.add(qId);
      }
    }
    return theirQIds.where((id) => !answeredIds.contains(id)).toList();
  }

  Widget _buildMessageBubble(ApplicationMessage msg, bool isDark) {
    final isMe = msg.senderId == _currentUserId;
    final text = MessageTemplates.extractContent(msg.content);
    return Align(
      alignment:
          isMe ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.1)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(msg.senderName,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ),
            Text(text,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(_formatTime(msg.createdAt),
                style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ─── 5. Status History Timeline ─────────────────────────────────

  Widget _buildHistoryTimeline(
      ApplicationModel app, AppLocalizations l10n, bool isDark) {
    return _buildInfoCard(
      icon: Icons.history_rounded,
      title: l10n.statusHistory,
      isDark: isDark,
      child: Column(
        children: app.statusHistory.asMap().entries.map((e) {
          final isLast = e.key == app.statusHistory.length - 1;
          return _AnimatedTimelineEntry(
            index: e.key,
            child: _buildTimelineEntry(e.value, l10n, isDark, isLast: isLast),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineEntry(ApplicationStatusEntry entry,
      AppLocalizations l10n, bool isDark,
      {required bool isLast}) {
    final color = _statusColor(entry.toStatus);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.4),
                            Colors.grey.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_localizedStatus(l10n, entry.fromStatus)} → ${_localizedStatus(l10n, entry.toStatus)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _formatDateTime(entry.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (entry.note != null && entry.note!.isNotEmpty)
                    Text(
                      entry.note!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared card shell ──────────────────────────────────────────

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  // ─── Small helpers ──────────────────────────────────────────────

  Widget _hint(
      {required IconData icon,
      required Color color,
      required String text,
      required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _primaryBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: _vm.isUpdatingStatus ? null : onTap,
      icon: _vm.isUpdatingStatus
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _outlineBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: _vm.isUpdatingStatus ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.6)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _rejectBtn(AppLocalizations l10n, bool isDark) {
    return OutlinedButton.icon(
      onPressed:
          _vm.isUpdatingStatus ? null : () => _showRejectDialog(l10n, isDark),
      icon: const Icon(Icons.cancel_rounded, size: 18),
      label: Text(l10n.rejectApplication),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary)),
          Flexible(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _verificationBadge(
      String label, bool verified, IconData icon, bool isDark) {
    final color =
        verified ? AppColors.success : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color)),
          const SizedBox(width: 4),
          Icon(
              verified
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              size: 14,
              color: color),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────

  Color _statusColor(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pending:
        return AppColors.warning;
      case ApplicationStatus.underReview:
        return AppColors.info;
      case ApplicationStatus.visitScheduled:
        return Colors.deepPurple;
      case ApplicationStatus.preApproved:
        return Colors.teal;
      case ApplicationStatus.accepted:
        return AppColors.success;
      case ApplicationStatus.negotiation:
        return Colors.orange;
      case ApplicationStatus.awaitingLawyer:
        return Colors.indigo;
      case ApplicationStatus.contractDrafting:
        return AppColors.primary;
      case ApplicationStatus.rejected:
        return AppColors.error;
      case ApplicationStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pending:
        return Icons.hourglass_top_rounded;
      case ApplicationStatus.underReview:
        return Icons.rate_review_rounded;
      case ApplicationStatus.visitScheduled:
        return Icons.event_rounded;
      case ApplicationStatus.preApproved:
        return Icons.thumb_up_rounded;
      case ApplicationStatus.accepted:
        return Icons.check_circle_rounded;
      case ApplicationStatus.negotiation:
        return Icons.attach_money_rounded;
      case ApplicationStatus.awaitingLawyer:
        return Icons.gavel_rounded;
      case ApplicationStatus.contractDrafting:
        return Icons.description_rounded;
      case ApplicationStatus.rejected:
        return Icons.cancel_rounded;
      case ApplicationStatus.cancelled:
        return Icons.block_rounded;
    }
  }

  String _localizedStatus(AppLocalizations l10n, ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pending:
        return l10n.applicationStatusPending;
      case ApplicationStatus.underReview:
        return l10n.applicationStatusUnderReview;
      case ApplicationStatus.visitScheduled:
        return l10n.applicationStatusVisitScheduled;
      case ApplicationStatus.preApproved:
        return l10n.applicationStatusPreApproved;
      case ApplicationStatus.accepted:
        return l10n.applicationStatusAccepted;
      case ApplicationStatus.negotiation:
        return l10n.applicationStatusNegotiation;
      case ApplicationStatus.awaitingLawyer:
        return l10n.applicationStatusAwaitingLawyer;
      case ApplicationStatus.contractDrafting:
        return l10n.applicationStatusContractDrafting;
      case ApplicationStatus.rejected:
        return l10n.applicationStatusRejected;
      case ApplicationStatus.cancelled:
        return l10n.applicationStatusCancelled;
    }
  }

  String _statusDescription(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pending:
        return 'Waiting for owner review';
      case ApplicationStatus.underReview:
        return 'Owner is reviewing this application';
      case ApplicationStatus.visitScheduled:
        return 'A property visit has been scheduled';
      case ApplicationStatus.preApproved:
        return 'Pre-approved — pending final acceptance';
      case ApplicationStatus.accepted:
        return 'Accepted — set the agreed rent amount';
      case ApplicationStatus.negotiation:
        return 'Amount set — assign a lawyer to draft the contract';
      case ApplicationStatus.awaitingLawyer:
        return 'Waiting for the assigned lawyer to start';
      case ApplicationStatus.contractDrafting:
        return 'Lawyer is preparing the contract';
      case ApplicationStatus.rejected:
        return 'This application was rejected';
      case ApplicationStatus.cancelled:
        return 'Applicant cancelled this application';
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime d) => '${_formatDate(d)} ${_formatTime(d)}';

  // ─── Dialogs ─────────────────────────────────────────────────────

  void _showNoteDialog(AppLocalizations l10n, bool isDark, String title,
      void Function(String? note) onConfirm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.addNote,
            hintText: l10n.noteHint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm(controller.text.trim().isEmpty
                  ? null
                  : controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.confirmAction),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(AppLocalizations l10n, bool isDark) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.rejectApplication),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.rejectReason,
            hintText: l10n.rejectReasonHint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              _vm.reject(reason: controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.rejectApplication),
          ),
        ],
      ),
    );
  }

  void _showVisitDialog(AppLocalizations l10n, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 365));
    DateTime selectedDate = today.add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final noteController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) {
          final bg = isDark ? AppColors.surfaceDark : Colors.white;
          final tp =
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
          final ts = isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondary;

          return Dialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.06),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_month_rounded,
                              color: Colors.deepPurple, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(l10n.scheduleVisit,
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: tp)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                          color: ts,
                        ),
                      ],
                    ),
                  ),
                  // Calendar
                  Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: Theme.of(ctx)
                          .colorScheme
                          .copyWith(primary: Colors.deepPurple),
                    ),
                    child: CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: today,
                      lastDate: maxDate,
                      onDateChanged: (d) =>
                          setDs(() => selectedDate = d),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Time picker
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            final t = await showTimePicker(
                                context: ctx,
                                initialTime: selectedTime);
                            if (t != null) setDs(() => selectedTime = t);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.grey.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 18, color: Colors.deepPurple),
                                const SizedBox(width: 10),
                                Text('Time: ${selectedTime.format(ctx)}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: tp)),
                                const Spacer(),
                                Icon(Icons.edit_rounded,
                                    size: 16, color: ts),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Note field
                        TextField(
                          controller: noteController,
                          maxLines: 2,
                          style: TextStyle(fontSize: 13, color: tp),
                          decoration: InputDecoration(
                            labelText: l10n.addNote,
                            hintText: l10n.noteHint,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Confirm
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            final dt = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                            _vm.scheduleVisit(
                              visitDate: dt.toIso8601String(),
                              note: noteController.text.trim().isEmpty
                                  ? null
                                  : noteController.text.trim(),
                            );
                          },
                          icon: const Icon(Icons.event_available_rounded,
                              size: 18),
                          label: Text(l10n.scheduleVisit),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSetAmountDialog(
      AppLocalizations l10n, bool isDark, ApplicationModel app) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.setAmount),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.enterAmount,
              suffixText: l10n.currency,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.amountRequired;
              final p = double.tryParse(v.trim());
              if (p == null || p <= 0) return l10n.amountInvalid;
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              _vm.setDealAmount(double.parse(controller.text.trim()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.confirmAction),
          ),
        ],
      ),
    );
  }

  void _showSelectLawyerDialog(AppLocalizations l10n, bool isDark) {
    final lawyerService = LawyerService();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.selectLawyer),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: FutureBuilder<List<UserModel>>(
            future: lawyerService.getAllLawyers(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || (snapshot.data?.isEmpty ?? true)) {
                return Center(child: Text(l10n.noVerifiedLawyers));
              }
              final lawyers = snapshot.data!;
              return ListView.separated(
                shrinkWrap: true,
                itemCount: lawyers.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final lawyer = lawyers[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        lawyer.fullName.isNotEmpty
                            ? lawyer.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                    ),
                    title: Text(lawyer.fullName),
                    subtitle: Text(lawyer.email),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _vm.assignLawyer(lawyer.id);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
        ],
      ),
    );
  }
}

// ─── Staggered timeline animation wrapper ──────────────────────────────────

class _AnimatedTimelineEntry extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedTimelineEntry({required this.index, required this.child});

  @override
  State<_AnimatedTimelineEntry> createState() => _AnimatedTimelineEntryState();
}

class _AnimatedTimelineEntryState extends State<_AnimatedTimelineEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    Future.delayed(Duration(milliseconds: widget.index * 90), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final v = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic).value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - v)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
