import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kareebwala/features/auth/data/auth_repository.dart';
import 'package:kareebwala/features/auth/presentation/login_screen.dart';
import 'package:kareebwala/features/booking/data/booking_service.dart';
import 'package:kareebwala/features/booking/domain/booking_model.dart';

class ProviderDashboard extends ConsumerStatefulWidget {
  const ProviderDashboard({super.key});

  @override
  ConsumerState<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends ConsumerState<ProviderDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0
            ? "New Requests"
            : _currentIndex == 1
                ? "Active Job"
                : "Profile"),
        backgroundColor: const Color(0xFF005844),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF005844),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Requests"),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: "Active Job"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Error: No User"));

    switch (_currentIndex) {
      case 0:
        return StreamBuilder<List<Booking>>(
          stream: BookingService().getPendingBookings(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            var requests = snapshot.data!;
            if (requests.isEmpty)
              return const Center(child: Text("No new requests nearby."));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) =>
                  _buildRequestCard(requests[index], user.uid),
            );
          },
        );

      case 1:
        return StreamBuilder<List<Booking>>(
          stream: BookingService().getProviderActiveJob(user.uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            var activeJobs = snapshot.data!;
            if (activeJobs.isEmpty)
              return const Center(
                  child: Text("No active jobs. Accept one first!"));

            return _buildActiveJobCard(activeJobs.first);
          },
        );

      case 2:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 50, color: Colors.white)),
              const SizedBox(height: 20),
              Text(user.email ?? "", style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (mounted)
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (r) => false);
                },
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
              )
            ],
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildRequestCard(Booking request, String providerId) {
    double distanceInMeters =
        Geolocator.distanceBetween(31.4280, 74.2400, request.lat, request.lng);
    double distanceInKm = distanceInMeters / 1000;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(request.serviceType,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Rs. ${request.price.toStringAsFixed(0)}",
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Text("Client: ${request.userName}"),
            Text("Issue: ${request.description}"),
            const SizedBox(height: 8),
            Text("${distanceInKm.toStringAsFixed(1)} km away",
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await BookingService().acceptBooking(request.id, providerId);
                  setState(() => _currentIndex = 1);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005844),
                    foregroundColor: Colors.white),
                child: const Text("ACCEPT JOB"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActiveJobCard(Booking job) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green)),
            child: Row(children: [
              const Icon(Icons.run_circle, size: 40, color: Colors.green),
              const SizedBox(width: 16),
              const Expanded(
                  child: Text("Job In Progress",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green))),
            ]),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              title: Text(job.serviceType,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  Text("Client: ${job.userName}\nIssue: ${job.description}"),
              trailing: IconButton(
                  icon: const Icon(Icons.map, color: Colors.blue),
                  onPressed: () {}),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () async {
              await BookingService().completeBooking(job.id);
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Job Completed! Cash Collected.")));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50)),
            child: const Text("MARK AS COMPLETED"),
          )
        ],
      ),
    );
  }
}
