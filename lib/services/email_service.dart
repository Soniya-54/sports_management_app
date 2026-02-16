// lib/services/email_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class EmailService {
  // EmailJS configuration
  static const String _serviceId = 'service_56qp7nj';
  static const String _templateId = 'template_5anxydh';
  static const String _publicKey = 'vFQLjj_0Ad_JPblwS';

  static Future<bool> sendBookingConfirmationEmail({
    required String toEmail,
    required String userName,
    required String venueName,
    required DateTime bookingDate,
    required String timeSlot,
    required double totalPrice,
  }) async {
    try {
      final dateStr = DateFormat('MMMM dd, yyyy').format(bookingDate);

      print('=== Sending Confirmation Email ===');
      print('To: $toEmail');
      print('Venue: $venueName');

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'accessToken': _publicKey,
          'template_params': {
            'to_email': toEmail,
            'to_name': userName,
            'subject': 'Booking Confirmed - $venueName',
            'venue_name': venueName,
            'booking_date': dateStr,
            'time_slot': timeSlot,
            'total_price': 'Rs. ${totalPrice.toStringAsFixed(2)}',
            'status': 'CONFIRMED',
            'message':
                'Great news! Your booking has been confirmed by the venue manager.',
          },
        }),
      );

      print('Response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error sending confirmation email: $e');
      return false;
    }
  }

  static Future<bool> sendBookingRejectionEmail({
    required String toEmail,
    required String userName,
    required String venueName,
    required DateTime bookingDate,
    required String timeSlot,
    required double totalPrice,
  }) async {
    try {
      final dateStr = DateFormat('MMMM dd, yyyy').format(bookingDate);

      print('=== Sending Rejection Email ===');
      print('To: $toEmail');
      print('Venue: $venueName');

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'accessToken': _publicKey,
          'template_params': {
            'to_email': toEmail,
            'to_name': userName,
            'subject': 'Booking Update - $venueName',
            'venue_name': venueName,
            'booking_date': dateStr,
            'time_slot': timeSlot,
            'total_price': 'Rs. ${totalPrice.toStringAsFixed(2)}',
            'status': 'NOT APPROVED',
            'message':
                'We\'re sorry, but your booking could not be confirmed. Please contact the venue manager or try booking another time slot.',
          },
        }),
      );

      print('Response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error sending rejection email: $e');
      return false;
    }
  }
}
