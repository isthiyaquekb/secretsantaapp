import 'package:flutter/material.dart';
import 'package:xmasfriend/core/services/participant_import_service.dart';
import 'package:xmasfriend/core/theme/app_colors.dart';
import 'package:xmasfriend/core/theme/app_theme.dart';

class ImportConfirmBottomSheet extends StatefulWidget {
  final ParsedTable table;
  final ColumnSelection? initialSelection;

  const ImportConfirmBottomSheet({
    super.key,
    required this.table,
    this.initialSelection,
  });

  @override
  State<ImportConfirmBottomSheet> createState() =>
      _ImportConfirmBottomSheetState();
}

class _ImportConfirmBottomSheetState extends State<ImportConfirmBottomSheet> {
  late ColumnSelection? _selectedColumn;
  late bool _isPickingColumn;

  @override
  void initState() {
    super.initState();
    _selectedColumn = widget.initialSelection;
    // If no column qualified automatically, go straight to the column picker
    _isPickingColumn = widget.initialSelection == null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final dividerColor =
        isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _isPickingColumn
              ? _buildColumnPicker(theme, isDark, dividerColor)
              : _buildPreview(theme, isDark, dividerColor),
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme, bool isDark, Color dividerColor) {
    final selection = _selectedColumn;
    if (selection == null) {
      return _buildColumnPicker(theme, isDark, dividerColor);
    }

    final rawNames = ParticipantImportService.extractRawNames(
      widget.table,
      selection,
    );
    final totalCount = rawNames.length;
    final previewNames = rawNames.take(5).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Serif Title
        Text(
          'Confirm Import',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontFamily: AppTheme.serifFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),

        // Subtitle: "Found N names from <column description>"
        Text(
          'Found $totalCount ${totalCount == 1 ? 'name' : 'names'} from ${selection.label}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // Preview box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBackground.withValues(alpha: 0.6)
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PREVIEW (FIRST 5 NAMES)',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 10),
              if (previewNames.isEmpty)
                Text(
                  'No valid names found in this column.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                )
              else
                for (int i = 0; i < previewNames.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Text(
                          '${i + 1}. ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            previewNames[i],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              if (totalCount > 5) ...[
                const SizedBox(height: 6),
                Text(
                  '+ ${totalCount - 5} more names',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons: Import, Change column, Cancel
        ElevatedButton(
          onPressed: totalCount > 0
              ? () => Navigator.of(context).pop(selection)
              : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            ),
          ),
          child: const Text(
            'Import',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),

        OutlinedButton(
          onPressed: () {
            setState(() {
              _isPickingColumn = true;
            });
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            ),
          ),
          child: const Text('Change column'),
        ),
        const SizedBox(height: 6),

        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnPicker(ThemeData theme, bool isDark, Color dividerColor) {
    final availableSelections =
        ParticipantImportService.getAvailableColumnSelections(widget.table);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Name Column',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: AppTheme.serifFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedColumn != null)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isPickingColumn = false;
                  });
                },
                tooltip: 'Back to preview',
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the column containing participant names:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 14),

        // Scrollable column options list
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.45,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: availableSelections.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              color: dividerColor,
            ),
            itemBuilder: (context, index) {
              final sel = availableSelections[index];
              final isSelected = sel == _selectedColumn;

              String sampleVal = '';
              if (sel.type == ColumnSelectionType.single) {
                sampleVal = widget.table.getSampleValue(sel.columnIndex);
              } else {
                final first =
                    widget.table.getSampleValue(sel.firstNameColumnIndex);
                final last =
                    widget.table.getSampleValue(sel.lastNameColumnIndex);
                sampleVal = '$first $last'.trim();
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColumn = sel;
                    _isPickingColumn = false;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sel.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            if (sampleVal.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Sample: "$sampleVal"',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        if (_selectedColumn == null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
      ],
    );
  }
}
