import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class SyncfusionOrdersDataGrid extends StatefulWidget {
  final List<Map<String, dynamic>> orders;
  final Function(Map<String, dynamic>) onOrderTap;
  final Function(Map<String, dynamic>) onAssignDriver;
  final Function(Map<String, dynamic>) onCancelOrder;

  const SyncfusionOrdersDataGrid({
    super.key,
    required this.orders,
    required this.onOrderTap,
    required this.onAssignDriver,
    required this.onCancelOrder,
  });

  @override
  State<SyncfusionOrdersDataGrid> createState() =>
      _SyncfusionOrdersDataGridState();
}

class _SyncfusionOrdersDataGridState extends State<SyncfusionOrdersDataGrid> {
  late OrderDataGridSource _dataGridSource;
  late DataGridController _dataGridController;

  @override
  void initState() {
    super.initState();
    _dataGridController = DataGridController();
    _dataGridSource = OrderDataGridSource(
      orders: widget.orders,
      onOrderTap: widget.onOrderTap,
      onAssignDriver: widget.onAssignDriver,
      onCancelOrder: widget.onCancelOrder,
    );
  }

  @override
  void didUpdateWidget(SyncfusionOrdersDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orders != widget.orders) {
      _dataGridSource.updateOrders(widget.orders);
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
        columnResizeMode: ColumnResizeMode.onResizeEnd,
        columnWidthMode: ColumnWidthMode.fill,
        gridLinesVisibility: GridLinesVisibility.both,
        headerGridLinesVisibility: GridLinesVisibility.both,
        footerHeight: 100,
        allowPullToRefresh: true,
        //shrinkWrapColumns: true,
        shrinkWrapRows: true,
        showHorizontalScrollbar: true,
        highlightRowOnHover: true,
        selectionMode: SelectionMode.single,
        headerRowHeight: 80,
        rowHeight: 50,
        onCellTap: (DataGridCellTapDetails details) {
          if (details.rowColumnIndex.rowIndex > 0) {
            final order = widget.orders[details.rowColumnIndex.rowIndex - 1];
            widget.onOrderTap(order);
          }
        },
        columns: <GridColumn>[
          GridColumn(
            columnName: 'orderNumber',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Sifariş №',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            minimumWidth: 100,
            allowSorting: true,
            allowFiltering: true,

            //columnWidthMode: ColumnWidthMode.fitByCellValue
          ),
          GridColumn(
            columnName: 'customer',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Müştəri',
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
          GridColumn(
            columnName: 'pickup',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Götürülmə yeri',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            minimumWidth: 150,
            allowSorting: true,
            allowFiltering: true,
          ),
          GridColumn(
            columnName: 'destination',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Təyinat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            minimumWidth: 150,
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
            minimumWidth: 100,
            allowSorting: true,
            allowFiltering: false,
          ),
          GridColumn(
            columnName: 'fare',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerRight,
              child: Text(
                'Qiymət',
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
                'Tarix',
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
            minimumWidth: 150,
            allowSorting: false,
            allowFiltering: false,
          ),
        ],
      ),
    );
  }
}

class OrderDataGridSource extends DataGridSource {
  OrderDataGridSource({
    required List<Map<String, dynamic>> orders,
    required Function(Map<String, dynamic>) onOrderTap,
    required Function(Map<String, dynamic>) onAssignDriver,
    required Function(Map<String, dynamic>) onCancelOrder,
  })  : _orders = orders,
        _onOrderTap = onOrderTap,
        _onAssignDriver = onAssignDriver,
        _onCancelOrder = onCancelOrder;

  final List<Map<String, dynamic>> _orders;
  final Function(Map<String, dynamic>) _onOrderTap;
  final Function(Map<String, dynamic>) _onAssignDriver;
  final Function(Map<String, dynamic>) _onCancelOrder;

  void updateOrders(List<Map<String, dynamic>> orders) {
    _orders.clear();
    _orders.addAll(orders);
    notifyListeners();
  }

