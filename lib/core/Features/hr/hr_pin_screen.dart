import 'package:flutter/material.dart';
import 'package:xmasfriend/core/Features/hr/hr_pairings_screen.dart';
import 'package:xmasfriend/core/Features/participants/participants_screen.dart';
import 'package:xmasfriend/core/data/draw_repository.dart';
import 'package:xmasfriend/core/theme/app_colors.dart';
import 'package:xmasfriend/core/theme/app_theme.dart';
import 'package:xmasfriend/core/widgets/snowfall_overlay.dart';

class HrPinScreen extends StatefulWidget {
  const HrPinScreen({super.key});

  @override
  State<HrPinScreen> createState() => _HrPinScreenState();
}

class _HrPinScreenState extends State<HrPinScreen> {
  bool _isLoading = true;
  bool _hasExistingPin = false;

  // Setup mode states
  bool _isConfirmingSetup = false;
  String _setupFirstPin = '';

  String _enteredPin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final hasPin = await DrawRepository.instance.hasHrPin();
    setState(() {
      _hasExistingPin = hasPin;
      _isLoading = false;
    });
  }

  void _onDigitPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        if (!_hasExistingPin) {
          _handleSetupStep();
        } else {
          _validateExistingPin();
        }
      }
    }
  }

  void _onBackspacePress() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleSetupStep() async {
    if (!_isConfirmingSetup) {
      // Transition to confirmation step
      setState(() {
        _setupFirstPin = _enteredPin;
        _enteredPin = '';
        _isConfirmingSetup = true;
      });
    } else {
      // Check confirmation matches
      if (_enteredPin == _setupFirstPin) {
        await DrawRepository.instance.setHrPin(_enteredPin);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HrPairingsScreen(),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'PINs do not match. Please start again.';
          _enteredPin = '';
          _setupFirstPin = '';
          _isConfirmingSetup = false;
        });
      }
    }
  }

  Future<void> _validateExistingPin() async {
    final isValid = await DrawRepository.instance.verifyHrPin(_enteredPin);
    if (isValid) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HrPairingsScreen(),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
        _enteredPin = '';
      });
    }
  }

  Future<void> _showForgotPinDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Reset Master PIN & Draw?',
              style: theme.textTheme.headlineSmall),
          content: const Text(
            'Resetting your coordinator PIN will permanently clear all generated pairings and active reveals. Participants will need to draw again.\n\nAre you sure you want to reset?',
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
                minimumSize: const Size(110, 42),
              ),
              child: const Text('Reset All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await DrawRepository.instance.resetDrawAndPin();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('HR PIN and draw have been reset.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

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

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String titleText = 'HR view';
    String subtitleText =
        'Enter the 4-digit PIN to manage\npairings and secret assignments.';

    if (!_hasExistingPin) {
      if (!_isConfirmingSetup) {
        titleText = 'Set a 4-digit PIN';
        subtitleText =
            'Create a 4-digit master PIN to secure\nconfidential coordinator access.';
      } else {
        titleText = 'Confirm PIN';
        subtitleText = 'Re-enter your 4-digit master PIN\nto confirm.';
      }
    }

    return Scaffold(
      body: SnowfallOverlay(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.horizontalPadding,
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Nav Bar
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
                            Icons.lock_outline,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ADMIN',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Shield Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainerHigh
                        : AppColors.lightSurfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security,
                    size: 26,
                    color: theme.colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  titleText,
                  style: theme.textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitleText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),

                const SizedBox(height: 24),

                // PIN Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? theme.colorScheme.primary
                            : (isDark
                                ? AppColors.darkSurfaceContainerHigh
                                : AppColors.lightSurfaceContainerHigh),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const Spacer(),

                // Keypad
                _buildKeypad(theme, isDark),

                const SizedBox(height: 16),

                // Forgot PIN Link (only if a PIN exists)
                if (_hasExistingPin)
                  TextButton(
                    onPressed: _showForgotPinDialog,
                    child: Text(
                      'Forgot master PIN?',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 38),

                Text(
                  'Confidential coordinator access',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme, bool isDark) {
    const letters = {
      '1': '',
      '2': 'ABC',
      '3': 'DEF',
      '4': 'GHI',
      '5': 'JKL',
      '6': 'MNO',
      '7': 'PQRS',
      '8': 'TUV',
      '9': 'WXYZ',
      '0': '',
    };

    Widget buildButton(String digit) {
      return InkWell(
        onTap: () => _onDigitPress(digit),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceContainerHigh
                : AppColors.lightSurfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (letters[digit]!.isNotEmpty)
                Text(
                  letters[digit]!,
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.2,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildButton('1'),
            buildButton('2'),
            buildButton('3'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildButton('4'),
            buildButton('5'),
            buildButton('6'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildButton('7'),
            buildButton('8'),
            buildButton('9'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 68, height: 68),
            buildButton('0'),
            InkWell(
              onTap: _onBackspacePress,
              borderRadius: BorderRadius.circular(100),
              child: SizedBox(
                width: 68,
                height: 68,
                child: Center(
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 22,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
