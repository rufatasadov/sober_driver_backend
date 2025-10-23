import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdvancedTableView<T> extends StatefulWidget {
  final List<T> data;
  final List<TableColumn<T>> columns;
  final Widget Function(T item, TableColumn<T> column) cellBuilder;
  final String Function(T item, String columnKey) valueExtractor;
  final List<String> Function(String columnKey) uniqueValuesExtractor;
  final String title;
  final VoidCallback? onRefresh;
  final bool showColumnControls;
  final bool autoSizeColumns; // New parameter for auto-sizing

  const AdvancedTableView({
    Key? key,
    required this.data,
    required this.columns,
    required this.cellBuilder,
    required this.valueExtractor,
    required this.uniqueValuesExtractor,
    required this.title,
    this.onRefresh,
    this.showColumnControls = true,
    this.autoSizeColumns = false, // Default to false
  }) : super(key: key);

  @override
  State<AdvancedTableView<T>> createState() => _AdvancedTableViewState<T>();
}

class _AdvancedTableViewState<T> extends State<AdvancedTableView<T>> {
  late List<TableColumn<T>> _columns;
  final Map<String, Set<String>> _columnFilters = {};
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final String _prefsKey = 'advanced_table_layout';

  // Global key for measuring text
  final GlobalKey _measureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _columns = List.from(widget.columns);
    _loadColumnLayout();

