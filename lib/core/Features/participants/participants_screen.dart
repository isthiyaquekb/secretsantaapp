import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:xmasfriend/core/Features/draw/whos_drawing_screen.dart';
import 'package:xmasfriend/core/Features/participants/widgets/import_confirm_bottom_sheet.dart';
import 'package:xmasfriend/core/constants/app_assets.dart';
import 'package:xmasfriend/core/data/draw_repository.dart';
import 'package:xmasfriend/core/services/draw_service.dart';
import 'package:xmasfriend/core/services/participant_import_service.dart';
import 'package:xmasfriend/core/services/storage_service.dart';
import 'package:xmasfriend/core/services/template_service.dart';
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
    final state = await DrawRepository.instance.load();
    List<String> list = state.participants;
    if (list.isEmpty) {
      list = await StorageService.loadParticipants();
      if (list.isNotEmpty) {
        await DrawRepository.instance.save(state.copyWith(participants: list));
      }
    }
    if (!mounted) return;
    setState(() {
      _participants = List<String>.from(list);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _persistParticipants() async {
    final state = await DrawRepository.instance.load();
    await DrawRepository.instance.save(
      state.copyWith(participants: _participants),
    );
    await StorageService.saveParticipants(_participants);
  }

  Future<void> _addParticipant() async {
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
    await _persistParticipants();
    _nameFocus.requestFocus();
  }

  Future<void> _removeParticipant(int index) async {
    setState(() {
      _participants.removeAt(index);
    });
    await _persistParticipants();
  }

  Future<void> _downloadSampleTemplate() async {
    try {
      await TemplateService.downloadOrShareSampleTemplate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample CSV ready!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't download template."),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Future<void> _importFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      // Parse the file into a table
      final table = ParticipantImportService.parseTable(
        bytes: bytes,
        fileName: file.name,
      );

      // Detect the best matching column (or null if none qualifies)
      final detectedColumn = ParticipantImportService.detectNameColumn(table);

      if (!mounted) return;

      // Show minimal confirmation bottom sheet
      final selectedColumn = await showModalBottomSheet<ColumnSelection>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ImportConfirmBottomSheet(
          table: table,
          initialSelection: detectedColumn,
        ),
      );

      if (selectedColumn == null || !mounted) return;

      // Extract raw cleaned names
      final rawNames = ParticipantImportService.extractRawNames(
        table,
        selectedColumn,
      );

      if (rawNames.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No names found in the selected column.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Check for duplicate names
      final duplicateCount = ParticipantImportService.countDuplicates(
        rawNames,
        _participants,
      );

      bool renumberDuplicates = false;
      if (duplicateCount > 0) {
        final choice = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            title: Text(
              'Duplicate Names Found',
              style: TextStyle(
                fontFamily: AppTheme.serifFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              '$duplicateCount duplicate ${duplicateCount == 1 ? 'name' : 'names'} found. Add numbers (John Smith 2) or skip them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(null),
                child: const Text('Cancel'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Skip them'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('Add numbers'),
              ),
            ],
          ),
        );

        if (choice == null || !mounted) return;
        renumberDuplicates = choice;
      }

      // Finalize import with 500 limit
      final importResult = ParticipantImportService.finalizeImport(
        extractedNames: rawNames,
        existingParticipants: _participants,
        renumberDuplicates: renumberDuplicates,
      );

      if (importResult.addedNames.isEmpty && importResult.reachedLimit) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Maximum 500 participants reached. No names were added.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _participants.addAll(importResult.addedNames);
      });
      await _persistParticipants();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(importResult.summaryMessage),
          backgroundColor: AppColors.lightPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Couldn't read this file. Check the format or use the template.",
          ),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Future<void> _startDraw() async {
    if (_participants.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'At least 3 participants are required to start the draw.',
          ),
        ),
      );
      return;
    }

    // Generate fresh pairings using Sattolo's single-cycle algorithm
    final pairsList = SecretSantaDrawService.generatePairings(_participants);
    final Map<String, String> pairsMap = {
      for (final p in pairsList) p.picker: p.picked,
    };

    final state = await DrawRepository.instance.load();
    await DrawRepository.instance.save(
      state.copyWith(
        participants: _participants,
        pairings: pairsMap,
        revealed: {},
      ),
    );
    await StorageService.savePairings(pairsList);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const WhosDrawingScreen()),
    );
  }

  // ---------------------------------------------------------------------------
  // UI building blocks
  // ---------------------------------------------------------------------------

  Color _muted(bool isDark) =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

  Widget _linkButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w500,
      color: color,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label, style: style, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              child: Padding(
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
          count == 1 ? '1 person in the draw' : '$count people in the draw',
          style: theme.textTheme.bodyMedium?.copyWith(color: _muted(isDark)),
        ),
      ],
    );
  }

  Widget _buildInputCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerTheme.color ?? AppColors.lightDivider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.person_add_outlined, size: 20, color: _muted(isDark)),
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
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _addParticipant,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(68, 42),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildImportSection(ThemeData theme, bool isDark, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: _linkButton(
                  icon: Icons.file_upload_outlined,
                  label: 'Import from Excel or CSV',
                  onTap: _importFile,
                  color: _muted(isDark),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: _linkButton(
                  icon: Icons.download_outlined,
                  label: 'Download sample CSV',
                  onTap: _downloadSampleTemplate,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tip: use a column named Name, or First Name and Last Name.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: _muted(isDark),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: count >= 3 ? theme.colorScheme.primary : Colors.orange,
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
    );
  }

  Widget _buildListHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'PARTICIPANTS',
          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.0),
        ),
        Text('Min. 3 required', style: theme.textTheme.labelSmall),
      ],
    );
  }

  Widget _buildList(ThemeData theme, bool isDark) {
    if (_participants.isEmpty) {
      return Center(
        child: Text(
          'No participants added yet.\nAdd names above or import from Excel/CSV.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: _muted(isDark)),
        ),
      );
    }

    return ListView.separated(
      itemCount: _participants.length,
      separatorBuilder: (context, _) =>
          Divider(color: theme.dividerTheme.color, height: 1),
      itemBuilder: (context, index) {
        final name = _participants[index];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              AppAvatar(name: name, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: _muted(isDark)),
                onPressed: () => _removeParticipant(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDark, int count) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 15, color: _muted(isDark)),
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Start the draw'),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
                _buildHeader(theme, isDark, count),
                const SizedBox(height: 24),
                _buildInputCard(theme, isDark),
                _buildImportSection(theme, isDark, count),
                const SizedBox(height: 12),
                _buildListHeader(theme),
                const SizedBox(height: 8),
                Expanded(child: _buildList(theme, isDark)),
                _buildFooter(theme, isDark, count),
              ],
            ),
          ),
        ),
      ),
    );
  }
}