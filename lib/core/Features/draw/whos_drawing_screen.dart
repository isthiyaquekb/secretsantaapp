import 'package:flutter/material.dart';
import 'package:xmasfriend/core/Features/draw/all_done_screen.dart';
import 'package:xmasfriend/core/Features/draw/private_reveal_screen.dart';
import 'package:xmasfriend/core/Features/hr/hr_pin_screen.dart';
import 'package:xmasfriend/core/data/draw_repository.dart';
import 'package:xmasfriend/core/employee_pair.dart';
import 'package:xmasfriend/core/services/storage_service.dart';
import 'package:xmasfriend/core/theme/app_colors.dart';
import 'package:xmasfriend/core/theme/app_theme.dart';
import 'package:xmasfriend/core/widgets/app_avatar.dart';
import 'package:xmasfriend/core/widgets/snowfall_overlay.dart';

class WhosDrawingScreen extends StatefulWidget {
  const WhosDrawingScreen({super.key});

  @override
  State<WhosDrawingScreen> createState() => _WhosDrawingScreenState();
}

class _WhosDrawingScreenState extends State<WhosDrawingScreen> {
  List<EmployeePair> _pairings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final state = await DrawRepository.instance.load();
    if (state.isComplete) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AllDoneScreen()),
      );
      return;
    }

    List<EmployeePair> pairs;
    if (state.pairings.isNotEmpty) {
      pairs = state.participants.map((name) {
        final picked = state.pairings[name] ?? '';
        final hasDrawn = state.revealed.contains(name);
        return EmployeePair(picker: name, picked: picked, hasDrawn: hasDrawn);
      }).toList();
    } else {
      pairs = await StorageService.loadPairings();
    }

    setState(() {
      _pairings = pairs;
      _isLoading = false;
    });

    if (pairs.isNotEmpty && pairs.every((p) => p.hasDrawn)) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AllDoneScreen()),
      );
    }
  }

  Future<void> _openPrivateReveal(String pickerName) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PrivateRevealScreen(pickerName: pickerName),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  void _openHrView() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HrPinScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final drawnList = _pairings.where((p) => p.hasDrawn).toList();
    final upNextList = _pairings.where((p) => !p.hasDrawn).toList();
    final total = _pairings.length;
    final done = drawnList.length;
    final progress = total > 0 ? (done / total) : 0.0;

    return Scaffold(
      body: SnowfallOverlay(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.horizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Top Nav Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '❅',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'WINTER RITUAL',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: _openHrView,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 6,
                              ),
                              child: Text(
                                'HR view',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Text(
                        "Who's drawing?",
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$done of $total done. Tap your name.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceContainerHigh
                              : AppColors.lightSurfaceContainerHigh,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Confidential Notice Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceContainerHigh
                              : AppColors.lightSurfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✦',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Drawings are confidential. Pick carefully when it's your turn.",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Main List Sections
                      Expanded(
                        child: ListView(
                          children: [
                            // Already Drawn Section
                            if (drawnList.isNotEmpty) ...[
                              Text(
                                'ALREADY DRAWN',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...drawnList.map((pair) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      AppAvatar(
                                        name: pair.picker,
                                        size: 34,
                                        isCompleted: true,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          pair.picker,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextMuted
                                                : AppColors.lightTextMuted,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 20),
                            ],

                            // Up Next Section
                            if (upNextList.isNotEmpty) ...[
                              Text(
                                'UP NEXT',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 0.8,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...upNextList.map((pair) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
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
                                      vertical: 2,
                                    ),
                                    leading: AppAvatar(
                                      name: pair.picker,
                                      size: 36,
                                    ),
                                    title: Text(
                                      pair.picker,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 15,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                    onTap: () =>
                                        _openPrivateReveal(pair.picker),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),

                      // Bottom Decorative Sparkles & Note
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('✦',
                                    style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 10)),
                                const SizedBox(width: 8),
                                Text('❅',
                                    style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 12)),
                                const SizedBox(width: 8),
                                Text('✦',
                                    style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Need to pass the phone? Make sure nobody else is peeking.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