    // Auto-size columns on init if enabled
    if (widget.autoSizeColumns) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSizeColumns();
      });
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> _loadColumnLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLayout = prefs.getStringList('${_prefsKey}_${widget.title}');
      if (savedLayout != null) {
        setState(() {
          for (int i = 0; i < _columns.length && i < savedLayout.length; i++) {
            final parts = savedLayout[i].split('|');
            if (parts.length >= 2) {
              _columns[i].width =
                  double.tryParse(parts[0]) ?? _columns[i].width;
              _columns[i].isVisible = parts[1] == 'true';
            }
          }
        });
      }
    } catch (e) {
      // Ignore errors, use default layout
    }
  }

  Future<void> _saveColumnLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final layout =
          _columns.map((col) => '${col.width}|${col.isVisible}').toList();
      await prefs.setStringList('${_prefsKey}_${widget.title}', layout);
    } catch (e) {
      // Ignore errors
    }
  }

  void _toggleColumnVisibility(String columnKey) {
    setState(() {
      final column = _columns.firstWhere((col) => col.key == columnKey);
      column.isVisible = !column.isVisible;
    });
    _saveColumnLayout();
  }

  void _resetColumnLayout() {
    setState(() {
      _columns = List.from(widget.columns);
    });
    _saveColumnLayout();
  }

  void _applyFilter(String columnKey, String value, bool isSelected) {
    setState(() {
      if (!_columnFilters.containsKey(columnKey)) {
        _columnFilters[columnKey] = <String>{};
      }

      if (isSelected) {
        _columnFilters[columnKey]!.add(value);
      } else {
        _columnFilters[columnKey]!.remove(value);
        if (_columnFilters[columnKey]!.isEmpty) {
          _columnFilters.remove(columnKey);
        }
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _columnFilters.clear();
    });
  }

  List<T> _getFilteredData() {
    if (_columnFilters.isEmpty) return widget.data;

    return widget.data.where((item) {
      for (final entry in _columnFilters.entries) {
        final columnKey = entry.key;
        final filterValues = entry.value;
        final itemValue = widget.valueExtractor(item, columnKey);

        bool matches = false;
        for (String filterValue in filterValues) {
          if (itemValue.toLowerCase().contains(filterValue.toLowerCase())) {
            matches = true;
            break;
          }
        }

        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  void _showFilterDialog(TableColumn<T> column) {
    final uniqueValues = widget.uniqueValuesExtractor(column.key);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentFilters = _columnFilters[column.key] ?? <String>{};

          return Dialog(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 350,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${column.title} - Filter',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search box
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search values...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        // TODO: Implement search within filter dialog
                      },
                    ),
                  ),
                  // Filter options
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: uniqueValues.length,
                        itemBuilder: (context, index) {
                          final value = uniqueValues[index];
                          final isSelected = currentFilters.contains(value);

                          return CheckboxListTile(
                            title: Text(
                              value.isEmpty ? '(Empty)' : value,
                              style: TextStyle(
                                color: value.isEmpty ? Colors.grey : null,
                                fontSize: 14,
                              ),
                            ),
                            value: isSelected,
                            onChanged: (selected) {
                              _applyFilter(
                                  column.key, value, selected ?? false);
                              // Update dialog state to reflect changes
                              setDialogState(() {});
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Footer actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _columnFilters.remove(column.key);
                            });
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear Filters'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                        Text(
                          '${currentFilters.length} selected',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
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

  void _showSortDialog(TableColumn<T> column) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 350,
            maxHeight: 200,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sort,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${column.title} - Sort',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
              // Sort options
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.sort_by_alpha),
                      title: const Text('Sort Ascending (A-Z)'),
                      onTap: () {
                        _sortColumn(column.key, true);
                        Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.sort_by_alpha),
                      title: const Text('Sort Descending (Z-A)'),
                      onTap: () {
                        _sortColumn(column.key, false);
                        Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.clear),
                      title: const Text('Clear Sort'),
                      onTap: () {
                        _clearSort();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sortColumn(String columnKey, bool ascending) {
    // TODO: Implement column sorting
    print('Sorting $columnKey ${ascending ? 'ascending' : 'descending'}');
  }

  void _clearSort() {
    // TODO: Implement clear sort
    print('Clearing sort');
  }

  Widget _buildResizableHeader(TableColumn<T> column) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          column.width = (column.width + details.delta.dx).clamp(50.0, 300.0);
        });
        _saveColumnLayout();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: column.width,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Column title (centered with consistent sizing)
              Container(
                width: column.width,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        column.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
              // Sort and Filter icons (right-aligned with consistent sizing)
              Container(
                width: column.width,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Sort icon
                    Tooltip(
                      message: 'Click to sort ${column.title}',
                      child: InkWell(
                        onTap: () => _showSortDialog(column),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.sort,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Filter icon
                    Tooltip(
                      message: _columnFilters.containsKey(column.key) &&
                              _columnFilters[column.key]!.isNotEmpty
                          ? '${_columnFilters[column.key]!.length} filter(s) active - Click to modify'
                          : 'Click to filter ${column.title}',
                      child: InkWell(
                        onTap: () => _showFilterDialog(column),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _columnFilters.containsKey(column.key) &&
                                    _columnFilters[column.key]!.isNotEmpty
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1)
                                : Colors.grey.shade50,
                            border: Border.all(
                              color: _columnFilters.containsKey(column.key) &&
                                      _columnFilters[column.key]!.isNotEmpty
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            _columnFilters.containsKey(column.key) &&
                                    _columnFilters[column.key]!.isNotEmpty
                                ? Icons.filter_alt
                                : Icons.filter_alt_outlined,
                            size: 14,
                            color: _columnFilters.containsKey(column.key) &&
                                    _columnFilters[column.key]!.isNotEmpty
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnControls() {
    if (!widget.showColumnControls) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Column visibility controls as popup menu
          PopupMenuButton<String>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_column,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Columns',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
            tooltip: 'Show/Hide columns',
            onSelected: (columnKey) {
              setState(() {
                final column =
                    _columns.firstWhere((col) => col.key == columnKey);
                column.isVisible = !column.isVisible;
              });
              _saveColumnLayout();
            },
            itemBuilder: (context) => _columns.map((column) {
              return PopupMenuItem<String>(
                value: column.key,
                child: Row(
                  children: [
                    Icon(
                      column.isVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 18,
                      color: column.isVisible
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        column.title,
                        style: TextStyle(
                          fontWeight: column.isVisible
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: column.isVisible
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (column.isVisible)
                      Icon(
                        Icons.check,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 16),
          // Action buttons
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveColumnLayout,
            tooltip: 'Save column layout',
            color: Theme.of(context).colorScheme.primary,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.onRefresh,
            tooltip: 'Refresh data',
            color: Colors.grey.shade600,
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetColumnLayout,
            tooltip: 'Reset column layout',
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: _clearAllFilters,
            tooltip: 'Clear all filters',
            color: Colors.grey.shade600,
          ),
          if (widget.autoSizeColumns) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: _resetToAutoSizes,
              tooltip: 'Auto-size columns',
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }

  double _getTotalTableWidth(List<TableColumn<T>> visibleColumns) {
    return visibleColumns.fold(0.0, (sum, column) => sum + column.width);
  }

  // New method to calculate optimal column widths
  void _autoSizeColumns() {
    if (widget.data.isEmpty) return;

    setState(() {
      for (final column in _columns) {
        double maxWidth = _calculateColumnWidth(column);
        column.width = maxWidth.clamp(80.0, 400.0); // Min 80, Max 400
      }
    });
    _saveColumnLayout();
  }

  // Calculate optimal width for a specific column
  double _calculateColumnWidth(TableColumn<T> column) {
    double maxWidth = 0.0;

    // Start with column title width
    final titleWidth = _measureTextWidth(column.title,
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 12));
    maxWidth = titleWidth + 40; // Add padding and filter button space

    // Check data content width
    for (final item in widget.data) {
      final cellContent = widget.cellBuilder(item, column);
      double contentWidth = 0.0;

      if (cellContent is Text) {
        contentWidth = _measureTextWidth(
            cellContent.data ?? '', cellContent.style ?? const TextStyle());
      } else if (cellContent is Container) {
        // Handle container widgets with padding
        if (cellContent.child is Text) {
          final textChild = cellContent.child as Text;
          contentWidth = _measureTextWidth(
              textChild.data ?? '', textChild.style ?? const TextStyle());
          // Add container padding
          if (cellContent.padding != null) {
            contentWidth += (cellContent.padding as EdgeInsets).horizontal;
          }
        } else {
          contentWidth = 120; // Default container width
        }
      } else if (cellContent is Row) {
        // Calculate row width based on children
        contentWidth = _calculateRowWidth(cellContent);
      } else if (cellContent is Icon) {
        contentWidth = 24; // Icon width
      } else if (cellContent is IconButton) {
        contentWidth = 48; // Icon button width
      } else {
        // Default width for other widget types
        contentWidth = 100;
      }

      // Add padding and update max width
      contentWidth += 20; // Cell padding
      maxWidth = maxWidth > contentWidth ? maxWidth : contentWidth;
    }

    return maxWidth;
  }

  // Helper method to calculate row width
  double _calculateRowWidth(Row row) {
    double totalWidth = 0.0;
    for (final child in row.children) {
      if (child is Text) {
        totalWidth += _measureTextWidth(
            child.data ?? '', child.style ?? const TextStyle());
      } else if (child is Icon) {
        totalWidth += 24;
      } else if (child is SizedBox) {
        totalWidth += (child.width ?? 0);
      } else if (child is Container) {
        totalWidth += 50; // Default container width
      }
      // Add spacing between children
      if (child != row.children.last) {
        totalWidth += 8;
      }
    }
    return totalWidth;
  }

  // Helper method to measure text width
  double _measureTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    textPainter.layout();
    return textPainter.width;
  }

  // Method to reset columns to auto-calculated sizes
  void _resetToAutoSizes() {
    _autoSizeColumns();
  }

  // Method to handle data changes and auto-resize if needed
  void _handleDataChange() {
    if (widget.autoSizeColumns && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSizeColumns();
      });
    }
  }

  // Public method to manually trigger auto-sizing
  void autoSizeColumns() {
    if (mounted) {
      _autoSizeColumns();
    }
  }

  @override
  void didUpdateWidget(AdvancedTableView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-resize columns when data changes
    if (oldWidget.data != widget.data && widget.autoSizeColumns) {
      _handleDataChange();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleColumns = _columns.where((col) => col.isVisible).toList();
    final filteredData = _getFilteredData();

    return Column(
      children: [
        _buildColumnControls(),

        // Filter status
        if (_columnFilters.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${filteredData.length} items shown (${widget.data.length} total)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear Filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

        // Table
        Expanded(
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              notificationPredicate: (notification) => notification.depth == 1,
              child: SingleChildScrollView(
                controller: _verticalController,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: _getTotalTableWidth(visibleColumns),
                    ),
                    child: DataTable(
                      columnSpacing: 0,
                      horizontalMargin: 0,
                      dataRowHeight: 60,
                      headingRowHeight: 80,
                      columns: visibleColumns.map((column) {
                        return DataColumn(
                          label: _buildResizableHeader(column),
                        );
                      }).toList(),
                      rows: filteredData.map((item) {
                        return DataRow(
                          cells: visibleColumns.map((column) {
                            return DataCell(
                              Container(
                                width: column.width,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                child: widget.cellBuilder(item, column),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TableColumn<T> {
  final String key;
  final String title;
  double width;
  bool isVisible;

  TableColumn({
    required this.key,
    required this.title,
    this.width = 150.0,
    this.isVisible = true,
  });
}
