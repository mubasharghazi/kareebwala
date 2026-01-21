import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kareebwala/features/booking/data/booking_service.dart';
import 'package:kareebwala/features/booking/domain/booking_model.dart';
import 'package:kareebwala/features/booking/presentation/chat_screen.dart';

class TrackingScreen extends StatefulWidget {
  final String bookingId;
  const TrackingScreen({super.key, required this.bookingId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  static final LatLng _userLocation = const LatLng(31.4247, 74.2372);

  void _showCancelDialog() {
    String? selectedReason;
    final TextEditingController otherReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cancel Booking?"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Please select a reason for cancellation:"),
                  RadioListTile(
                    title: const Text("Provider is taking too long"),
                    value: "delay",
                    groupValue: selectedReason,
                    onChanged: (v) =>
                        setState(() => selectedReason = v.toString()),
                  ),
                  RadioListTile(
                    title: const Text("Changed my mind"),
                    value: "change",
                    groupValue: selectedReason,
                    onChanged: (v) =>
                        setState(() => selectedReason = v.toString()),
                  ),
                  RadioListTile(
                    title: const Text("Other"),
                    value: "other",
                    groupValue: selectedReason,
                    onChanged: (v) =>
                        setState(() => selectedReason = v.toString()),
                  ),
                  if (selectedReason == 'other')
                    TextField(
                      controller: otherReasonController,
                      decoration:
                          const InputDecoration(hintText: "Enter reason..."),
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                String finalReason = selectedReason == 'other'
                    ? otherReasonController.text
                    : (selectedReason ?? "");

                if (finalReason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Reason is required!")),
                  );
                  return;
                }

                await BookingService()
                    .cancelBooking(widget.bookingId, finalReason);

                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              child: const Text("Confirm Cancel",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch dialer")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Tracking")),
      body: StreamBuilder<Booking>(
        stream: BookingService().listenToBooking(widget.bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Booking not found/Cancelled"));
          }

          Booking booking = snapshot.data!;

          if (booking.status == 'cancelled') {
            return const Center(child: Text("This job was cancelled."));
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _userLocation,
                  zoom: 14.5,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('user'),
                    position: _userLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueCyan),
                  ),
                },
                onMapCreated: (controller) {
                  if (!_controller.isCompleted) {
                    _controller.complete(controller);
                  }
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _buildStatusDot("Accepted", true),
                          _buildStatusLine(true),
                          _buildStatusDot("Arriving", true),
                          _buildStatusLine(booking.status == 'completed'),
                          _buildStatusDot(
                              "Done", booking.status == 'completed'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FutureBuilder<Map<String, dynamic>?>(
                          future: BookingService()
                              .getProviderDetails(booking.providerId ?? ""),
                          builder: (context, providerSnap) {
                            String pName =
                                providerSnap.data?['name'] ?? "Provider";

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.teal,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                pName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Text(
                                "${booking.status.toUpperCase()} • 5 mins away",
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        Colors.blue.withOpacity(0.1),
                                    child: IconButton(
                                      icon: const Icon(Icons.message,
                                          color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => ChatScreen(
                                                    providerName: pName)));
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  CircleAvatar(
                                    backgroundColor:
                                        Colors.green.withOpacity(0.1),
                                    child: IconButton(
                                      icon: const Icon(Icons.call,
                                          color: Colors.green),
                                      onPressed: () =>
                                          _makePhoneCall("03001234567"),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      const SizedBox(height: 16),
                      if (booking.status != 'completed')
                        OutlinedButton(
                          onPressed: _showCancelDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text("Cancel Booking"),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusDot(String label, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor:
              isActive ? const Color(0xFF006A6A) : Colors.grey[300],
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: isActive ? Colors.black : Colors.grey)),
      ],
    );
  }

  Widget _buildStatusLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? const Color(0xFF006A6A) : Colors.grey[300],
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      ),
    );
  }
}
