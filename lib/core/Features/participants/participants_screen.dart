import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:xmasfriend/core/Features/draw/whos_drawing_screen.dart';
import 'package:xmasfriend/core/constants/app_assets.dart';
import 'package:xmasfriend/core/services/draw_service.dart';
import 'package:xmasfriend/core/services/participant_import_service.dart';
import 'package:xmasfriend/core/services/storage_service.dart';
import 'package:xmasfriend/core/theme/app_colors.dart';
import 'package:xmasfriend/core/theme/app_theme.dart';
import 'package:xmasfriend/core/widgets/app_avatar.dart';
import 'package:xmasfriend/core/widgets/snowfall_overlay.dart';

class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({super.key});

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  List<String> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await StorageService.loadParticipants();
    setState(() {
      _participants = list;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _addParticipant() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Check if duplicate (case-insensitive)
    final isDup = _participants.any(
      (p) => p.trim().toLowerCase() == name.toLowerCase(),
    );
    if (isDup) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name is already in the list'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    setState(() {
      _participants.add(name);
      _nameController.clear();
    });
    StorageService.saveParticipants(_participants);
    _nameFocus.requestFocus();
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants.removeAt(index);
    });
    StorageService.saveParticipants(_participants);
  }

  Future<void> _importFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      final importResult = ParticipantImportService.parseFileBytes(
        bytes: bytes,
        fileName: file.name,
        existingParticipants: _participants,
      );

      setState(() {
        _participants.addAll(importResult.addedNames);
      });
      await StorageService.saveParticipants(_participants);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(importResult.summaryMessage),
          backgroundColor: AppColors.lightPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing file: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Future<void> _startDraw() async {
    if (_participants.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 3 participants are required to start the draw.'),
        ),
      );
      return;
    }

    // Check if pairings already exist or if we should generate fresh ones
    final existingPairings = await StorageService.loadPairings();
    if (existingPairings.isEmpty ||
        existingPairings.length != _participants.length) {
      final newPairs = SecretSantaDrawService.generatePairings(_participants);
      await StorageService.savePairings(newPairs);
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WhosDrawingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final count = _participants.length;

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
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Secret Santa',
                                    style: theme.textTheme.headlineLarge,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '★',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceContainerHigh
                                  : AppColors.lightSurfaceContainerHigh,
                              shape: BoxShape.circle,
                            ),
                            child:Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: SvgPicture.asset(
                                  AppAssets.appLogoSvg,
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.card_giftcard,
                                    size: 44,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        count == 1
                            ? '1 person in the draw'
                            : '$count people in the draw',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Input Box Card
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.dividerTheme.color ??
                                AppColors.lightDivider,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Icon(
                              Icons.person_add_outlined,
                              size: 20,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                focusNode: _nameFocus,
                                textCapitalization: TextCapitalization.words,
                                onSubmitted: (_) => _addParticipant(),
                                decoration: const InputDecoration(
                                  hintText: 'Add a name',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _addParticipant,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(68, 42),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),

                      // Import from Excel or CSV row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: InkWell(
                                onTap: _importFile,
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.file_upload_outlined,
                                        size: 16,
                                        color: isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Import from Excel or CSV',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            decoration: TextDecoration.underline,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: count >= 3
                                        ? theme.colorScheme.primary
                                        : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  count >= 3 ? 'Ready to match' : 'Min. 3 needed',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Participants Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PARTICIPANTS',
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            'Min. 3 required',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Participant List
                      Expanded(
                        child: _participants.isEmpty
                            ? Center(
                                child: Text(
                                  'No participants added yet.\nAdd names above or import from Excel/CSV.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _participants.length,
                                separatorBuilder: (context, _) => Divider(
                                  color: theme.dividerTheme.color,
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final name = _participants[index];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        AppAvatar(name: name, size: 36),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            size: 20,
                                            color: isDark
                                                ? AppColors.darkTextMuted
                                                : AppColors.lightTextMuted,
                                          ),
                                          onPressed: () =>
                                              _removeParticipant(index),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Footer & Action Button
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 15,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Draw assignments remain completely secret',
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: count >= 3 ? _startDraw : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text('Start the draw'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
