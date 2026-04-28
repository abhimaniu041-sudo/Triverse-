import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Wraps the Razorpay Flutter checkout + Cloud Function order creation.
/// Falls back to mock-success flow when backend keys are not configured.
class PaymentService {
  final Razorpay _razorpay = Razorpay();
  Function(int creditsAdded)? _onSuccess;
  Function(String reason)? _onError;
  String? _pendingOrderId;

  PaymentService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  void dispose() {
    _razorpay.clear();
  }

  Future<void> startPayment({
    required BuildContext context,
    required int amountRupees,
    required int creditsToAdd,
    required String planLabel,
    required Function(int creditsAdded) onSuccess,
    required Function(String reason) onError,
  }) async {
    _onSuccess = onSuccess;
    _onError = onError;

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('createRazorpayOrder');
      final result = await callable.call(<String, dynamic>{
        'amount': amountRupees,
        'creditsToAdd': creditsToAdd,
      });
      final data = Map<String, dynamic>.from(result.data as Map);

      // MOCK mode → credits already granted server-side
      if (data['mock'] == true) {
        onSuccess(creditsToAdd);
        return;
      }

      _pendingOrderId = data['orderId'] as String;
      final options = <String, dynamic>{
        'key': data['keyId'],
        'amount': data['amountPaise'],
        'currency': data['currency'],
        'order_id': data['razorpayOrderId'],
        'name': 'TriVerse',
        'description': planLabel,
        'prefill': {
          'email': FirebaseAuth.instance.currentUser?.email ?? '',
        },
        'theme': {'color': '#B026FF'},
      };
      _razorpay.open(options);
    } catch (e) {
      onError('Order creation failed: $e');
    }
  }

  Future<void> _handleSuccess(PaymentSuccessResponse resp) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('verifyRazorpayPayment');
      final result = await callable.call(<String, dynamic>{
        'orderId': _pendingOrderId,
        'razorpayOrderId': resp.orderId,
        'razorpayPaymentId': resp.paymentId,
        'razorpaySignature': resp.signature,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['success'] == true && _onSuccess != null) {
        _onSuccess!(data['creditsAdded'] ?? 0);
      } else {
        _onError?.call('Verification failed.');
      }
    } catch (e) {
      _onError?.call('Verification error: $e');
    }
  }

  void _handleError(PaymentFailureResponse resp) {
    _onError?.call(resp.message ?? 'Payment failed');
  }
}
