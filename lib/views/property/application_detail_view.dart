import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/application_model.dart';
import '../../models/user_model.dart';
import '../../services/lawyer_service.dart';
import '../../services/token_service.dart';
import '../../viewmodels/property/owner_applications_viewmodel.dart';

/// Full application detail view with applicant info, status actions,
/// conversation, and status history. Used inside MainShell.
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

class _ApplicationDetailContentState extends State<ApplicationDetailContent> {
  final OwnerApplicationsViewModel _vm = OwnerApplicationsViewModel();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
    _vm.selectApplication(widget.applicationId);
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    _currentUserId = await TokenService.getUserId();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
          // Back button
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: Text(l10n.back),
            ),
          ),
          const SizedBox(height: 8),

          // ── Status banner ──
          _buildStatusBanner(app, l10n, isDark),
          const SizedBox(height: 16),

          // ── Property info summary ──
          _buildInfoCard(
            icon: Icons.apartment_rounded,
            title: l10n.viewProperty,
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.location_on_outlined, l10n.address,
                    app.propertyAddress, isDark),
                _infoRow(
                    Icons.category_outlined,
                    l10n.applicationType,
                    app.type == ApplicationType.rent ? l10n.rent : l10n.buy,
                    isDark),
                _infoRow(Icons.calendar_today_outlined, l10n.appliedOn,
                    _formatDate(app.createdAt), isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Applicant info ──
          _buildInfoCard(
            icon: Icons.person_outline_rounded,
            title: l10n.applicantInfo,
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.person_outline, l10n.name, app.applicantName,
                    isDark),
                if (app.applicantEmail != null)
                  _infoRow(Icons.email_outlined, l10n.email,
                      app.applicantEmail!, isDark),
                if (app.applicantPhone != null)
                  _infoRow(Icons.phone_outlined, l10n.phoneNumber,
                      app.applicantPhone!, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Applicant verification badges ──
          _buildInfoCard(
            icon: Icons.verified_user_outlined,
            title: l10n.applicantVerification,
            isDark: isDark,
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _verificationBadge(
                  l10n.faceRegistered,
                  app.applicantFaceRegistered,
                  Icons.face_rounded,
                  isDark,
                ),
                _verificationBadge(
                  l10n.electronicSignature,
                  app.applicantHasSignature,
                  Icons.draw_rounded,
                  isDark,
                ),
                _verificationBadge(
                  l10n.identityVerified,
                  app.applicantIsVerified,
                  Icons.badge_rounded,
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Applicant's message ──
          if (app.message != null && app.message!.isNotEmpty) ...[
            _buildInfoCard(
              icon: Icons.message_outlined,
              title: l10n.applicantMessage,
              isDark: isDark,
              child: Text(
                app.message!,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Owner actions (only if status is active) ──
          if (app.status.isActive) ...[
            _buildInfoCard(
              icon: Icons.touch_app_rounded,
              title: l10n.ownerActions,
              isDark: isDark,
              child: _buildOwnerActions(app, l10n, isDark),
            ),
            const SizedBox(height: 16),
          ],

          // ── Rejection reason ──
          if (app.rejectionReason != null &&
              app.rejectionReason!.isNotEmpty) ...[
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

          // ── Visit date ──
          if (app.visitDate != null) ...[
            _buildInfoCard(
              icon: Icons.event_rounded,
              title: l10n.visitDate,
              isDark: isDark,
              child: Text(
                _formatDateTime(app.visitDate!),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Deal terms (amount + assigned lawyer) ──
          if (app.dealAmount != null) ...[
            _buildInfoCard(
              icon: Icons.receipt_long_rounded,
              title: l10n.dealTerms,
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_money_rounded,
                          size: 20, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.dealAmount}: ${app.dealAmount!.toStringAsFixed(2)} ${l10n.currency}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (app.assignedLawyerName != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.gavel_rounded,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${l10n.assignLawyer}: ${app.assignedLawyerName}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Conversation ──
          _buildConversationSection(l10n, isDark),
          const SizedBox(height: 16),

          // ── Status history ──
          if (app.statusHistory.isNotEmpty) ...[
            _buildInfoCard(
              icon: Icons.history_rounded,
              title: l10n.statusHistory,
              isDark: isDark,
              child: Column(
                children: app.statusHistory
                    .map((e) => _buildHistoryEntry(e, l10n, isDark))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Feedback message
          if (_vm.actionMessage != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _vm.actionMessage == 'STATUS_UPDATED'
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _vm.actionMessage == 'STATUS_UPDATED'
                    ? l10n.statusUpdated
                    : _vm.actionMessage!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _vm.actionMessage == 'STATUS_UPDATED'
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Status Banner ──────────────────────────────────────────────

  Widget _buildStatusBanner(
      ApplicationModel app, AppLocalizations l10n, bool isDark) {
    final color = _statusColor(app.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(app.status), color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedStatus(l10n, app.status),
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusDescription(l10n, app.status),
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
    );
  }

  // ─── Owner Action Buttons ───────────────────────────────────────

  Widget _buildOwnerActions(
      ApplicationModel app, AppLocalizations l10n, bool isDark) {
    final List<_ActionItem> actions = [];

    switch (app.status) {
      case ApplicationStatus.pending:
        actions.add(_ActionItem(
          label: l10n.markUnderReview,
          icon: Icons.rate_review_rounded,
          color: AppColors.info,
          onTap: () => _showNoteDialog(
              l10n, isDark, l10n.markUnderReview, (note) {
            _vm.markUnderReview(note: note);
          }),
        ));
        actions.add(_ActionItem(
          label: l10n.rejectApplication,
          icon: Icons.cancel_rounded,
          color: AppColors.error,
          onTap: () => _showRejectDialog(l10n, isDark),
        ));
        break;
      case ApplicationStatus.underReview:
        actions.add(_ActionItem(
          label: l10n.scheduleVisit,
          icon: Icons.event_rounded,
          color: Colors.deepPurple,
          onTap: () => _showVisitDialog(l10n, isDark),
        ));
        actions.add(_ActionItem(
          label: l10n.preApprove,
          icon: Icons.thumb_up_rounded,
          color: Colors.teal,
          onTap: () => _showNoteDialog(
              l10n, isDark, l10n.preApprove, (note) {
            _vm.preApprove(note: note);
          }),
        ));
        actions.add(_ActionItem(
          label: l10n.rejectApplication,
          icon: Icons.cancel_rounded,
          color: AppColors.error,
          onTap: () => _showRejectDialog(l10n, isDark),
        ));
        break;
      case ApplicationStatus.visitScheduled:
        actions.add(_ActionItem(
          label: l10n.preApprove,
          icon: Icons.thumb_up_rounded,
          color: Colors.teal,
          onTap: () => _showNoteDialog(
              l10n, isDark, l10n.preApprove, (note) {
            _vm.preApprove(note: note);
          }),
        ));
        actions.add(_ActionItem(
          label: l10n.rejectApplication,
          icon: Icons.cancel_rounded,
          color: AppColors.error,
          onTap: () => _showRejectDialog(l10n, isDark),
        ));
        break;
      case ApplicationStatus.preApproved:
        actions.add(_ActionItem(
          label: l10n.acceptApplication,
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          onTap: () => _showNoteDialog(
              l10n, isDark, l10n.acceptApplication, (note) {
            _vm.accept(note: note);
          }),
        ));
        actions.add(_ActionItem(
          label: l10n.rejectApplication,
          icon: Icons.cancel_rounded,
          color: AppColors.error,
          onTap: () => _showRejectDialog(l10n, isDark),
        ));
        break;
      case ApplicationStatus.accepted:
        // After accepted, owner sets the deal amount
        actions.add(_ActionItem(
          label: l10n.setAmount,
          icon: Icons.attach_money_rounded,
          color: Colors.orange,
          onTap: () => _showSetAmountDialog(l10n, isDark, app),
        ));
        break;
      case ApplicationStatus.negotiation:
        // Amount confirmed, now owner selects a lawyer
        actions.add(_ActionItem(
          label: l10n.selectLawyer,
          icon: Icons.gavel_rounded,
          color: AppColors.primary,
          onTap: () => _showSelectLawyerDialog(l10n, isDark),
        ));
        break;
      case ApplicationStatus.awaitingLawyer:
        // Waiting for lawyer assignment (already in progress)
        break;
      case ApplicationStatus.contractDrafting:
        // Lawyer is working on the contract — no owner action needed
        break;
      default:
        break;
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions.map((a) {
        return ElevatedButton.icon(
          onPressed: _vm.isUpdatingStatus ? null : a.onTap,
          icon: _vm.isUpdatingStatus
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Icon(a.icon, size: 18),
          label: Text(a.label),
          style: ElevatedButton.styleFrom(
            backgroundColor: a.color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        );
      }).toList(),
    );
  }

  // ─── Conversation Section ───────────────────────────────────

  Widget _buildConversationSection(AppLocalizations l10n, bool isDark) {
    return _buildInfoCard(
      icon: Icons.chat_bubble_outline_rounded,
      title: l10n.conversation,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Messages list
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
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) =>
                  _buildMessageBubble(_vm.messages[i], isDark),
            ),
          const SizedBox(height: 12),

          // Input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: 2,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: l10n.typeMessage,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed:
                    _vm.isSendingMessage ? null : _sendMessage,
                icon: _vm.isSendingMessage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ApplicationMessage msg, bool isDark) {
    final isMe = msg.senderId == _currentUserId;
    return Align(
      alignment: isMe
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                child: Text(
                  msg.senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Text(
              msg.content,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _vm.sendMessage(text);
  }

  // ─── Status History Entry ──────────────────────────────────────

  Widget _buildHistoryEntry(
      ApplicationStatusEntry entry, AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor(entry.toStatus),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                Text(
                  _formatDateTime(entry.createdAt),
                  style: TextStyle(
                    fontSize: 11,
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
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────

  void _showNoteDialog(AppLocalizations l10n, bool isDark, String title,
      void Function(String? note) onConfirm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.addNote,
            hintText: l10n.noteHint,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.rejectApplication),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.rejectReason,
            hintText: l10n.rejectReasonHint,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
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
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.scheduleVisit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date picker
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded),
                title: Text(l10n.visitDate),
                subtitle: Text(_formatDate(selectedDate)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                tileColor: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.withValues(alpha: 0.06),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setDialogState(() => selectedDate = date);
                  }
                },
              ),
              const SizedBox(height: 8),
              // Time picker
              ListTile(
                leading: const Icon(Icons.access_time_rounded),
                title: const Text('Time'),
                subtitle: Text(selectedTime.format(ctx)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                tileColor: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.withValues(alpha: 0.06),
                onTap: () async {
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setDialogState(() => selectedTime = time);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.addNote,
                  hintText: l10n.noteHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel)),
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(l10n.scheduleVisit),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared widgets ────────────────────────────────────────────

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
        border:
            Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
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
                  child:
                      Icon(icon, color: AppColors.primary, size: 18),
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
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationBadge(
      String label, bool verified, IconData icon, bool isDark) {
    final color = verified ? AppColors.success : AppColors.textSecondary;
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
          Text(
            label,
            style:
                TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
          ),
          const SizedBox(width: 4),
          Icon(
            verified ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: color,
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────

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

  String _statusDescription(AppLocalizations l10n, ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pending:
        return 'Waiting for owner review';
      case ApplicationStatus.underReview:
        return 'Owner is reviewing this application';
      case ApplicationStatus.visitScheduled:
        return 'A property visit has been scheduled';
      case ApplicationStatus.preApproved:
        return 'Application pre-approved, pending final acceptance';
      case ApplicationStatus.accepted:
        return 'Application accepted — set the deal amount';
      case ApplicationStatus.negotiation:
        return 'Deal amount set — select a lawyer to draft the contract';
      case ApplicationStatus.awaitingLawyer:
        return 'Waiting for the assigned lawyer to start';
      case ApplicationStatus.contractDrafting:
        return 'The lawyer is preparing the contract';
      case ApplicationStatus.rejected:
        return 'Application was rejected';
      case ApplicationStatus.cancelled:
        return 'Application was cancelled by applicant';
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime d) =>
      '${_formatDate(d)} ${_formatTime(d)}';

  // ─── Negotiation dialogs ─────────────────────────────────────

  void _showSetAmountDialog(
      AppLocalizations l10n, bool isDark, ApplicationModel app) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.setAmount),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.enterAmount,
              suffixText: l10n.currency,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.amountRequired;
              final parsed = double.tryParse(v.trim());
              if (parsed == null || parsed <= 0) return l10n.amountInvalid;
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              if (snapshot.hasError) {
                return Center(child: Text(l10n.noVerifiedLawyers));
              }
              final lawyers = snapshot.data ?? [];
              if (lawyers.isEmpty) {
                return Center(child: Text(l10n.noVerifiedLawyers));
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: lawyers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final lawyer = lawyers[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
        ],
      ),
    );
  }
}

/// Helper class for action button config
class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
