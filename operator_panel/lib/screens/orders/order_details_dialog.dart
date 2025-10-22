import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_map/flutter_map.dart';
import '../../utils/constants.dart';
import '../../providers/order_provider.dart';
import '../../providers/driver_provider.dart';
import '../../widgets/map_widget.dart';

class OrderDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderDetailsDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sifariş #${order['orderNumber']}'),
      content: OrderEditorDialog(order: order),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.close),
        ),
      ],
    );
  }
}

class OrderEditorDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderEditorDialog({super.key, required this.order});

  @override
  State<OrderEditorDialog> createState() => _OrderEditorDialogState();
}

class _OrderEditorDialogState extends State<OrderEditorDialog> {
  late String _status;
  late TextEditingController _pickupController;
  late TextEditingController _destinationController;
  late TextEditingController _notesController;
  List<double>? _pickupLatLon;
  List<double>? _destLatLon;
  Map<String, dynamic>? _selectedDriver;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    _status = o['status'] ?? 'pending';
    _pickupController =
        TextEditingController(text: o['pickup']?['address'] ?? '');
    _destinationController =
        TextEditingController(text: o['destination']?['address'] ?? '');
    _notesController =
        TextEditingController(text: o['notes']?.toString() ?? '');
    final p = o['pickup']?['location']?['coordinates'];
    final d = o['destination']?['location']?['coordinates'];
    if (p is List && p.length >= 2) {
      _pickupLatLon = [(p[1] as num).toDouble(), (p[0] as num).toDouble()];
    }
    if (d is List && d.length >= 2) {
      _destLatLon = [(d[1] as num).toDouble(), (d[0] as num).toDouble()];
    }
    _selectedDriver = o['driver'] as Map<String, dynamic>?;
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final theme = Theme.of(context);
    final customer = order['customer'] as Map<String, dynamic>?;
    final paymentMethod =
        order['payment']?['method']?.toString().toUpperCase() ?? 'N/A';
    final fare = order['fare']?['total'];
    final fareText = fare == null
        ? '-'
        : (fare is num
            ? fare.toStringAsFixed(2)
            : (double.tryParse(fare.toString())?.toStringAsFixed(2) ?? '-'));

