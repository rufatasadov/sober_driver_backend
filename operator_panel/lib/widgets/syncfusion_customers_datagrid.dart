import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class SyncfusionCustomersDataGrid extends StatefulWidget {
  final List<Map<String, dynamic>> customers;
  final Function(Map<String, dynamic>) onCustomerTap;
  final Function(Map<String, dynamic>) onEditCustomer;
  final Function(Map<String, dynamic>) onDeleteCustomer;

  const SyncfusionCustomersDataGrid({
    super.key,
    required this.customers,
    required this.onCustomerTap,
    required this.onEditCustomer,
    required this.onDeleteCustomer,
  });

  @override
  State<SyncfusionCustomersDataGrid> createState() =>
      _SyncfusionCustomersDataGridState();
}

class _SyncfusionCustomersDataGridState
    extends State<SyncfusionCustomersDataGrid> {
  late CustomerDataGridSource _dataGridSource;
  late DataGridController _dataGridController;

  @override
  void initState() {
    super.initState();
    _dataGridController = DataGridController();
    _dataGridSource = CustomerDataGridSource(
      customers: widget.customers,
      onCustomerTap: widget.onCustomerTap,
      onEditCustomer: widget.onEditCustomer,
      onDeleteCustomer: widget.onDeleteCustomer,
    );
  }

  @override
  void didUpdateWidget(SyncfusionCustomersDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customers != widget.customers) {
      _dataGridSource.updateCustomers(widget.customers);
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
            final customer =
                widget.customers[details.rowColumnIndex.rowIndex - 1];
            widget.onCustomerTap(customer);
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
          GridColumn(
            columnName: 'email',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Email',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ),
            minimumWidth: 120,
            allowSorting: true,
            allowFiltering: true,
          ),
          GridColumn(
            columnName: 'address',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Ünvan',
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
            columnName: 'totalOrders',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(
                'Sifariş sayı',
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
            columnName: 'totalSpent',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerRight,
              child: Text(
                'Xərclənən məbləğ',
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
            columnName: 'lastOrderDate',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                'Son sifariş',
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
            columnName: 'isActive',
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(
                'Aktiv',
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
            minimumWidth: 100,
            allowSorting: false,
            allowFiltering: false,
          ),
        ],
      ),
    );
  }
}

class CustomerDataGridSource extends DataGridSource {
  CustomerDataGridSource({
    required List<Map<String, dynamic>> customers,
    required Function(Map<String, dynamic>) onCustomerTap,
    required Function(Map<String, dynamic>) onEditCustomer,
    required Function(Map<String, dynamic>) onDeleteCustomer,
  })  : _customers = customers,
        _onCustomerTap = onCustomerTap,
        _onEditCustomer = onEditCustomer,
        _onDeleteCustomer = onDeleteCustomer;

  final List<Map<String, dynamic>> _customers;
  final Function(Map<String, dynamic>) _onCustomerTap;
  final Function(Map<String, dynamic>) _onEditCustomer;
  final Function(Map<String, dynamic>) _onDeleteCustomer;

  void updateCustomers(List<Map<String, dynamic>> customers) {
    _customers.clear();
    _customers.addAll(customers);
    notifyListeners();
  }

  @override
  List<DataGridRow> get rows {
    print(
        'SyncfusionCustomersDataGrid: Building rows for ${_customers.length} customers');
    if (_customers.isNotEmpty) {
      print('First customer data: ${_customers.first}');
    }
    return _customers.map<DataGridRow>((customer) {
      return DataGridRow(cells: [
        DataGridCell<String>(
          columnName: 'name',
          value: customer['name'] ?? 'N/A',
        ),
        DataGridCell<String>(
          columnName: 'phone',
          value: customer['phone'] ?? 'N/A',
        ),
        DataGridCell<String>(
          columnName: 'email',
          value: customer['email'] ?? 'N/A',
        ),
        DataGridCell<String>(
          columnName: 'address',
          value: customer['address'] ?? 'N/A',
        ),
        DataGridCell<String>(
          columnName: 'totalOrders',
          value: (customer['totalOrders'] ?? 0).toString(),
        ),
        DataGridCell<String>(
          columnName: 'totalSpent',
          value: customer['totalSpent'] != null
              ? '${customer['totalSpent']} ₼'
              : '0 ₼',
        ),
        DataGridCell<String>(
          columnName: 'lastOrderDate',
          value: customer['lastOrder'] != null
              ? DateFormat('dd.MM.yyyy')
                  .format(DateTime.parse(customer['lastOrder']))
              : 'N/A',
        ),
        DataGridCell<Widget>(
          columnName: 'isActive',
          value: _buildBooleanChip(
              customer['isActive'] ?? true, 'Aktiv', 'Qeyri-aktiv'),
        ),
        DataGridCell<String>(
          columnName: 'createdAt',
          value: customer['registeredAt'] != null
              ? DateFormat('dd.MM.yyyy')
                  .format(DateTime.parse(customer['registeredAt']))
              : 'N/A',
        ),
        DataGridCell<Widget>(
          columnName: 'actions',
          value: _buildActionButtons(customer),
        ),
      ]);
    }).toList();
  }

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataGridCell) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          alignment: dataGridCell.columnName == 'totalOrders' ||
                  dataGridCell.columnName == 'totalSpent' ||
                  dataGridCell.columnName == 'isActive' ||
                  dataGridCell.columnName == 'actions'
              ? Alignment.center
              : dataGridCell.columnName == 'totalSpent'
                  ? Alignment.centerRight
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

  Widget _buildActionButtons(Map<String, dynamic> customer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.visibility,
            size: 16,
            color: AppColors.primary,
          ),
          onPressed: () => _onCustomerTap(customer),
          tooltip: 'Ətraflı bax',
        ),
        IconButton(
          icon: Icon(
            Icons.edit,
            size: 16,
            color: AppColors.info,
          ),
          onPressed: () => _onEditCustomer(customer),
          tooltip: 'Redaktə et',
        ),
        IconButton(
          icon: Icon(
            Icons.delete,
            size: 16,
            color: AppColors.error,
          ),
          onPressed: () => _onDeleteCustomer(customer),
          tooltip: 'Sil',
        ),
      ],
    );
  }

  @override
  bool shouldRecalculateColumnWidths() {
    return true;
  }
}
