import 'package:flutter/material.dart';
import 'package:kareebwala/features/booking/data/booking_service.dart';
import 'package:kareebwala/features/booking/domain/booking_model.dart';
import 'package:kareebwala/features/booking/presentation/tracking_screen.dart';

class SearchingScreen extends StatefulWidget {
  final String bookingId;
  const SearchingScreen({super.key, required this.bookingId});

  @override
  State<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends State<SearchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<Booking>(
        stream: BookingService().listenToBooking(widget.bookingId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.status == 'accepted') {
            Future.microtask(() {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrackingScreen(bookingId: widget.bookingId),
                  ),
                );
              }
            });
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: RadarPainter(_controller),
                child: Container(width: 400, height: 400),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF006A6A),
                    child: Icon(Icons.search, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Finding Nearest Provider...",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Connecting to mechanics nearby...",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 50),
                  OutlinedButton(
                    onPressed: () async {
                      String? reason = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          TextEditingController reasonController =
                              TextEditingController();
                          return AlertDialog(
                            title: const Text("Cancel Request?"),
                            content: TextField(
                              controller: reasonController,
                              decoration: const InputDecoration(
                                hintText: "Reason (e.g. Changed mind)",
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("No"),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, reasonController.text),
                                child: const Text("Yes, Cancel"),
                              ),
                            ],
                          );
                        },
                      );

                      if (reason != null) {
                        String finalReason =
                            reason.isEmpty ? "Changed mind" : reason;

                        await BookingService()
                            .cancelBooking(widget.bookingId, finalReason);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Request Cancelled")),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    child: const Text("Cancel Search"),
                  )
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final Animation<double> animation;
  RadarPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF006A6A).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      double radius = (animation.value * 150) + (i * 40);
      double opacity = 1.0 - (animation.value + (i * 0.2)) % 1.0;

      if (radius > 200) radius -= 200;

      paint.color =
          const Color(0xFF006A6A).withOpacity(opacity.clamp(0.0, 1.0));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