    return SizedBox(
      width: 860,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sifariş #${order['orderNumber'] ?? ''}',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(AppStrings.save),
                  ),
                ),
                Chip(label: Text(_statusText(_status))),
              ],
            ),
            const SizedBox(height: AppSizes.padding),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Status tarixçəsi',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSizes.padding),
                    ..._buildStatusTimeline(order),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.padding),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'pending', child: Text('Gözləyir')),
                          DropdownMenuItem(
                              value: 'accepted', child: Text('Qəbul edildi')),
                          DropdownMenuItem(
                              value: 'driver_assigned',
                              child: Text('Sürücü təyin')),
                          DropdownMenuItem(
                              value: 'driver_arrived',
                              child: Text('Sürücü gəldi')),
                          DropdownMenuItem(
                              value: 'in_progress', child: Text('Yoldadır')),
                          DropdownMenuItem(
                              value: 'completed', child: Text('Tamamlandı')),
                          DropdownMenuItem(
                              value: 'cancelled', child: Text('Ləğv edildi')),
                        ],
                        onChanged: (v) =>
                            setState(() => _status = v ?? _status),
                      ),
                    ),
                    const SizedBox(width: AppSizes.padding),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.person, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDriver != null
                                  ? (_selectedDriver!['user']?['name'] ??
                                      _selectedDriver!['name'] ??
                                      '')
                                  : 'Sürücü: təyin edilməyib',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingSmall),
                          TextButton.icon(
                            onPressed: _changeDriver,
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Sürücünü dəyiş'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.padding),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  children: [
                    _infoTile(Icons.person_outline, 'Müştəri',
                        customer?['name'] ?? 'N/A'),
                    const Divider(height: 16),
                    _infoTile(Icons.phone_outlined, 'Telefon',
                        customer?['phone'] ?? 'N/A'),
                    const Divider(height: 16),
                    _infoTile(Icons.payment, 'Ödəniş', paymentMethod),
                    const Divider(height: 16),
                    _infoTile(Icons.calendar_today_outlined, 'Yaradılma tarixi',
                        _formatDateTime(order['createdAt'])),
                    const Divider(height: 16),
                    _infoTile(Icons.schedule_outlined, 'Son yenilənmə',
                        _formatDateTime(order['updatedAt'])),
                    const Divider(height: 16),
                    _infoTile(Icons.attach_money, 'Qiymət', '$fareText ₼'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.padding),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Ünvanlar', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSizes.padding),
                    TextField(
                        controller: _pickupController,
                        decoration: const InputDecoration(
                            labelText: 'Götürülmə ünvanı')),
                    const SizedBox(height: AppSizes.padding),
                    TextField(
                        controller: _destinationController,
                        decoration:
                            const InputDecoration(labelText: 'Təyinat ünvanı')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.padding),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Marşrut', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSizes.padding),
                    SizedBox(
                      height: 300,
                      child: MapWidget(
                        center: _getMapCenter(),
                        zoom: 14.0,
                        markers: _getMapMarkers(),
                        polylines: _getPolylines(),
                        showLocationButton: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.padding),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Qeydlər'),
                  maxLines: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeDriver() async {
    final driver = await _showDriverPicker();
    if (driver != null) setState(() => _selectedDriver = driver);
  }

  Future<Map<String, dynamic>?> _showDriverPicker() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.loadDrivers();
    final drivers = driverProvider.drivers;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sürücü seçin'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final d = drivers[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(d['user']?['name'] ?? 'Ad yoxdur'),
                subtitle: Text(d['user']?['phone'] ?? ''),
                onTap: () => Navigator.of(context).pop(d),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppStrings.cancel))
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final orderId = widget.order['id'] ?? widget.order['_id'];
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      if (_selectedDriver != null) {
        final currentDriverId =
            widget.order['driver']?['id'] ?? widget.order['driverId'];
        if (_selectedDriver!['id'] != currentDriverId) {
          await orderProvider.assignDriver(orderId, _selectedDriver!['id']);
        }
      }
      final updates = <String, dynamic>{
        'status': _status,
        'pickup': {
          'address': _pickupController.text.trim(),
          if (_pickupLatLon != null)
            'coordinates': [_pickupLatLon![1], _pickupLatLon![0]],
        },
        'destination': {
          'address': _destinationController.text.trim(),
          if (_destLatLon != null)
            'coordinates': [_destLatLon![1], _destLatLon![0]],
        },
        'notes': _notesController.text.trim(),
      };
      await orderProvider.updateOrder(orderId, updates);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? 'Sifariş yenilənmədi' : message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Widget> _buildStatusTimeline(Map<String, dynamic> order) {
    final List<dynamic> timeline =
        order['timeline'] is List ? (order['timeline'] as List) : [];
    if (timeline.isEmpty) {
      return [
        _timelineTile('Yaradıldı', order['createdAt']),
        _timelineTile(_statusText(order['status'] ?? ''), order['updatedAt']),
      ];
    }
    return timeline.map((e) {
      final status = e['status']?.toString() ?? '';
      final ts = e['timestamp'];
      return _timelineTile(_statusText(status), ts);
    }).toList();
  }

  Widget _timelineTile(String title, dynamic timestamp) {
    final when = _formatDateTime(timestamp);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(when,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'Gözləyir';
      case 'accepted':
        return 'Qəbul edildi';
      case 'driver_assigned':
        return 'Sürücü təyin';
      case 'driver_arrived':
        return 'Sürücü gəldi';
      case 'in_progress':
        return 'Yoldadır';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'Ləğv edildi';
      default:
        return status;
    }
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return 'N/A';
    if (value is DateTime) {
      return DateFormat('dd.MM.yyyy HH:mm').format(value);
    }
    if (value is num) {
      final int ms =
          value < 1000000000000 ? (value * 1000).toInt() : value.toInt();
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateFormat('dd.MM.yyyy HH:mm').format(d);
    }
    final s = value.toString();
    final parsed = DateTime.tryParse(s);
    if (parsed == null) return 'N/A';
    return DateFormat('dd.MM.yyyy HH:mm').format(parsed);
  }

  latlong.LatLng _getMapCenter() {
    final order = widget.order;
    final pickup = order['pickup'];
    final destination = order['destination'];

    // Try to get coordinates from pickup or destination
    if (pickup != null &&
        pickup['location'] != null &&
        pickup['location']['coordinates'] != null) {
      final coords = pickup['location']['coordinates'];
      if (coords is List && coords.length >= 2) {
        return latlong.LatLng(
            (coords[1] as num).toDouble(), (coords[0] as num).toDouble());
      }
    }

    if (destination != null &&
        destination['location'] != null &&
        destination['location']['coordinates'] != null) {
      final coords = destination['location']['coordinates'];
      if (coords is List && coords.length >= 2) {
        return latlong.LatLng(
            (coords[1] as num).toDouble(), (coords[0] as num).toDouble());
      }
    }

    // Default to Baku center
    return const latlong.LatLng(40.3777, 49.8516);
  }

  List<MapMarker> _getMapMarkers() {
    final markers = <MapMarker>[];
    final order = widget.order;

    // Pickup marker
    final pickup = order['pickup'];
    if (pickup != null &&
        pickup['location'] != null &&
        pickup['location']['coordinates'] != null) {
      final coords = pickup['location']['coordinates'];
      if (coords is List && coords.length >= 2) {
        markers.add(
          MapMarker(
            point: latlong.LatLng(
              (coords[1] as num).toDouble(),
              (coords[0] as num).toDouble(),
            ),
            widget: const PickupMarker(),
          ),
        );
      }
    }

    // Destination marker
    final destination = order['destination'];
    if (destination != null &&
        destination['location'] != null &&
        destination['location']['coordinates'] != null) {
      final coords = destination['location']['coordinates'];
      if (coords is List && coords.length >= 2) {
        markers.add(
          MapMarker(
            point: latlong.LatLng(
              (coords[1] as num).toDouble(),
              (coords[0] as num).toDouble(),
            ),
            widget: const DestinationMarker(),
          ),
        );
      }
    }

    return markers;
  }

  List<Polyline> _getPolylines() {
    final order = widget.order;
    final pickup = order['pickup'];
    final destination = order['destination'];

    // Create route line between pickup and destination
    if (pickup != null &&
        pickup['location'] != null &&
        pickup['location']['coordinates'] != null &&
        destination != null &&
        destination['location'] != null &&
        destination['location']['coordinates'] != null) {
      final pickupCoords = pickup['location']['coordinates'];
      final destCoords = destination['location']['coordinates'];

      if (pickupCoords is List &&
          pickupCoords.length >= 2 &&
          destCoords is List &&
          destCoords.length >= 2) {
        return [
          Polyline(
            points: [
              latlong.LatLng(
                (pickupCoords[1] as num).toDouble(),
                (pickupCoords[0] as num).toDouble(),
              ),
              latlong.LatLng(
                (destCoords[1] as num).toDouble(),
                (destCoords[0] as num).toDouble(),
              ),
            ],
            strokeWidth: 3.0,
            color: AppColors.primary,
          ),
        ];
      }
    }

    return [];
  }
}
