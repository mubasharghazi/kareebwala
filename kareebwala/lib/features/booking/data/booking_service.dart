import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kareebwala/features/booking/domain/booking_model.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createBooking(Booking booking) async {
    try {
      DocumentReference docRef = _db.collection('bookings').doc();

      Booking finalBooking = Booking(
        id: docRef.id,
        userId: booking.userId,
        userName: booking.userName,
        serviceType: booking.serviceType,
        description: booking.description,
        status: 'searching',
        lat: booking.lat,
        lng: booking.lng,
        price: booking.price,
        createdAt: Timestamp.now(),
      );

      await docRef.set(finalBooking.toMap());
      return docRef.id;
    } catch (e) {
      throw "Error creating booking: $e";
    }
  }

  Stream<List<Booking>> getPendingBookings() {
    return _db
        .collection('bookings')
        .where('status', isEqualTo: 'searching')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Booking>> getProviderActiveJob(String providerId) {
    return _db
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> acceptBooking(String bookingId, String providerId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'accepted',
      'providerId': providerId,
    });
  }

  Future<void> completeBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'completed',
    });
  }

  Future<void> cancelBooking(String bookingId, String reason) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'cancelled',
      'cancellationReason': reason,
    });
  }

  Stream<List<Booking>> getUserBookings(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<Booking> listenToBooking(String bookingId) {
    return _db.collection('bookings').doc(bookingId).snapshots().map((doc) {
      if (doc.exists)
        return Booking.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      throw "Booking not found";
    });
  }

  Future<Map<String, dynamic>?> getProviderDetails(String providerId) async {
    try {
      DocumentSnapshot doc =
          await _db.collection('users').doc(providerId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching provider: $e");
    }
    return null;
  }
}
