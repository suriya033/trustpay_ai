import '../core/constants/api_constants.dart';
import '../models/transaction_model.dart';
import 'api_service.dart';

class PaymentService {
  static Future<Map<String, dynamic>> createPayPalOrder({
    required String projectId,
    required String milestoneId,
  }) async {
    final response = await ApiService.post(
      ApiConstants.createPayPalOrder(projectId, milestoneId),
    );
    return response as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> capturePayPalOrder({
    required String projectId,
    required String milestoneId,
    String? orderId,
  }) async {
    final response = await ApiService.post(
      ApiConstants.capturePayPalOrder(projectId, milestoneId),
      body: {
        if (orderId != null) 'orderId': orderId,
      },
    );
    return response as Map<String, dynamic>;
  }

  static Future<List<TransactionModel>> getTransactions() async {
    final response = await ApiService.get(ApiConstants.transactions);
    if (response is List) {
      return response
          .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static Future<TransactionModel> getReceipt(String receiptId) async {
    final response = await ApiService.get(ApiConstants.receipt(receiptId));
    return TransactionModel.fromJson(response);
  }
}
