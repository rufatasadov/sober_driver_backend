import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../utils/constants.dart';

class BalanceManagementTab extends StatefulWidget {
  const BalanceManagementTab({super.key});

  @override
  State<BalanceManagementTab> createState() => _BalanceManagementTabState();
}

class _BalanceManagementTabState extends State<BalanceManagementTab> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String _selectedOperation = 'add';
  String? _selectedDriverId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDriversBalance();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sürücü Balans İdarəetmə',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Balance Update Form
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balans Yenilə',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Driver Selection
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedDriverId,
                              decoration: InputDecoration(
                                labelText: 'Sürücü seçin',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(Icons.person),
                              ),
                              items: adminProvider.driversBalance?.isNotEmpty ==
                                      true
                                  ? adminProvider.driversBalance!.map((driver) {
                                      return DropdownMenuItem<String>(
                                        value: driver['id'].toString(),
                                        child: Text(
                                            '${driver['name']} (${driver['licenseNumber']})'),
                                      );
                                    }).toList()
                                  : [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text(
                                          adminProvider.isLoading
                                              ? 'Yüklənir...'
                                              : 'Sürücü tapılmadı',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDriverId = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Operation Selection
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedOperation,
                              decoration: InputDecoration(
                                labelText: 'Əməliyyat',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'add',
                                  child: Text('Əlavə et'),
                                ),
                                DropdownMenuItem(
                                  value: 'subtract',
                                  child: Text('Çıx'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedOperation = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Amount Input
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              decoration: InputDecoration(
                                labelText: 'Məbləğ (₼)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(Icons.monetization_on),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Reason Input
                          Expanded(
                            child: TextFormField(
                              controller: _reasonController,
                              decoration: InputDecoration(
                                labelText: 'Səbəb (opsional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(Icons.note),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              adminProvider.isLoading ? null : _updateBalance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: adminProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Balansı Yenilə',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Drivers Balance List
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sürücü Balansları',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Debug info
                        if (adminProvider.error != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Xəta: ${adminProvider.error}',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        Text(
                          'Debug: driversBalance length = ${adminProvider.driversBalance?.length ?? 'null'}, isLoading = ${adminProvider.isLoading}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: adminProvider.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : adminProvider.driversBalance == null ||
                                      adminProvider.driversBalance!.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.person_off,
                                              size: 64, color: Colors.grey),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Sürücü tapılmadı',
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Verilənlər bazasında sürücü yoxdur və ya balans sütunu mövcud deyil',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount:
                                          adminProvider.driversBalance!.length,
                                      itemBuilder: (context, index) {
                                        final driver = adminProvider
                                            .driversBalance![index];
                                        return Card(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  AppColors.primary,
                                              child: Text(
                                                driver['name']
                                                        ?.substring(0, 1)
                                                        .toUpperCase() ??
                                                    '?',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              driver['name'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    'Lisenziya: ${driver['licenseNumber'] ?? 'N/A'}'),
                                                Text(
                                                    'Telefon: ${driver['phone'] ?? 'N/A'}'),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      driver['isOnline'] == true
                                                          ? Icons.circle
                                                          : Icons
                                                              .circle_outlined,
                                                      color:
                                                          driver['isOnline'] ==
                                                                  true
                                                              ? Colors.green
                                                              : Colors.grey,
                                                      size: 12,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      driver['isOnline'] == true
                                                          ? 'Online'
                                                          : 'Offline',
                                                      style: TextStyle(
                                                        color:
                                                            driver['isOnline'] ==
                                                                    true
                                                                ? Colors.green
                                                                : Colors.grey,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            trailing: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: AppColors.primary,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                '${driver['balance']?.toStringAsFixed(2) ?? '0.00'} ₼',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateBalance() async {
    if (_selectedDriverId == null) {
      _showSnackBar('Zəhmət olmasa sürücü seçin', isError: true);
      return;
    }

    if (_amountController.text.isEmpty) {
      _showSnackBar('Zəhmət olmasa məbləğ daxil edin', isError: true);
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('Düzgün məbləğ daxil edin', isError: true);
      return;
    }

    final success = await context.read<AdminProvider>().updateDriverBalance(
          _selectedDriverId!,
          amount,
          _selectedOperation,
          _reasonController.text,
        );

    if (success) {
      _showSnackBar('Balans uğurla yeniləndi');
      _amountController.clear();
      _reasonController.clear();
      setState(() {
        _selectedDriverId = null;
      });
    } else {
      _showSnackBar('Balans yeniləməkdə xəta baş verdi', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
