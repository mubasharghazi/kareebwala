import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kareebwala/features/booking/data/booking_service.dart';
import 'package:kareebwala/features/booking/domain/booking_model.dart';
import 'package:kareebwala/features/booking/presentation/searching_screen.dart';

class ServiceRequestScreen extends StatefulWidget {
  final String serviceType;
  const ServiceRequestScreen({super.key, required this.serviceType});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _descController = TextEditingController();
  bool _isLoading = false;
  double _estimatedPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _calculatePrice();
  }

  void _calculatePrice() {
    if (widget.serviceType == "Mechanic")
      _estimatedPrice = 1000.0;
    else if (widget.serviceType == "Electrician")
      _estimatedPrice = 800.0;
    else if (widget.serviceType == "Plumber")
      _estimatedPrice = 700.0;
    else
      _estimatedPrice = 500.0;
  }

  void _submitRequest() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please describe the issue")));
      return;
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Request"),
        content: Text(
            "Service: ${widget.serviceType}\nEst. Price: Rs. $_estimatedPrice\n\nProceed to find provider?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Confirm")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Booking newBooking = Booking(
        id: '',
        userId: user.uid,
        userName: user.displayName ?? "Client",
        serviceType: widget.serviceType,
        description: _descController.text.trim(),
        status: 'searching',
        lat: 31.4247,
        lng: 74.2372,
        price: _estimatedPrice,
      );

      String bookingId = await BookingService().createBooking(newBooking);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => SearchingScreen(bookingId: bookingId)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Request ${widget.serviceType}")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.price_check, color: Colors.green, size: 30),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Estimated Price",
                          style: TextStyle(color: Colors.black54)),
                      Text("Rs. ${_estimatedPrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text("Describe Issue:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "E.g. Car not starting...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A6A),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("FIND PROVIDER",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
