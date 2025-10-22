import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class SyncfusionDriversDataGrid extends StatefulWidget {
  final List<Map<String, dynamic>> drivers;
  final Function(Map<String, dynamic>) onDriverTap;
  final Function(Map<String, dynamic>) onEditDriver;
  final Function(Map<String, dynamic>) onDeleteDriver;
  final Function(Map<String, dynamic>) onToggleStatus;

  const SyncfusionDriversDataGrid({
    super.key,
    required this.drivers,
    required this.onDriverTap,
    required this.onEditDriver,
    required this.onDeleteDriver,
    required this.onToggleStatus,
  });

  @override
  State<SyncfusionDriversDataGrid> createState() =>
      _SyncfusionDriversDataGridState();
}

class _SyncfusionDriversDataGridState extends State<SyncfusionDriversDataGrid> {
  late DriverDataGridSource _dataGridSource;
  late DataGridController _dataGridController;

  @override
  void initState() {
    super.initState();
    _dataGridController = DataGridController();
    _dataGridSource = DriverDataGridSource(
      drivers: widget.drivers,
      onDriverTap: widget.onDriverTap,
      onEditDriver: widget.onEditDriver,
      onDeleteDriver: widget.onDeleteDriver,
      onToggleStatus: widget.onToggleStatus,
    );
  }

