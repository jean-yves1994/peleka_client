import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Kigali {
  static const String name = 'Kigali';
  static const String currency = 'RWF';
  static const String countryCode = '+250';
  static const LatLng center = LatLng(-1.9441, 30.0619);
  static const List<Map<String, dynamic>> neighborhoods = [
    {'name': 'Nyarugenge, City Center', 'lat': -1.9536, 'lng': 30.0606},
    {'name': 'Kimironko', 'lat': -1.9370, 'lng': 30.1230},
    {'name': 'Kacyiru', 'lat': -1.9200, 'lng': 30.0800},
    {'name': 'Nyamirambo', 'lat': -1.9800, 'lng': 30.0400},
    {'name': 'Remera', 'lat': -1.9560, 'lng': 30.1085},
    {'name': 'Gikondo', 'lat': -1.9750, 'lng': 30.0800},
    {'name': 'Kanombe', 'lat': -1.9680, 'lng': 30.1330},
    {'name': 'Kibagabaga', 'lat': -1.9130, 'lng': 30.1130},
    {'name': 'Kicukiro', 'lat': -1.9820, 'lng': 30.1000},
    {'name': 'Gacuriro', 'lat': -1.9250, 'lng': 30.0930},
  ];
}
class ParcelCategory {
  final String id; final String label; final IconData icon;
  const ParcelCategory(this.id, this.label, this.icon);
}
class ParcelCategories {
  static const List<ParcelCategory> all = [
    ParcelCategory('documents', 'Documents', Icons.description_outlined),
    ParcelCategory('food', 'Food', Icons.restaurant_outlined),
    ParcelCategory('electronics', 'Electronics', Icons.devices_other_outlined),
    ParcelCategory('medical', 'Medical', Icons.medical_services_outlined),
    ParcelCategory('clothing', 'Clothing', Icons.checkroom_outlined),
    ParcelCategory('gifts', 'Gifts', Icons.card_giftcard_outlined),
    ParcelCategory('other', 'Other', Icons.inventory_2_outlined),
  ];
}
