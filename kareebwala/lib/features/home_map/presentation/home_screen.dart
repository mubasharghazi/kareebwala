import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kareebwala/features/auth/data/auth_repository.dart';
import 'package:kareebwala/features/auth/presentation/login_screen.dart';
import 'package:kareebwala/features/auth/presentation/profile_screen.dart';
import 'package:kareebwala/features/booking/presentation/service_request_screen.dart';
import 'package:kareebwala/features/booking/presentation/my_bookings_screen.dart'; // IMPORTED

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _locationController = TextEditingController();

  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(31.4247, 74.2372),
    zoom: 14.4746,
  );

  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      _updateMapLocation(
          LatLng(position.latitude, position.longitude), "Current Location");
    } catch (e) {
      print("Location Error: $e");
      _updateMapLocation(const LatLng(31.4247, 74.2372), "Default Location");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchLocation() async {
    String address = _locationController.text.trim();
    if (address.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("No location found")));
      } else if (locations.length == 1) {
        Location loc = locations.first;
        _updateMapLocation(LatLng(loc.latitude, loc.longitude), address);
      } else {
        if (mounted) _showLocationSelectionSheet(locations, address);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLocationSelectionSheet(List<Location> locations, String query) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select Location for '$query'",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: locations.length > 5 ? 5 : locations.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final loc = locations[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on,
                          color: Color(0xFF007AFF)),
                      title: Text("$query (Result ${index + 1})"),
                      subtitle: Text(
                          "Lat: ${loc.latitude.toStringAsFixed(4)}, Lng: ${loc.longitude.toStringAsFixed(4)}"),
                      onTap: () {
                        Navigator.pop(context);
                        _updateMapLocation(
                            LatLng(loc.latitude, loc.longitude), query);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateMapLocation(LatLng pos, String title) async {
    if (!mounted) return;
    setState(() {
      _currentPosition = pos;
      _isLoading = false;
      _markers = {
        Marker(
          markerId: const MarkerId('selected-loc'),
          position: pos,
          infoWindow: InfoWindow(title: title),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        )
      };
    });
    final controller = await _controller.future;
    controller.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 16)));
  }

  void _navigateToRequest(String serviceType) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ServiceRequestScreen(serviceType: serviceType)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kDefaultLocation,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            onMapCreated: (c) => _controller.complete(c),
          ),
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black87),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.search, color: Color(0xFF007AFF)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _locationController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchLocation(),
                            decoration: const InputDecoration(
                              hintText: "Search location...",
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.grey),
                          onPressed: _searchLocation,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("How can we help?",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildServiceItem(Icons.car_repair, "Mechanic"),
                      _buildServiceItem(
                          Icons.electrical_services, "Electrician"),
                      _buildServiceItem(Icons.plumbing, "Plumber"),
                      _buildServiceItem(Icons.grid_view_rounded, "More"),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _navigateToRequest("General Emergency"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      shadowColor: const Color(0xFFD32F2F).withOpacity(0.4),
                      elevation: 8,
                    ),
                    child: const Text("EMERGENCY SOS",
                        style: TextStyle(
                            letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildServiceItem(IconData icon, String label) {
    return GestureDetector(
      onTap: () => _navigateToRequest(label),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: const Color(0xFF007AFF), size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF005844)),
            accountName: Text(user?.displayName ?? "User",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(user?.email ?? ""),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.displayName ?? "U")[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 28,
                    color: Color(0xFF005844),
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Profile"),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("My Bookings"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (mounted)
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
