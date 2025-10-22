import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/constants.dart';

class RoleManagementTab extends StatefulWidget {
  const RoleManagementTab({super.key});

  @override
  State<RoleManagementTab> createState() => _RoleManagementTabState();
}

class _RoleManagementTabState extends State<RoleManagementTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _selectedPrivileges = [];
  Map<String, dynamic>? _editingRole;

  final List<String> _availablePrivileges = [
    'users.read',
    'users.create',
    'users.update',
    'users.delete',
    'roles.read',
    'roles.create',
    'roles.update',
    'roles.delete',
    'orders.read',
    'orders.create',
    'orders.update',
    'orders.delete',
    'drivers.read',
    'drivers.create',
    'drivers.update',
    'drivers.delete',
    'customers.read',
    'customers.create',
    'customers.update',
    'customers.delete',
    'payments.read',
    'payments.create',
    'payments.update',
    'payments.delete',
    'reports.read',
    'settings.read',
    'settings.update',
    'parametric_tables.read',
    'parametric_tables.create',
    'parametric_tables.update',
    'parametric_tables.delete',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showRoleDialog({Map<String, dynamic>? role}) {
    _editingRole = role;
    if (role != null) {
      _nameController.text = role['name'] ?? '';
      _descriptionController.text = role['description'] ?? '';
      _selectedPrivileges.clear();
      if (role['privileges'] != null) {
        _selectedPrivileges.addAll(List<String>.from(role['privileges']));
      }
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _selectedPrivileges.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(role == null ? 'Create Role' : 'Edit Role'),
        content: SizedBox(
          width: 500,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Role Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Role name is required';
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
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Privileges',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    itemCount: _availablePrivileges.length,
                    itemBuilder: (context, index) {
                      final privilege = _availablePrivileges[index];
                      return CheckboxListTile(
                        title: Text(privilege),
                        value: _selectedPrivileges.contains(privilege),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedPrivileges.add(privilege);
                            } else {
                              _selectedPrivileges.remove(privilege);
                            }
                          });
                        },
                      );
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
            onPressed: _saveRole,
            child: Text(role == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRole() async {
    if (!_formKey.currentState!.validate()) return;

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    bool success;

    if (_editingRole == null) {
      success = await adminProvider.createRole(
        _nameController.text,
        _descriptionController.text,
        _selectedPrivileges,
      );
    } else {
      success = await adminProvider.updateRole(
        _editingRole!['id'],
        _nameController.text,
        _descriptionController.text,
        _selectedPrivileges,
      );
    }

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingRole == null
              ? 'Role created successfully'
              : 'Role updated successfully'),
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

  Future<void> _deleteRole(String roleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this role?'),
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
      final success = await adminProvider.deleteRole(roleId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role deleted successfully'),
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
                    'Role Management',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showRoleDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Role'),
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
                child: adminProvider.roles.isEmpty
                    ? const Center(
                        child: Text('No roles found'),
                      )
                    : ListView.builder(
                        itemCount: adminProvider.roles.length,
                        itemBuilder: (context, index) {
                          final role = adminProvider.roles[index];
                          return Card(
                            margin:
                                const EdgeInsets.only(bottom: AppSizes.padding),
                            child: ListTile(
                              title: Text(
                                role['name'] ?? 'Unknown Role',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(role['description'] ?? 'No description'),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    children: (role['privileges']
                                                as List<dynamic>? ??
                                            [])
                                        .map((privilege) => Chip(
                                              label: Text(
                                                privilege.toString(),
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              backgroundColor: AppColors.primary
                                                  .withOpacity(0.1),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _showRoleDialog(role: role),
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit Role',
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteRole(role['id']),
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Delete Role',
                                    color: AppColors.error,
                                  ),
                                ],
                              ),
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
