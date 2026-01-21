import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kareebwala/core/services/local_storage_service.dart';
import 'package:kareebwala/features/booking/data/booking_service.dart';
import 'package:kareebwala/features/booking/domain/booking_model.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Map<String, dynamic>> _offlineBookings = [];

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  void _loadOfflineData() async {
    final data = await LocalStorageService().getLocalBookings();
    if (mounted) {
      setState(() {
        _offlineBookings = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("My Bookings")),
      body: StreamBuilder<List<Booking>>(
        stream: BookingService().getUserBookings(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (_offlineBookings.isNotEmpty) {
              return Column(
                children: [
                  Container(
                    color: Colors.redAccent,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text("Offline Mode: Showing saved history",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(child: _buildOfflineList()),
                ],
              );
            }
            return const Center(child: Text("No internet & No local records."));
          }

          final bookings = snapshot.data!;
          if (bookings.isEmpty)
            return const Center(child: Text("No booking history found."));

          for (var booking in bookings) {
            LocalStorageService().insertBooking(booking);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _buildBookingCard(
                title: bookings[index].serviceType,
                desc: bookings[index].description,
                price: bookings[index].price,
                status: bookings[index].status,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(
      {required String title,
      required String desc,
      required double price,
      required String status}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status),
          child: Icon(_getStatusIcon(status), color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text("Rs. ${price.toStringAsFixed(0)}",
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.w600)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(status.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(status))),
        ),
      ),
    );
  }

  Widget _buildOfflineList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _offlineBookings.length,
      itemBuilder: (context, index) {
        final item = _offlineBookings[index];
        return _buildBookingCard(
          title: item['serviceType'] ?? 'Unknown',
          desc: item['description'] ?? '',
          price: (item['price'] ?? 0.0).toDouble(),
          status: item['status'] ?? 'unknown',
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'accepted') return Colors.green;
    if (status == 'cancelled') return Colors.red;
    return Colors.orange;
  }

  IconData _getStatusIcon(String status) {
    if (status == 'cancelled') return Icons.close;
    if (status == 'accepted') return Icons.check;
    return Icons.history;
  }
}
