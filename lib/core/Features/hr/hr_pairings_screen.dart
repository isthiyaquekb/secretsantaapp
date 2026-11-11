import 'package:flutter/material.dart';
import 'package:xmasfriend/core/Features/participants/participants_screen.dart';
import 'package:xmasfriend/core/data/draw_repository.dart';
import 'package:xmasfriend/core/data/draw_state.dart';
import 'package:xmasfriend/core/employee_pair.dart';
import 'package:xmasfriend/core/services/storage_service.dart';
import 'package:xmasfriend/core/theme/app_colors.dart';
import 'package:xmasfriend/core/theme/app_theme.dart';
import 'package:xmasfriend/core/utils/exchange_date.dart';
import 'package:xmasfriend/core/widgets/app_avatar.dart';
import 'package:xmasfriend/core/widgets/snowfall_overlay.dart';

class HrPairingsScreen extends StatefulWidget {
  const HrPairingsScreen({super.key});

  @override
  State<HrPairingsScreen> createState() => _HrPairingsScreenState();
}

class _HrPairingsScreenState extends State<HrPairingsScreen> {
  List<EmployeePair> _pairings = [];
  DrawState _drawState = DrawState(year: currentSeasonYear());
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final state = await DrawRepository.instance.load();
    List<EmployeePair> list;
    if (state.pairings.isNotEmpty) {
      list = state.participants.map((name) {
        final picked = state.pairings[name] ?? '';
        final hasDrawn = state.revealed.contains(name);
        return EmployeePair(picker: name, picked: picked, hasDrawn: hasDrawn);
      }).toList();
    } else {
      list = await StorageService.loadPairings();
    }

    setState(() {
      _drawState = state;
      _pairings = list;
      _isLoading = false;
    });
  }

  Future<void> _pickExchangeDate() async {
    final picked = await pickExchangeDate(
      context,
      year: _drawState.year,
      current: _drawState.exchangeDate,
    );

    if (picked != null) {
      final updated = _drawState.copyWith(exchangeDate: picked);
      await DrawRepository.instance.save(updated);
      setState(() {
        _drawState = updated;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exchange date set to ${formatShortDate(picked)}.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showChangePinFlow() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    // Step 1: Verify Current PIN
    final currentPin = await showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Verify Current PIN',
              style: theme.textTheme.headlineSmall),
          content: TextField(
            controller: currentController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: const InputDecoration(
              hintText: 'Enter current 4-digit PIN',
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = currentController.text.trim();
                if (text.length == 4) {
                  Navigator.pop(context, text);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 42),
              ),
              child: const Text('Next'),
            ),
          ],
        );
      },
    );

    if (currentPin == null) return;

    final isCorrect = await DrawRepository.instance.verifyHrPin(currentPin);
    if (!isCorrect) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Incorrect current PIN.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Step 2: Enter & Confirm New PIN
    final newPin = await showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        String? dialogError;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('Set New PIN', style: theme.textTheme.headlineSmall),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter new 4-digit PIN',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      hintText: 'Confirm new 4-digit PIN',
                      counterText: '',
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      dialogError!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final p1 = newController.text.trim();
                    final p2 = confirmController.text.trim();
                    if (p1.length != 4 || int.tryParse(p1) == null) {
                      setDialogState(() {
                        dialogError = 'PIN must be 4 numeric digits.';
                      });
                      return;
                    }
                    if (p1 != p2) {
                      setDialogState(() {
                        dialogError = 'PINs do not match.';
                      });
                      return;
                    }
                    Navigator.pop(context, p1);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 42),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newPin != null) {
      await DrawRepository.instance.setHrPin(newPin);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('HR PIN updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmResetDraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Reset All Pairings?',
              style: theme.textTheme.headlineSmall),
          content: const Text(
            'Are you sure you want to reset the draw? All existing pairings and revealed statuses will be permanently cleared, and participants will need to draw again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                minimumSize: const Size(100, 42),
              ),
              child: const Text('Reset Draw'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await DrawRepository.instance.resetDraw();
      await StorageService.clearPairings();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draw has been reset.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Return to ParticipantsScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const ParticipantsScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final total = _pairings.length;
    final drawnCount = _pairings.where((p) => p.hasDrawn).length;
    final pendingCount = total - drawnCount;
    final progress = total > 0 ? (drawnCount / total) : 0.0;
    final exchangeDate =
        _drawState.exchangeDate ?? defaultExchangeDate(_drawState.year);

    return Scaffold(
      body: SnowfallOverlay(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.horizontalPadding,
                  ),
                  children: [
                    const SizedBox(height: 12),
                    // Top Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 2,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_back_ios, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Back',
                                  style: theme.textTheme.titleSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainerHigh
                                : AppColors.lightSurfaceContainerHigh,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'HR view',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Title
                    Row(
                      children: [
                        Text(
                          'Pairings',
                          style: theme.textTheme.displayMedium,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '✦',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confidential audit view. Only authorized organizers may view active assignments.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Exchange Date ListTile (Problem 2)
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : AppColors.lightSurfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.dividerTheme.color ??
                              AppColors.lightDivider,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 0,
                        ),
                        leading: Icon(
                          Icons.event_outlined,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        title: Text(
                          'Exchange date',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          formatShortDate(exchangeDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          Icons.calendar_month,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        onTap: _pickExchangeDate,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Progress Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : AppColors.lightSurfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Draw progress',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$drawnCount of $total assigned',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: isDark
                                  ? AppColors.darkSurfaceContainerLow
                                  : AppColors.lightDivider,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$drawnCount Drawn',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$pendingCount Pending draw',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'SECRET SANTA',
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            'RECIPIENT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Pairings List Items
                    for (final pair in _pairings) ...[
                      _buildPairingCard(pair, theme, isDark),
                      const SizedBox(height: 8),
                    ],

                    // Notice Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : AppColors.lightSurfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pairing reveals are encrypted per employee session. Resetting the draw will shuffle all assignments and notify active recipients.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action Button (Reset draw)
                    ElevatedButton.icon(
                      onPressed: _confirmResetDraw,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reset draw'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : AppColors.lightSurfaceContainerHigh,
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Change PIN Action (on-screen PIN removed completely)
                    Center(
                      child: InkWell(
                        onTap: _showChangePinFlow,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Change PIN',
                            style: theme.textTheme.labelSmall?.copyWith(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'Exchange rule: Budget capped at \$30',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPairingCard(EmployeePair pair, ThemeData theme, bool isDark) {
    final hasDrawn = pair.hasDrawn;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: hasDrawn
            ? theme.colorScheme.surface
            : (isDark
                ? AppColors.darkSurfaceContainerHigh
                : AppColors.lightSurfaceContainerLow),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerTheme.color ?? AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          AppAvatar(
            name: pair.picker,
            size: 34,
            isTwoLetter: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pair.picker,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_forward,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: hasDrawn
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          pair.picked,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'not drawn',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