  @override
  void didUpdateWidget(SyncfusionDriversDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.drivers != widget.drivers) {
      _dataGridSource.updateDrivers(widget.drivers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: SfDataGrid(
        controller: _dataGridController,
        source: _dataGridSource,
        allowSorting: true,
        allowFiltering: true,
        allowMultiColumnSorting: true,
        allowColumnsResizing: true,
        columnResizeMode: ColumnResizeMode.onResize,
        columnWidthMode: ColumnWidthMode.fill,
        gridLinesVisibility: GridLinesVisibility.both,
        headerGridLinesVisibility: GridLinesVisibility.both,
        selectionMode: SelectionMode.single,
        headerRowHeight: 50,
        rowHeight: 50,
        onCellTap: (DataGridCellTapDetails details) {
          if (details.rowColumnIndex.rowIndex > 0) {
            final driver = widget.drivers[details.rowColumnIndex.rowIndex - 1];
            widget.onDriverTap(driver);
          }
        },
        columns: <GridColumn>[
          GridColumn(
            columnName: 'name',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Ad',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            minimumWidth: 100,
            allowSorting: true,
            allowFiltering: true,
          ),
          GridColumn(
            columnName: 'phone',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Telefon',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            minimumWidth: 100,
            allowSorting: true,
            allowFiltering: true,
          ),
          // Email column removed - hidden from display
          GridColumn(
            columnName: 'licenseNumber',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Lisenziya №',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            minimumWidth: 100,
            allowSorting: true,
            allowFiltering: true,
          ),
          GridColumn(
            columnName: 'status',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(
                'Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            minimumWidth: 80,
            allowSorting: true,
            allowFiltering: true,
          ),
          GridColumn(
            columnName: 'isOnline',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(
                'Onlayn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            minimumWidth: 60,
            allowSorting: true,
            allowFiltering: true,
          ),
          GridColumn(
            columnName: 'isAvailable',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(
                'Mövcud',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            minimumWidth: 60,
            allowSorting: true,
            allowFiltering: true,
          ),
          GridColumn(
            columnName: 'rating',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(
                'Reytinq',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            minimumWidth: 80,
            allowSorting: true,
            allowFiltering: true,
          ),
          GridColumn(
            columnName: 'createdAt',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Qeydiyyat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            minimumWidth: 100,
            allowSorting: true,
            allowFiltering: true,
          ),
          GridColumn(
            columnName: 'actions',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(
                'Əməliyyatlar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            minimumWidth: 120,
            allowSorting: false,
            allowFiltering: false,
          ),
        ],
      ),
    );
  }
}

class DriverDataGridSource extends DataGridSource {
  DriverDataGridSource({
    required List<Map<String, dynamic>> drivers,
    required Function(Map<String, dynamic>) onDriverTap,
    required Function(Map<String, dynamic>) onEditDriver,
    required Function(Map<String, dynamic>) onDeleteDriver,
    required Function(Map<String, dynamic>) onToggleStatus,
  })  : _drivers = drivers,
        _onDriverTap = onDriverTap,
        _onEditDriver = onEditDriver,
        _onDeleteDriver = onDeleteDriver,
        _onToggleStatus = onToggleStatus;

  final List<Map<String, dynamic>> _drivers;
  final Function(Map<String, dynamic>) _onDriverTap;
  final Function(Map<String, dynamic>) _onEditDriver;
  final Function(Map<String, dynamic>) _onDeleteDriver;
  final Function(Map<String, dynamic>) _onToggleStatus;

  void updateDrivers(List<Map<String, dynamic>> drivers) {
    _drivers.clear();
    _drivers.addAll(drivers);
    print('Syncfusion DataGrid updated with ${_drivers.length} drivers');
    if (_drivers.isNotEmpty) {
      print('First driver in DataGrid: ${_drivers.first}');
    }
    notifyListeners();
  }

  @override
  List<DataGridRow> get rows => _drivers.map<DataGridRow>((driver) {
        return DataGridRow(cells: [
          DataGridCell<String>(
            columnName: 'name',
            value: driver['user']?['name'] ?? 'N/A',
          ),
          DataGridCell<String>(
            columnName: 'phone',
            value: driver['user']?['phone'] ?? 'N/A',
          ),
          // Email removed from display
          DataGridCell<String>(
            columnName: 'licenseNumber',
            value: driver['licenseNumber'] ?? 'N/A',
          ),
          DataGridCell<Widget>(
            columnName: 'status',
            value: _buildStatusChip(driver['status'] ?? 'offline'),
          ),
          DataGridCell<Widget>(
            columnName: 'isOnline',
            value: _buildBooleanChip(
                driver['isOnline'] ?? false, 'Onlayn', 'Offlayn'),
          ),
          DataGridCell<Widget>(
            columnName: 'isAvailable',
            value: _buildBooleanChip(
                driver['isAvailable'] ?? false, 'Mövcud', 'Məşğul'),
          ),
          DataGridCell<Widget>(
            columnName: 'rating',
            value: _buildRatingChip(_getRatingValue(driver['rating'])),
          ),
          DataGridCell<String>(
            columnName: 'createdAt',
            value: driver['createdAt'] != null
                ? DateFormat('dd.MM.yyyy')
                    .format(DateTime.parse(driver['createdAt']))
                : 'Tarix yoxdur',
          ),
          DataGridCell<Widget>(
            columnName: 'actions',
            value: _buildActionButtons(driver),
          ),
        ]);
      }).toList();

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataGridCell) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          alignment: dataGridCell.columnName == 'rating' ||
                  dataGridCell.columnName == 'isOnline' ||
                  dataGridCell.columnName == 'isAvailable' ||
                  dataGridCell.columnName == 'actions'
              ? Alignment.center
              : dataGridCell.columnName == 'status'
                  ? Alignment.center
                  : Alignment.centerLeft,
          child: dataGridCell.value is Widget
              ? dataGridCell.value
              : Text(
                  dataGridCell.value.toString(),
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    // Determine status based on isOnline and isAvailable
    if (status == 'online' || status == 'offline' || status == 'busy') {
      switch (status.toLowerCase()) {
        case 'online':
          backgroundColor = AppColors.success.withOpacity(0.1);
          textColor = AppColors.success;
          statusText = 'Onlayn';
          break;
        case 'offline':
          backgroundColor = AppColors.error.withOpacity(0.1);
          textColor = AppColors.error;
          statusText = 'Oflayn';
          break;
        case 'busy':
          backgroundColor = AppColors.warning.withOpacity(0.1);
          textColor = AppColors.warning;
          statusText = 'Məşğul';
          break;
        default:
          backgroundColor = Colors.grey.withOpacity(0.1);
          textColor = Colors.grey;
          statusText = 'Oflayn';
      }
    } else {
      // Default to offline if status is not recognized
      backgroundColor = AppColors.error.withOpacity(0.1);
      textColor = AppColors.error;
      statusText = 'Oflayn';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBooleanChip(bool value, String trueText, String falseText) {
    final backgroundColor = value
        ? AppColors.success.withOpacity(0.1)
        : AppColors.error.withOpacity(0.1);
    final textColor = value ? AppColors.success : AppColors.error;
    final text = value ? trueText : falseText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  double _getRatingValue(dynamic rating) {
    try {
      if (rating == null) return 0.0;

      if (rating is num) {
        return rating.toDouble();
      } else if (rating is String) {
        return double.tryParse(rating) ?? 0.0;
      } else if (rating is Map && rating['average'] != null) {
        return double.tryParse(rating['average'].toString()) ?? 0.0;
      }

      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Widget _buildRatingChip(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: 16,
          color: rating >= 4.0 ? AppColors.warning : AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> driver) {
    return Container(
      width: 120, // Fixed width to prevent overflow
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.visibility,
              size: 14,
              color: AppColors.primary,
            ),
            onPressed: () => _onDriverTap(driver),
            tooltip: 'Ətraflı bax',
            padding: EdgeInsets.all(2),
            constraints: BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              size: 14,
              color: AppColors.info,
            ),
            onPressed: () => _onEditDriver(driver),
            tooltip: 'Redaktə et',
            padding: EdgeInsets.all(2),
            constraints: BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          IconButton(
            icon: Icon(
              driver['isActive'] == true
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              size: 14,
              color: driver['isActive'] == true
                  ? AppColors.warning
                  : AppColors.success,
            ),
            onPressed: () => _onToggleStatus(driver),
            tooltip: driver['isActive'] == true ? 'Deaktiv et' : 'Aktiv et',
            padding: EdgeInsets.all(2),
            constraints: BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              size: 14,
              color: AppColors.error,
            ),
            onPressed: () => _onDeleteDriver(driver),
            tooltip: 'Sil',
            padding: EdgeInsets.all(2),
            constraints: BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRecalculateColumnWidths() {
    return true;
  }
}
