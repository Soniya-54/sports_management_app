// lib/screens/payment_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String venueName;
  final String venueManagerId;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.venueName,
    required this.venueManagerId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoadingManagerInfo = true;
  String? _khaltiNumber;
  String? _esewaNumber;
  String? _qrCodeUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVenueManagerPaymentInfo();
  }

  Future<void> _loadVenueManagerPaymentInfo() async {
    setState(() {
      _isLoadingManagerInfo = true;
      _errorMessage = null;
    });

    try {
      final managerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.venueManagerId)
          .get();

      if (managerDoc.exists) {
        final data = managerDoc.data();
        setState(() {
          _khaltiNumber = data?['khaltiNumber'] as String?;
          _esewaNumber = data?['esewaNumber'] as String?;
          _qrCodeUrl = data?['qrCodeUrl'] as String?;
          _isLoadingManagerInfo = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Venue manager information not found';
          _isLoadingManagerInfo = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load payment information: $e';
        _isLoadingManagerInfo = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _manualPaymentConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: const Text(
          'Have you completed the payment via QR code, Khalti, or eSewa?\n\n'
          'Please confirm only after making the payment. The venue manager will verify your booking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(widget.bookingId)
                    .update({
                      'bookingStatus': 'pending_verification',
                      'paymentMethod': 'manual',
                      'paidAt': FieldValue.serverTimestamp(),
                    });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Booking submitted for verification. You will be notified once confirmed.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop(true);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update booking: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Yes, I have Paid'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Payment')),
      body: _isLoadingManagerInfo
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadVenueManagerPaymentInfo,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Venue:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                widget.venueName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Amount:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Rs. ${widget.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_khaltiNumber != null ||
                      _esewaNumber != null ||
                      _qrCodeUrl != null) ...[
                    const Text(
                      'Pay to Venue Manager',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_qrCodeUrl != null && _qrCodeUrl!.isNotEmpty) ...[
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Scan QR Code to Pay',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _qrCodeUrl!.startsWith('http')
                                  ? Image.network(
                                      _qrCodeUrl!,
                                      width: 250,
                                      height: 250,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 250,
                                              height: 250,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.qr_code,
                                                size: 100,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    )
                                  : Image.memory(
                                      base64Decode(_qrCodeUrl!),
                                      width: 250,
                                      height: 250,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 250,
                                              height: 250,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.qr_code,
                                                size: 100,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_khaltiNumber != null && _khaltiNumber!.isNotEmpty) ...[
                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(
                            Icons.phone_android,
                            color: Colors.purple,
                          ),
                          title: const Text('Payment Number'),
                          subtitle: Text(
                            _khaltiNumber!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () => _copyToClipboard(
                              _khaltiNumber!,
                              'Payment number',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_esewaNumber != null && _esewaNumber!.isNotEmpty) ...[
                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.green,
                          ),
                          title: const Text('eSewa Number'),
                          subtitle: Text(
                            _esewaNumber!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () =>
                                _copyToClipboard(_esewaNumber!, 'eSewa number'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                  if (_khaltiNumber == null &&
                      _esewaNumber == null &&
                      _qrCodeUrl == null)
                    const Card(
                      color: Colors.orange,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Venue manager has not set up payment details yet. Please contact them directly.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _manualPaymentConfirmation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.check_circle),
                    label: const Text(
                      'I have completed the payment',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.blue[50],
                    elevation: 0,
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Payment Instructions',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. Scan the QR code or copy Khalti/eSewa number\n'
                            '2. Open your Khalti or eSewa app\n'
                            '3. Complete the payment of Rs. shown above\n'
                            '4. After payment, click "I have completed the payment"\n'
                            '5. Your booking will be verified by the venue manager',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