  @override
  List<DataGridRow> get rows => _orders.map<DataGridRow>((order) {
        return DataGridRow(cells: [
          DataGridCell<String>(
            columnName: 'orderNumber',
            value: order['orderNumber'] ?? 'N/A',
          ),
          DataGridCell<String>(
            columnName: 'customer',
            value: order['customer']?['name'] ?? 'N/A',
          ),
          DataGridCell<String>(
            columnName: 'phone',
            value: order['customer']?['phone'] ?? 'N/A',
          ),
          DataGridCell<String>(
            columnName: 'pickup',
            value: order['pickup']?['address'] ?? 'N/A',
          ),
          DataGridCell<String>(
            columnName: 'destination',
            value: order['destination']?['address'] ?? 'N/A',
          ),
          DataGridCell<Widget>(
            columnName: 'status',
            value: _buildStatusChip(order['status'] ?? 'pending'),
          ),
          DataGridCell<String>(
            columnName: 'fare',
            value: _formatFare(order['fare']),
          ),
          DataGridCell<String>(
            columnName: 'createdAt',
            value: order['createdAt'] != null
                ? DateFormat('dd.MM.yyyy HH:mm')
                    .format(DateTime.parse(order['createdAt']))
                : 'N/A',
          ),
          DataGridCell<Widget>(
            columnName: 'actions',
            value: _buildActionButtons(order),
          ),
        ]);
      }).toList();

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataGridCell) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          alignment: dataGridCell.columnName == 'fare' ||
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

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        statusText = AppStrings.pending;
        break;
      case 'accepted':
        backgroundColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        statusText = AppStrings.accepted;
        break;
      case 'driver_assigned':
        backgroundColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        statusText = 'Sürücü təyin edildi';
        break;
      case 'driver_arrived':
        backgroundColor = AppColors.primary.withOpacity(0.1);
        textColor = AppColors.primary;
        statusText = 'Sürücü gəldi';
        break;
      case 'in_progress':
        backgroundColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        statusText = AppStrings.inProgress;
        break;
      case 'completed':
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        statusText = AppStrings.completed;
        break;
      case 'cancelled':
        backgroundColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        statusText = AppStrings.cancelled;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        statusText = status;
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

  Widget _buildActionButtons(Map<String, dynamic> order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.visibility,
            size: 16,
            color: AppColors.primary,
          ),
          onPressed: () => _onOrderTap(order),
          tooltip: 'Ətraflı bax',
        ),
        if (order['status'] == 'pending' || order['status'] == 'accepted')
          IconButton(
            icon: Icon(
              Icons.person_add,
              size: 16,
              color: AppColors.success,
            ),
            onPressed: () => _onAssignDriver(order),
            tooltip: 'Sürücü təyin et',
          ),
        if (order['status'] != 'completed' && order['status'] != 'cancelled')
          IconButton(
            icon: Icon(
              Icons.cancel,
              size: 16,
              color: AppColors.error,
            ),
            onPressed: () => _onCancelOrder(order),
            tooltip: 'Ləğv et',
          ),
      ],
    );
  }

  String _formatFare(dynamic fare) {
    if (fare == null) return 'N/A';

    // If fare is a number, format it directly
    if (fare is num) {
      return '${fare.toStringAsFixed(2)} ₼';
    }

    // If fare is a Map/object, try to get the total or amount
    if (fare is Map<String, dynamic>) {
      final total = fare['total'] ?? fare['amount'] ?? fare['price'];
      if (total != null) {
        return '${total.toStringAsFixed(2)} ₼';
      }
    }

    // If fare is a string, try to parse it
    if (fare is String) {
      final parsed = double.tryParse(fare);
      if (parsed != null) {
        return '${parsed.toStringAsFixed(2)} ₼';
      }
    }

    return 'N/A';
  }

  @override
  bool shouldRecalculateColumnWidths() {
    return true;
  }
}
