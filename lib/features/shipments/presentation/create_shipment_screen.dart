import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/peleka_button.dart';
import '../../../core/widgets/peleka_card.dart';
import '../../../core/widgets/peleka_text_field.dart';
import '../data/location_repository.dart';
import '../data/shipment_repository.dart';
import 'shipments_view_model.dart';

class CreateShipmentScreen extends ConsumerStatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  ConsumerState<CreateShipmentScreen> createState() =>
      _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends ConsumerState<CreateShipmentScreen> {
  int _step = 0;
  bool _loading = false;
  bool _locating = false;

  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  final _pickupAddressController = TextEditingController();
  final _pickupNotesController = TextEditingController();

  final _deliveryAddressController = TextEditingController();
  final _deliveryNotesController = TextEditingController();

  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();

  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();

  final _descriptionController = TextEditingController();

  Map<String, dynamic>? _pickupPlace;
  Map<String, dynamic>? _deliveryPlace;

  List<PlaceResult> _pickupResults = <PlaceResult>[];
  List<PlaceResult> _deliveryResults = <PlaceResult>[];

  bool _pickupSearching = false;
  bool _deliverySearching = false;

  double? _currentLat;
  double? _currentLng;

  String _category = 'documents';
  bool _fragile = false;

  Timer? _pickupSearchTimer;
  Timer? _deliverySearchTimer;

  @override
  void initState() {
    super.initState();

    final draft = ref.read(draftProvider);

    if (draft.parcelCategory.isNotEmpty) {
      _category = draft.parcelCategory;
    }
  }

  @override
  void dispose() {
    _pickupSearchTimer?.cancel();
    _deliverySearchTimer?.cancel();

    _pickupAddressController.dispose();
    _pickupNotesController.dispose();

    _deliveryAddressController.dispose();
    _deliveryNotesController.dispose();

    _recipientNameController.dispose();
    _recipientPhoneController.dispose();

    _senderNameController.dispose();
    _senderPhoneController.dispose();

    _descriptionController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // PICKUP LOCATION SEARCH
  // ---------------------------------------------------------------------------

  Future<void> _searchPickup(String query) async {
    _pickupSearchTimer?.cancel();

    final q = query.trim();

    if (q.length < 2) {
      if (mounted) {
        setState(() {
          _pickupResults = <PlaceResult>[];
          _pickupSearching = false;
        });
      }
      return;
    }

    _pickupSearchTimer = Timer(
      const Duration(milliseconds: 450),
      () async {
        if (!mounted) return;

        setState(() {
          _pickupSearching = true;
        });

        try {
          final results = await ref.read(locationRepositoryProvider).search(
                q,
                lat: _currentLat,
                lng: _currentLng,
              );

          if (!mounted) return;

          setState(() {
            _pickupResults = results;
          });
        } catch (e) {
          if (!mounted) return;

          _showError(
            e.toString().replaceAll('ApiException: ', ''),
          );
        } finally {
          if (!mounted) return;

          setState(() {
            _pickupSearching = false;
          });
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DELIVERY LOCATION SEARCH
  // ---------------------------------------------------------------------------

  Future<void> _searchDelivery(String query) async {
    _deliverySearchTimer?.cancel();

    final q = query.trim();

    if (q.length < 2) {
      if (mounted) {
        setState(() {
          _deliveryResults = <PlaceResult>[];
          _deliverySearching = false;
        });
      }
      return;
    }

    _deliverySearchTimer = Timer(
      const Duration(milliseconds: 450),
      () async {
        if (!mounted) return;

        setState(() {
          _deliverySearching = true;
        });

        try {
          final results = await ref.read(locationRepositoryProvider).search(
                q,
                lat: _currentLat,
                lng: _currentLng,
              );

          if (!mounted) return;

          setState(() {
            _deliveryResults = results;
          });
        } catch (e) {
          if (!mounted) return;

          _showError(
            e.toString().replaceAll('ApiException: ', ''),
          );
        } finally {
          if (!mounted) return;

          setState(() {
            _deliverySearching = false;
          });
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // USE CURRENT LOCATION
  // ---------------------------------------------------------------------------

  Future<void> _useCurrentPickup() async {
    if (_locating) return;

    setState(() {
      _locating = true;
    });

    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required to use your current location.',
        );
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Turn on location services and try again.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLat = position.latitude;
      _currentLng = position.longitude;

      final place = await ref.read(locationRepositoryProvider).reverse(
            position.latitude,
            position.longitude,
          );

      if (!mounted) return;

      if (place != null) {
        setState(() {
          _pickupPlace = place.toMap();

          _pickupAddressController.text =
              place.address.isNotEmpty ? place.address : place.name;

          _pickupResults = <PlaceResult>[];
        });
      } else {
        setState(() {
          _pickupPlace = {
            'name': 'Current location',
            'address': 'Current location',
            'lat': position.latitude,
            'lng': position.longitude,
          };

          _pickupAddressController.text = 'Current location';

          _pickupResults = <PlaceResult>[];
        });
      }
    } catch (e) {
      if (!mounted) return;

      _showError(
        e.toString().replaceAll('ApiException: ', ''),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _locating = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // SELECT LOCATION
  // ---------------------------------------------------------------------------

  void _selectPickup(PlaceResult place) {
    setState(() {
      _pickupPlace = place.toMap();

      _pickupAddressController.text =
          place.address.isNotEmpty ? place.address : place.name;

      _pickupResults = <PlaceResult>[];
    });
  }

  void _selectDelivery(PlaceResult place) {
    setState(() {
      _deliveryPlace = place.toMap();

      _deliveryAddressController.text =
          place.address.isNotEmpty ? place.address : place.name;

      _deliveryResults = <PlaceResult>[];
    });
  }

  // ---------------------------------------------------------------------------
  // STEP NAVIGATION
  // ---------------------------------------------------------------------------

  Future<void> _next() async {
    final form = _formKeys[_step].currentState;

    if (form == null || !form.validate()) {
      return;
    }

    if (_step == 0 && _pickupPlace == null) {
      _showError(
        'Search for a pickup place or use your current location.',
      );
      return;
    }

    if (_step == 1 && _deliveryPlace == null) {
      _showError(
        'Search for a delivery place.',
      );
      return;
    }

    if (_step < 2) {
      setState(() {
        _step++;
      });

      return;
    }

    await _getQuote();
  }

  // ---------------------------------------------------------------------------
  // REQUEST QUOTE
  // ---------------------------------------------------------------------------

  Future<void> _getQuote() async {
    if (_pickupPlace == null || _deliveryPlace == null) {
      _showError('Please select both pickup and delivery locations.');
      return;
    }

    final pickupLat = _pickupPlace!['lat'];
    final pickupLng = _pickupPlace!['lng'];

    final deliveryLat = _deliveryPlace!['lat'];
    final deliveryLng = _deliveryPlace!['lng'];

    if (pickupLat == null ||
        pickupLng == null ||
        deliveryLat == null ||
        deliveryLng == null) {
      _showError(
        'The selected locations do not have valid coordinates.',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final quote = await ref.read(shipmentRepositoryProvider).quote(
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            deliveryLat: deliveryLat,
            deliveryLng: deliveryLng,
          );

      final draft = CreateShipmentDraft()
        ..pickupLat = pickupLat
        ..pickupLng = pickupLng
        ..pickupAddress = _pickupAddressController.text.trim()
        ..pickupNotes = _pickupNotesController.text.trim()
        ..deliveryLat = deliveryLat
        ..deliveryLng = deliveryLng
        ..deliveryAddress = _deliveryAddressController.text.trim()
        ..deliveryNotes = _deliveryNotesController.text.trim()
        ..senderName = _senderNameController.text.trim()
        ..senderPhone = _senderPhoneController.text.trim()
        ..recipientName = _recipientNameController.text.trim()
        ..recipientPhone = _recipientPhoneController.text.trim()
        ..parcelDescription = _descriptionController.text.trim()
        ..parcelCategory = _category
        ..isFragile = _fragile
        ..quote = quote;

      ref.read(draftProvider.notifier).state = draft;

      if (!mounted) return;

      context.push('/shipments/quote');
    } catch (e) {
      if (!mounted) return;

      _showError(
        e.toString().replaceAll('ApiException: ', ''),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // ERROR MESSAGE
  // ---------------------------------------------------------------------------

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 0) {
              context.pop();
            } else {
              setState(() {
                _step--;
              });
            }
          },
        ),
        title: Text(
          'New delivery · ${_step + 1}/3',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                children: List.generate(
                  3,
                  (index) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: index < 2 ? 8 : 0,
                        ),
                        height: 6,
                        decoration: BoxDecoration(
                          color: index <= _step
                              ? AppColors.orange
                              : AppColors.ink200,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKeys[_step],
                  child: [
                    _pickup(),
                    _delivery(),
                    _parcel(),
                  ][_step],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: PelekaButton(
                label: _step == 2 ? 'Review price' : 'Continue',
                icon:
                    _step == 2 ? Icons.calculate_outlined : Icons.arrow_forward,
                loading: _loading,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PICKUP STEP
  // ---------------------------------------------------------------------------

  Widget _pickup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup location',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Search for a place or use your current location.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.ink500,
          ),
        ),
        const SizedBox(height: 18),
        PelekaButton(
          label:
              _locating ? 'Finding your location…' : 'Use my current location',
          icon: Icons.my_location,
          outlined: true,
          loading: _locating,
          onPressed: _locating ? null : _useCurrentPickup,
        ),
        const SizedBox(height: 16),
        PelekaTextField(
          label: 'Search pickup place',
          hint: 'Business, hotel, school, market, street…',
          controller: _pickupAddressController,
          prefixIcon: Icons.search_outlined,
          onChanged: _searchPickup,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Pickup location required';
            }

            return null;
          },
        ),
        if (_pickupSearching)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.orange,
              ),
            ),
          ),
        if (_pickupResults.isNotEmpty)
          _results(
            _pickupResults,
            _selectPickup,
          ),
        const SizedBox(height: 12),
        PelekaTextField(
          label: 'Notes for rider (optional)',
          hint: 'Gate code, floor, landmarks…',
          controller: _pickupNotesController,
          maxLines: 3,
          prefixIcon: Icons.sticky_note_2_outlined,
        ),
        const SizedBox(height: 16),
        if (_pickupPlace != null)
          PelekaCard(
            color: AppColors.blueLight,
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pickup selected at '
                    '${_pickupPlace!['lat']?.toStringAsFixed(5)}, '
                    '${_pickupPlace!['lng']?.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DELIVERY STEP
  // ---------------------------------------------------------------------------

  Widget _delivery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery location',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Search for the recipient location.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.ink500,
          ),
        ),
        const SizedBox(height: 18),
        PelekaTextField(
          label: 'Search delivery place',
          hint: 'Business, hotel, school, market, street…',
          controller: _deliveryAddressController,
          prefixIcon: Icons.search_outlined,
          onChanged: _searchDelivery,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Delivery location required';
            }

            return null;
          },
        ),
        if (_deliverySearching)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.orange,
              ),
            ),
          ),
        if (_deliveryResults.isNotEmpty)
          _results(
            _deliveryResults,
            _selectDelivery,
          ),
        const SizedBox(height: 12),
        PelekaTextField(
          label: 'Recipient name',
          hint: 'Full name of the person receiving',
          controller: _recipientNameController,
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.trim().length < 2) {
              return 'Required';
            }

            return null;
          },
        ),
        const SizedBox(height: 14),
        PelekaTextField(
          label: 'Recipient phone',
          hint: '+2507XX XXX XXX',
          controller: _recipientPhoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().length < 6) {
              return 'Required';
            }

            return null;
          },
        ),
        const SizedBox(height: 14),
        PelekaTextField(
          label: 'Delivery notes (optional)',
          hint: 'Gate, floor, landmark…',
          controller: _deliveryNotesController,
          maxLines: 3,
          prefixIcon: Icons.sticky_note_2_outlined,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LOCATION RESULTS
  // ---------------------------------------------------------------------------

  Widget _results(
    List<PlaceResult> places,
    void Function(PlaceResult) onTap,
  ) {
    final List<Widget> items = <Widget>[];

    for (final place in places.take(5)) {
      items.add(
        InkWell(
          onTap: () => onTap(place),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        place.address,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.ink500,
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

    return PelekaCard(
      child: Column(
        children: items,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PARCEL STEP
  // ---------------------------------------------------------------------------

  Widget _parcel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Parcel details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 20),
        PelekaTextField(
          label: 'Sender name',
          hint: 'Your full name',
          controller: _senderNameController,
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.trim().length < 2) {
              return 'Required';
            }

            return null;
          },
        ),
        const SizedBox(height: 14),
        PelekaTextField(
          label: 'Sender phone',
          hint: '+2507XX XXX XXX',
          controller: _senderPhoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().length < 6) {
              return 'Required';
            }

            return null;
          },
        ),
        const SizedBox(height: 14),
        PelekaTextField(
          label: 'Parcel description',
          hint: 'e.g. Documents, shoes, electronics',
          controller: _descriptionController,
          prefixIcon: Icons.inventory_2_outlined,
          validator: (value) {
            if (value == null || value.trim().length < 2) {
              return 'Required';
            }

            return null;
          },
        ),
        const SizedBox(height: 14),
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: const InputDecoration(),
          items: const [
            'documents',
            'clothing',
            'electronics',
            'food',
            'fragile',
            'other',
          ].map(
            (value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value[0].toUpperCase() + value.substring(1),
                ),
              );
            },
          ).toList(),
          onChanged: (value) {
            setState(() {
              _category = value ?? 'other';
            });
          },
        ),
        const SizedBox(height: 12),
        _toggle(
          'Fragile parcel',
          'Handle with extra care',
          _fragile,
          (value) {
            setState(() {
              _fragile = value;
            });
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TOGGLE
  // ---------------------------------------------------------------------------

  Widget _toggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return PelekaCard(
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.ink500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.orange,
          ),
        ],
      ),
    );
  }
}
