import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../orders/presentation/cubit/orders_cubit.dart';

class HomeState extends Equatable {
  final String? pickupAddress;
  final List<double>? pickupCoordinates; // [lng, lat]
  final String? destinationAddress;
  final List<double>? destinationCoordinates; // [lng, lat]
  final bool isSearchingDriver;
  final UserModel? driver;
  final int? etaMinutes;
  final List<double>? driverCoordinates; // [lng, lat]
  final int searchSecondsLeft; // countdown in seconds
  final bool searchRejected;

  const HomeState({
    this.pickupAddress,
    this.pickupCoordinates,
    this.destinationAddress,
    this.destinationCoordinates,
    this.isSearchingDriver = false,
    this.driver,
    this.etaMinutes,
    this.driverCoordinates,
    this.searchSecondsLeft = 0,
    this.searchRejected = false,
  });

  HomeState copyWith({
    String? pickupAddress,
    List<double>? pickupCoordinates,
    String? destinationAddress,
    List<double>? destinationCoordinates,
    bool? isSearchingDriver,
    UserModel? driver,
    int? etaMinutes,
    List<double>? driverCoordinates,
    int? searchSecondsLeft,
    bool? searchRejected,
  }) {
    return HomeState(
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupCoordinates: pickupCoordinates ?? this.pickupCoordinates,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationCoordinates: destinationCoordinates ?? this.destinationCoordinates,
      isSearchingDriver: isSearchingDriver ?? this.isSearchingDriver,
      driver: driver ?? this.driver,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      driverCoordinates: driverCoordinates ?? this.driverCoordinates,
      searchSecondsLeft: searchSecondsLeft ?? this.searchSecondsLeft,
      searchRejected: searchRejected ?? this.searchRejected,
    );
  }

  @override
  List<Object?> get props => [
    pickupAddress,
    pickupCoordinates,
    destinationAddress,
    destinationCoordinates,
    isSearchingDriver,
    driver,
    etaMinutes,
    driverCoordinates,
    searchSecondsLeft,
    searchRejected,
  ];
}

class HomeCubit extends Cubit<HomeState> {
  final OrdersCubit ordersCubit;
  final LocationService _locationService = LocationService();
  StreamSubscription? _orderAcceptedSubscription;
  StreamSubscription? _orderRejectedSubscription;
  StreamSubscription? _driverLocationSubscription;
  Timer? _searchTimer;

  HomeCubit({required this.ordersCubit}) : super(const HomeState());

  Future<void> setPickupToCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position == null) return;
    final placemarks = await _locationService.getAddressFromCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    final address = placemarks != null && placemarks.isNotEmpty
        ? _locationService.formatAddress(placemarks.first)
        : 'Cari yer';
    emit(state.copyWith(
      pickupAddress: address,
      pickupCoordinates: [position.longitude, position.latitude],
    ));
  }

  void setDestination(String address, {List<double>? coordinates}) {
    emit(state.copyWith(
      destinationAddress: address,
      destinationCoordinates: coordinates,
    ));
  }

  Future<void> onMapTapSetDestination({required double latitude, required double longitude}) async {
    final placemarks = await _locationService.getAddressFromCoordinates(
      latitude: latitude,
      longitude: longitude,
    );
    final address = placemarks != null && placemarks.isNotEmpty
        ? _locationService.formatAddress(placemarks.first)
        : 'Seçilmiş məkan';
    setDestination(address, coordinates: [longitude, latitude]);
  }

  Future<void> requestRide() async {
    if (state.pickupAddress == null || state.destinationAddress == null) return;
    emit(state.copyWith(isSearchingDriver: true, driver: null, searchRejected: false));

    // Create order (uses mock in test mode)
    await ordersCubit.createOrder(
      pickup: {
        'address': state.pickupAddress,
        'coordinates': state.pickupCoordinates ?? [],
      },
      destination: {
        'address': state.destinationAddress,
        'coordinates': state.destinationCoordinates ?? [],
      },
      paymentMethod: 'cash',
    );

    // Listen for driver assignment via socket, fallback to mock after delay in test mode
    _orderAcceptedSubscription?.cancel();
    _orderAcceptedSubscription = SocketService().orderAcceptedStream.listen((data) {
      final driverJson = data['driver'] as Map<String, dynamic>?;
      if (driverJson != null) {
        final driver = UserModel.fromJson(driverJson);
        emit(state.copyWith(isSearchingDriver: false, driver: driver, etaMinutes: data['eta'] ?? 5));
        _stopSearchTimer();
      }
    });

    _orderRejectedSubscription?.cancel();
    _orderRejectedSubscription = SocketService().orderRejectedStream.listen((data) {
      emit(state.copyWith(isSearchingDriver: false, searchRejected: true));
      _stopSearchTimer();
    });

    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = SocketService().driverLocationStream.listen((data) {
      // expect { orderId, lat, lng }
      final lat = (data['lat'] ?? data['latitude'])?.toDouble();
      final lng = (data['lng'] ?? data['longitude'])?.toDouble();
      if (lat != null && lng != null) {
        emit(state.copyWith(driverCoordinates: [lng, lat]));
      }
    });

    _startSearchTimer(seconds: 300); // 5 minutes

    // Test-mode fallback: mock driver after short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (state.isSearchingDriver) {
        final mockDriver = UserModel(
          id: 'driver-1',
          name: 'Kamran Məmmədov',
          phone: '+994501112233',
          role: 'driver',
          isVerified: true,
          isActive: true,
          createdAt: DateTime.now(),
          averageRating: 4.8,
          ratingCount: 132,
          vehicleMake: 'Toyota',
          vehicleModel: 'Prius',
          vehiclePlate: '90-AB-123',
        );
        emit(state.copyWith(isSearchingDriver: false, driver: mockDriver, etaMinutes: 4));
        _stopSearchTimer();
      }
    });
  }

  void retrySearch() {
    emit(state.copyWith(searchRejected: false));
    requestRide();
  }

  void _startSearchTimer({required int seconds}) {
    _searchTimer?.cancel();
    emit(state.copyWith(searchSecondsLeft: seconds));
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = state.searchSecondsLeft - 1;
      if (next <= 0 || !state.isSearchingDriver) {
        _stopSearchTimer();
        if (state.isSearchingDriver) {
          // timeout -> consider as rejected
          emit(state.copyWith(isSearchingDriver: false, searchRejected: true));
        }
      } else {
        emit(state.copyWith(searchSecondsLeft: next));
      }
    });
  }

  void _stopSearchTimer() {
    _searchTimer?.cancel();
    _searchTimer = null;
  }

  @override
  Future<void> close() {
    _orderAcceptedSubscription?.cancel();
    _orderRejectedSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    _searchTimer?.cancel();
    return super.close();
  }
}


