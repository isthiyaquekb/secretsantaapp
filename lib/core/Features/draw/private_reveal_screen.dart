import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:xmasfriend/core/data/draw_repository.dart';
import 'package:xmasfriend/core/employee_pair.dart';
import 'package:xmasfriend/core/services/storage_service.dart';
import 'package:xmasfriend/core/theme/app_colors.dart';
import 'package:xmasfriend/core/theme/app_theme.dart';
import 'package:xmasfriend/core/widgets/snowfall_overlay.dart';

class PrivateRevealScreen extends StatefulWidget {
  final String pickerName;

  const PrivateRevealScreen({
    super.key,
    required this.pickerName,
  });

  @override
  State<PrivateRevealScreen> createState() => _PrivateRevealScreenState();
}

class _PrivateRevealScreenState extends State<PrivateRevealScreen>
    with WidgetsBindingObserver {
  late ConfettiController _confettiController;
  EmployeePair? _pair;
  int _year = currentSeasonYear();
  bool _isLoading = true;
  bool _isHolding = false;
  bool _hasRevealedOnce = false;
  bool _hasFiredConfetti = false;
  String? _selectedGift;
  bool _hasMadeGiftChoice = false;

  final List<String> _suggestedGifts = [
    'Coffee beans',
    'Scented candle',
    'Desk plant',
    'Notebook set',
    'Mug',
    'Chocolate box',
    'Board game',
    'Warm socks',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1200),
    );
    _loadPair();
  }

  Future<void> _loadPair() async {
    final state = await DrawRepository.instance.load();
    _year = state.year;

    EmployeePair pair;
    if (state.pairings.containsKey(widget.pickerName)) {
      final picked = state.pairings[widget.pickerName]!;
      final hasDrawn = state.revealed.contains(widget.pickerName);
      pair = EmployeePair(
          picker: widget.pickerName, picked: picked, hasDrawn: hasDrawn);
    } else {
      final pairings = await StorageService.loadPairings();
      pair = pairings.firstWhere(
        (p) => p.picker.toLowerCase() == widget.pickerName.toLowerCase(),
        orElse: () =>
            EmployeePair(picker: widget.pickerName, picked: 'Unknown'),
      );
    }

    setState(() {
      _pair = pair;
      _selectedGift = pair.giftIdea;
      _hasMadeGiftChoice = pair.giftIdea != null;
      _isLoading = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Hide revealed name immediately if app is sent to background or switcher
    if (state != AppLifecycleState.resumed && _isHolding) {
      setState(() {
        _isHolding = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    super.dispose();
  }

  void _onPointerDown() {
    setState(() {
      _isHolding = true;
      _hasRevealedOnce = true;
    });

    if (!_hasFiredConfetti) {
      _hasFiredConfetti = true;
      _confettiController.play();
    }
  }

  void _onPointerUp() {
    if (_isHolding) {
      setState(() {
        _isHolding = false;
      });
    }
  }

  Future<void> _openCustomGiftDialog() async {
    final textController = TextEditingController(text: _selectedGift ?? '');
    final customName = await showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Your Gift Idea', style: theme.textTheme.headlineSmall),
          content: TextField(
            controller: textController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Enter custom gift idea (e.g. Book, Tea set)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, textController.text.trim()),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 42),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (customName != null && customName.isNotEmpty) {
      setState(() {
        _selectedGift = customName;
        _hasMadeGiftChoice = true;
      });
    }
  }

  Future<void> _completeTurn() async {
    if (_pair == null) return;

    // Mark revealed in DrawRepository
    await DrawRepository.instance.markRevealed(widget.pickerName);

    final pairings = await StorageService.loadPairings();
    final updatedList = pairings.map((p) {
      if (p.picker.toLowerCase() == widget.pickerName.toLowerCase()) {
        return p.copyWith(
          hasDrawn: true,
          giftIdea: _selectedGift,
        );
      }
      return p;
    }).toList();

    await StorageService.savePairings(updatedList);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SnowfallOverlay(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.horizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Navigation Row
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
                                'Exchange $_year',
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

                    // Confidential Badge
                    Row(
                      children: [
                        Text(
                          'CONFIDENTIAL',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '✦',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    Text(
                      'Hi, ${widget.pickerName}',
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Make sure no one is looking.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Hold to Reveal Container
                    Listener(
                      onPointerDown: (_) => _onPointerDown(),
                      onPointerUp: (_) => _onPointerUp(),
                      onPointerCancel: (_) => _onPointerUp(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: _isHolding
                              ? (isDark
                                  ? AppColors.darkSurfaceContainerHigh
                                  : AppColors.lightSurfaceContainerLow)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isHolding
                                ? theme.colorScheme.primary
                                : (theme.dividerTheme.color ??
                                    AppColors.lightDivider),
                            width: _isHolding ? 1.5 : 1.0,
                            strokeAlign: BorderSide.strokeAlignCenter,
                          ),
                        ),
                        child: _isHolding
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkAvatarBg
                                          : AppColors.lightSurfaceContainerHigh,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.auto_awesome,
                                      size: 24,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'YOUR RECIPIENT',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _pair?.picked ?? '',
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurface
                                          : AppColors.lightSurfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Row(
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
                                          'Card unlocked & active',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurfaceContainerHigh
                                          : AppColors.lightSurfaceContainerHigh,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.touch_app_outlined,
                                      size: 22,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Hold to reveal',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Press and keep finger down',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Eye Icon Note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility_off_outlined,
                          size: 15,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Let go and the name hides again.',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Gift Idea Section (Highlighted until a selection/custom choice is made)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: !_hasMadeGiftChoice
                                  ? theme.colorScheme.primary
                                  : (theme.dividerTheme.color ??
                                      AppColors.lightDivider),
                              width: !_hasMadeGiftChoice ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Gift idea',
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurfaceContainerHigh
                                          : AppColors.lightSurfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      _selectedGift != null
                                          ? '1 chosen'
                                          : '0 chosen',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pick a suggestion, or choose your own.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Suggestion Chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ..._suggestedGifts.map((gift) {
                                    final isSelected = _selectedGift == gift;
                                    return ChoiceChip(
                                      label: Text(gift),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedGift = gift;
                                            _hasMadeGiftChoice = true;
                                          } else {
                                            _selectedGift = null;
                                          }
                                        });
                                      },
                                    );
                                  }),
                                  ActionChip(
                                    avatar: const Icon(Icons.edit_outlined,
                                        size: 14),
                                    label: Text(
                                      _selectedGift != null &&
                                              !_suggestedGifts
                                                  .contains(_selectedGift)
                                          ? _selectedGift!
                                          : "I'll choose my own",
                                    ),
                                    backgroundColor: _selectedGift != null &&
                                            !_suggestedGifts
                                                .contains(_selectedGift)
                                        ? theme.colorScheme.primary
                                        : null,
                                    labelStyle: TextStyle(
                                      color: _selectedGift != null &&
                                              !_suggestedGifts
                                                  .contains(_selectedGift)
                                          ? Colors.white
                                          : null,
                                    ),
                                    onPressed: _openCustomGiftDialog,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Action (Done Button)
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _hasRevealedOnce ? _completeTurn : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Done'),
                              if (_hasRevealedOnce) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check, size: 18),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Assignments are private and encrypted',
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Confetti Burst Layer
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  AppColors.confettiRed,
                  AppColors.confettiGold,
                  AppColors.confettiGreen,
                ],
                numberOfParticles: 35,
                gravity: 0.25,
                emissionFrequency: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

