import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../providers/order_provider.dart'; // Added import for OrderProvider
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/syncfusion_drivers_datagrid.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriverProvider>(context, listen: false).loadDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.drivers,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                CustomButton(
                  onPressed: () => _showAddDriverDialog(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drive_eta),
                      const SizedBox(width: AppSizes.paddingSmall),
                      Text(AppStrings.addDriver),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingLarge),

            // Filters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Row(
                  children: [
                    // Search
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _searchController,
                        hintText: AppStrings.searchDrivers,
                        prefixIconData: Icons.search,
                        onChanged: (value) {
                          Provider.of<DriverProvider>(context, listen: false)
                              .searchDrivers(value);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.padding),

                    // Status Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: AppStrings.status,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'all', child: Text(AppStrings.all)),
                          DropdownMenuItem(
                              value: 'online', child: Text(AppStrings.online)),
                          DropdownMenuItem(
                              value: 'offline',
                              child: Text(AppStrings.offline)),
                          DropdownMenuItem(
                              value: 'busy', child: Text(AppStrings.busy)),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value ?? 'all';
                          });
                          if (value == 'all') {
                            Provider.of<DriverProvider>(context, listen: false)
                                .loadDrivers();
                          } else {
                            Provider.of<DriverProvider>(context, listen: false)
                                .loadDrivers(status: value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingLarge),

            // Drivers Table
            Expanded(
              child: Consumer<DriverProvider>(
                builder: (context, driverProvider, child) {
                  if (driverProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (driverProvider.drivers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.drive_eta_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSizes.padding),
                          Text(
                            AppStrings.noDrivers,
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SyncfusionDriversDataGrid(
                    drivers: driverProvider.drivers,
                    onDriverTap: _showDriverDetails,
                    onEditDriver: _editDriver,
                    onDeleteDriver: _deleteDriver,
                    onToggleStatus: _toggleDriverStatus,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDriverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddDriverDialog(),
    );
  }

  void _showDriverDetails(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (context) => DriverDetailsDialog(driver: driver),
    );
  }

  void _editDriver(Map<String, dynamic> driver) {
    // TODO: Implement edit driver functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redaktə funksiyası tezliklə əlavə ediləcək'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _deleteDriver(Map<String, dynamic> driver) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sürücünü sil'),
        content: Text('Bu sürücünü silmək istədiyinizə əminsiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Ləğv et'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Bəli, sil'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final driverProvider =
            Provider.of<DriverProvider>(context, listen: false);
        await driverProvider.deleteDriver(driver['_id']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sürücü uğurla silindi'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _toggleDriverStatus(Map<String, dynamic> driver) async {
    try {
      final driverProvider =
          Provider.of<DriverProvider>(context, listen: false);
      final currentStatus = driver['isActive'] ?? true;
      final newStatus = !currentStatus;

      await driverProvider.toggleDriverActive(driver['id'], newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sürücü ${newStatus ? 'aktiv' : 'deaktiv'} edildi',
          ),
          backgroundColor: newStatus ? AppColors.success : AppColors.warning,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class AddDriverDialog extends StatefulWidget {
  const AddDriverDialog({super.key});

  @override
  State<AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _licenseController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _actualAddressController = TextEditingController();

  // New fields
  DateTime? _licenseExpiryDate;
  String? _identityCardFront;
  String? _identityCardBack;
  String? _licenseFront;
  String? _licenseBack;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _actualAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.addDriver),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: AppStrings.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.padding),
              CustomTextField(
                controller: _phoneController,
                labelText: AppStrings.phone,
                hintText: '+994501234567',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.padding),
              CustomTextField(
                controller: _emailController,
                labelText: AppStrings.email,
                hintText: 'example@email.com',
              ),
              const SizedBox(height: AppSizes.padding),
              CustomTextField(
                controller: _licenseController,
                labelText: AppStrings.licenseNumber,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.padding),

              // Actual Address
              CustomTextField(
                controller: _actualAddressController,
                labelText: 'Faktiki ünvan',
                hintText: 'Yaşadığı ünvan',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.padding),

              // License Expiry Date
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() {
                      _licenseExpiryDate = date;
                    });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _licenseExpiryDate != null
                              ? '${_licenseExpiryDate!.day}/${_licenseExpiryDate!.month}/${_licenseExpiryDate!.year}'
                              : 'Sürücülük vəsiqəsinin bitmə tarixi',
                          style: TextStyle(
                            color: _licenseExpiryDate != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.padding),

              // Vehicle information section (optional for sober driver service)
              const SizedBox(height: AppSizes.padding),
              Text(
                'Avtomobil məlumatları (istəyə bağlı)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _makeController,
                      labelText: AppStrings.vehicleMake,
                      hintText: 'Məsələn: Toyota',
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(
                    child: CustomTextField(
                      controller: _modelController,
                      labelText: AppStrings.vehicleModel,
                      hintText: 'Məsələn: Camry',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.padding),
              CustomTextField(
                controller: _plateController,
                labelText: AppStrings.plateNumber,
                hintText: 'Məsələn: 10-AA-123',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        CustomButton(
          onPressed: _submitDriver,
          child: Text(AppStrings.add),
        ),
      ],
    );
  }

  void _submitDriver() async {
    if (_formKey.currentState!.validate()) {
      if (_licenseExpiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sürücülük vəsiqəsinin bitmə tarixini seçin'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final driverProvider =
            Provider.of<DriverProvider>(context, listen: false);

        // Prepare driver data
        final driverData = {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          'licenseNumber': _licenseController.text.trim(),
          'actualAddress': _actualAddressController.text.trim(),
          'licenseExpiryDate': _licenseExpiryDate!.toIso8601String(),
          if (_identityCardFront != null)
            'identityCardFront': _identityCardFront,
          if (_identityCardBack != null) 'identityCardBack': _identityCardBack,
          if (_licenseFront != null) 'licenseFront': _licenseFront,
          if (_licenseBack != null) 'licenseBack': _licenseBack,
        };

        // Only add vehicle information if provided
        final vehicleMake = _makeController.text.trim();
        final vehicleModel = _modelController.text.trim();
        final plateNumber = _plateController.text.trim();

        if (vehicleMake.isNotEmpty &&
            vehicleModel.isNotEmpty &&
            plateNumber.isNotEmpty) {
          driverData['vehicleMake'] = vehicleMake;
          driverData['vehicleModel'] = vehicleModel;
          driverData['plateNumber'] = plateNumber;
        }

        await driverProvider.createDriver(driverData);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sürücü uğurla əlavə edildi'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class DriverDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> driver;

  const DriverDetailsDialog({super.key, required this.driver});

  @override
  State<DriverDetailsDialog> createState() => _DriverDetailsDialogState();
}

class _DriverDetailsDialogState extends State<DriverDetailsDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sürücü Detalları',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information
                    _buildSectionTitle('Əsas Məlumatlar'),
                    _buildDetailRow(
                        'Ad', widget.driver['user']?['name'] ?? 'N/A'),
                    _buildDetailRow(
                        'Telefon', widget.driver['user']?['phone'] ?? 'N/A'),
                    _buildDetailRow(
                        'Email', widget.driver['user']?['email'] ?? 'N/A'),
                    _buildDetailRow('Sürücülük vəsiqəsi',
                        widget.driver['licenseNumber'] ?? 'N/A'),
                    _buildDetailRow('Faktiki ünvan',
                        widget.driver['actualAddress'] ?? 'N/A'),
                    _buildDetailRow('Vəsiqə bitmə tarixi',
                        _formatDate(widget.driver['licenseExpiryDate'])),

                    const SizedBox(height: 20),

                    // Vehicle Information
                    _buildSectionTitle('Avtomobil Məlumatları'),
                    _buildDetailRow('Marka',
                        widget.driver['vehicleInfo']?['make'] ?? 'N/A'),
                    _buildDetailRow('Model',
                        widget.driver['vehicleInfo']?['model'] ?? 'N/A'),
                    _buildDetailRow('Nömrə nişanı',
                        widget.driver['vehicleInfo']?['plateNumber'] ?? 'N/A'),

                    const SizedBox(height: 20),

                    // Documents
                    _buildSectionTitle('Sənədlər'),
                    _buildDocumentRow('Şəxsiyyət vəsiqəsi (Ön)',
                        widget.driver['identityCardFront']),
                    _buildDocumentRow('Şəxsiyyət vəsiqəsi (Arxa)',
                        widget.driver['identityCardBack']),
                    _buildDocumentRow('Sürücülük vəsiqəsi (Ön)',
                        widget.driver['licenseFront']),
                    _buildDocumentRow('Sürücülük vəsiqəsi (Arxa)',
                        widget.driver['licenseBack']),

                    const SizedBox(height: 20),

                    // Statistics
                    _buildSectionTitle('Statistika'),
                    _buildDetailRow('Reytinq',
                        '${widget.driver['rating']?['average']?.toStringAsFixed(1) ?? '0.0'} (${widget.driver['rating']?['count'] ?? 0} qiymətləndirmə)'),
                    _buildDetailRow('Ümumi qazanç',
                        '${widget.driver['earnings']?['total'] ?? 0} ₼'),
                    _buildDetailRow('Bugünkü qazanç',
                        '${widget.driver['earnings']?['today'] ?? 0} ₼'),
                    _buildDetailRow(
                        'Balans', '${widget.driver['balance'] ?? 0} ₼'),

                    const SizedBox(height: 20),

                    // Status
                    _buildSectionTitle('Status'),
                    _buildDetailRow(
                        'Onlayn status',
                        widget.driver['isOnline'] == true
                            ? 'Onlayn'
                            : 'Oflayn'),
                    _buildDetailRow(
                        'Müsaitlik',
                        widget.driver['isAvailable'] == true
                            ? 'Müsait'
                            : 'Məşğul'),
                    _buildDetailRow(
                        'Aktiv status',
                        widget.driver['isActive'] == true
                            ? 'Aktiv'
                            : 'Deaktiv'),
                    _buildDetailRow('Qeydiyyat tarixi',
                        _formatDateTime(widget.driver['createdAt'])),
                  ],
                ),
              ),
            ),

            const Divider(),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Bağla'),
                ),
                CustomButton(
                  onPressed: () => _toggleDriverActive(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.driver['isActive'] == true
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(widget.driver['isActive'] == true
                          ? 'Deaktiv et'
                          : 'Aktiv et'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildDocumentRow(String label, String? imagePath) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: imagePath != null && imagePath.isNotEmpty
                ? GestureDetector(
                    onTap: () => _showImageDialog(imagePath),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text('Şəkli gör',
                              style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                  )
                : const Text('Yüklənməyib',
                    style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              AppBar(
                title: const Text('Sənəd'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: imagePath.startsWith('http')
                      ? Image.network(imagePath, fit: BoxFit.contain)
                      : imagePath.startsWith('/') || imagePath.contains('\\')
                          ? Image.file(
                              File(imagePath),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Text('Şəkil yüklənə bilmədi'),
                                );
                              },
                            )
                          : const Center(
                              child: Text('Şəkil yüklənə bilmədi'),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleDriverActive() async {
    try {
      final driverProvider =
          Provider.of<DriverProvider>(context, listen: false);
      final currentStatus = widget.driver['isActive'] ?? true;
      final newStatus = !currentStatus;

      await driverProvider.toggleDriverActive(widget.driver['id'], newStatus);

      setState(() {
        widget.driver['isActive'] = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sürücü ${newStatus ? 'aktiv' : 'deaktiv'} edildi',
          ),
          backgroundColor: newStatus ? AppColors.success : AppColors.warning,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return 'N/A';
    }
  }
}

class DriverLocationDialog extends StatelessWidget {
  final Map<String, dynamic> driver;

  const DriverLocationDialog({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final location = driver['currentLocation'];

    return AlertDialog(
      title: Text('${driver['user']?['name']} - Yer'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Column(
          children: [
            if (location != null) ...[
              Text(
                location['address'] ?? 'Ünvan yoxdur',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: AppSizes.padding),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSizes.padding),
                      Text(
                        'Xəritə burada göstəriləcək',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Icon(
                Icons.location_off,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSizes.padding),
              Text(
                'Yer məlumatı yoxdur',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.close),
        ),
      ],
    );
  }
}

class DriverOrdersDialog extends StatelessWidget {
  final Map<String, dynamic> driver;

  const DriverOrdersDialog({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${driver['user']?['name']} - Sifarişlər'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            if (orderProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final driverOrders = orderProvider.orders
                .where((order) => order['driver']?['_id'] == driver['_id'])
                .toList();

            if (driverOrders.isEmpty) {
              return Center(
                child: Text(
                  'Sifariş yoxdur',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return ListView.builder(
              itemCount: driverOrders.length,
              itemBuilder: (context, index) {
                final order = driverOrders[index];
                return ListTile(
                  title: Text('Sifariş #${order['orderNumber']}'),
                  subtitle: Text(order['pickup']?['address'] ?? 'Ünvan yoxdur'),
                  trailing: Text('${order['fare']?['total'] ?? 0} ₼'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Show order details
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.close),
        ),
      ],
    );
  }
}
