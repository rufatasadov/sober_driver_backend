import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/constants.dart';

class ParametricTableTab extends StatefulWidget {
  const ParametricTableTab({super.key});

  @override
  State<ParametricTableTab> createState() => _ParametricTableTabState();
}

class _ParametricTableTabState extends State<ParametricTableTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<Map<String, dynamic>> _columns = [];
  Map<String, dynamic>? _editingTable;

  final List<String> _columnTypes = [
    'text',
    'number',
    'boolean',
    'date',
    'email',
    'phone',
    'select',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showTableDialog({Map<String, dynamic>? table}) {
    _editingTable = table;
    if (table != null) {
      _nameController.text = table['name'] ?? '';
      _descriptionController.text = table['description'] ?? '';
      _columns.clear();
      if (table['columns'] != null) {
        _columns.addAll(List<Map<String, dynamic>>.from(table['columns']));
      }
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _columns.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(table == null
            ? 'Create Parametric Table'
            : 'Edit Parametric Table'),
        content: SizedBox(
          width: 600,
          height: 500,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Table Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Table name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Columns',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addColumn,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Column'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _columns.isEmpty
                      ? const Center(
                          child: Text('No columns defined'),
                        )
                      : ListView.builder(
                          itemCount: _columns.length,
                          itemBuilder: (context, index) {
                            return _buildColumnCard(index);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saveTable,
            child: Text(table == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnCard(int index) {
    final column = _columns[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: column['name'] ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Column Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _columns[index]['name'] = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Column name is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: column['type'] ?? 'text',
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _columnTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _columns[index]['type'] = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _removeColumn(index),
                  icon: const Icon(Icons.delete),
                  color: AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Required'),
                    value: column['required'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _columns[index]['required'] = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Unique'),
                    value: column['unique'] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _columns[index]['unique'] = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (column['type'] == 'select') ...[
              const SizedBox(height: 8),
              TextFormField(
                initialValue: column['options']?.join(', ') ?? '',
                decoration: const InputDecoration(
                  labelText: 'Options (comma separated)',
                  border: OutlineInputBorder(),
                  hintText: 'option1, option2, option3',
                ),
                onChanged: (value) {
                  _columns[index]['options'] =
                      value.split(',').map((e) => e.trim()).toList();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addColumn() {
    setState(() {
      _columns.add({
        'name': '',
        'type': 'text',
        'required': false,
        'unique': false,
      });
    });
  }

  void _removeColumn(int index) {
    setState(() {
      _columns.removeAt(index);
    });
  }

  Future<void> _saveTable() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate columns
    for (int i = 0; i < _columns.length; i++) {
      final column = _columns[i];
      if (column['name'] == null || column['name'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Column ${i + 1} name is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    bool success;

    if (_editingTable == null) {
      success = await adminProvider.createParametricTable(
        _nameController.text,
        _descriptionController.text,
        _columns,
      );
    } else {
      success = await adminProvider.updateParametricTable(
        _editingTable!['id'],
        _nameController.text,
        _descriptionController.text,
        _columns,
      );
    }

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingTable == null
              ? 'Table created successfully'
              : 'Table updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adminProvider.error ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTable(String tableId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
            'Are you sure you want to delete this parametric table?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final success = await adminProvider.deleteParametricTable(tableId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Table deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adminProvider.error ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Parametric Tables',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showTableDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Table'),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              if (adminProvider.error != null)
                Container(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  margin: const EdgeInsets.only(bottom: AppSizes.padding),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    border: Border.all(color: AppColors.error),
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: AppColors.error),
                      const SizedBox(width: AppSizes.paddingSmall),
                      Expanded(child: Text(adminProvider.error!)),
                      IconButton(
                        onPressed: adminProvider.clearError,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: adminProvider.parametricTables.isEmpty
                    ? const Center(
                        child: Text('No parametric tables found'),
                      )
                    : ListView.builder(
                        itemCount: adminProvider.parametricTables.length,
                        itemBuilder: (context, index) {
                          final table = adminProvider.parametricTables[index];
                          return Card(
                            margin:
                                const EdgeInsets.only(bottom: AppSizes.padding),
                            child: ExpansionTile(
                              title: Text(
                                table['name'] ?? 'Unknown Table',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  table['description'] ?? 'No description'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Columns:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: (table['columns']
                                                    as List<dynamic>? ??
                                                [])
                                            .map((column) => Chip(
                                                  label: Text(
                                                    '${column['name']} (${column['type']})',
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                  backgroundColor: AppColors
                                                      .secondary
                                                      .withOpacity(0.1),
                                                ))
                                            .toList(),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _showTableDialog(table: table),
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Edit'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _deleteTable(table['id']),
                                            icon: const Icon(Icons.delete),
                                            label: const Text('Delete'),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.error),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
