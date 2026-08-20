import 'package:dio/dio.dart';
import 'package:maava_mart_seller/features/payouts/domain/payout_model.dart';
import 'package:maava_mart_seller/features/payouts/domain/payout_repository.dart';

/// Earnings, settlement history and bank details.
///
/// `/food/restaurant/finance` answers all of it in one call: the current cycle
/// is what is still owed, past cycles are what has been settled. Bank details
/// live on the store document, not in finance.
class ApiPayoutRepository implements PayoutRepository {
  const ApiPayoutRepository(this._dio);

  final Dio _dio;

  @override
  Future<PayoutSummaryModel> getPayoutSummary() async {
    final finance = await _finance();
    final wallet = _asMap(finance['wallet']);
    final current = _asMap(finance['currentCycle']);
    final past = _asMap(finance['pastCycles']);

    // Wallet is the lifetime view and the cycle is the open one; the wallet is
    // preferred and the cycle fills in when a field is missing rather than
    // zero, so a fresh store does not read as having earned nothing when it
    // has simply not been settled yet.
    double pick(String key) =>
        _asNum(wallet[key])?.toDouble() ??
        _asNum(current[key])?.toDouble() ??
        0;

    final settled = _asList(past['orders']);

    return PayoutSummaryModel(
      totalEarnings: pick('totalEarnings'),
      availableBalance: pick('withdrawableBalance'),
      // What is earned but not yet withdrawable.
      pendingPayout: pick('estimatedPayout'),
      lastPayoutAmount: settled.isEmpty
          ? 0
          : _asNum(
                  settled.first['amount'] ?? settled.first['netAmount'],
                )?.toDouble() ??
                0,
      lastPayoutDate: settled.isEmpty
          ? null
          : _asDate(settled.first['payoutDate'] ?? settled.first['createdAt']),
    );
  }

  @override
  Future<List<PayoutTransactionModel>> getPayoutTransactions() async {
    final finance = await _finance();

    // Settled cycles first, then the open one, so the newest movement is not
    // buried under history.
    final rows = [
      ..._asList(_asMap(finance['currentCycle'])['orders']),
      ..._asList(_asMap(finance['pastCycles'])['orders']),
    ];

    return rows.map((r) {
      final amount =
          _asNum(
            r['netAmount'] ?? r['amount'] ?? r['payoutAmount'],
          )?.toDouble() ??
          0;
      return PayoutTransactionModel(
        id: (r['_id'] ?? r['id'] ?? r['orderId'] ?? '').toString(),
        referenceNumber: (r['order_id'] ?? r['orderId'] ?? r['reference'] ?? '')
            .toString(),
        amount: amount,
        date: _asDate(r['payoutDate'] ?? r['createdAt']) ?? DateTime.now(),
        status: _toStatus((r['payoutStatus'] ?? r['status'] ?? '').toString()),
        // No invented default: this labels a real money movement, and naming a
        // method the backend never reported is a claim about where the money
        // went.
        payoutMethod: (r['payoutMethod'] ?? '').toString(),
      );
    }).toList();
  }

  @override
  Future<BankDetailsModel> getBankDetails() async {
    final store = await _currentStore();

    return BankDetailsModel(
      accountHolderName: (store['accountHolderName'] ?? '').toString(),
      accountNumber: (store['accountNumber'] ?? '').toString(),
      ifscCode: (store['ifscCode'] ?? '').toString(),
      bankName: (store['bankName'] ?? '').toString(),
      branchName: (store['branchName'] ?? '').toString(),
      upiId: (store['upiId'] ?? '').toString(),
      // The backend has no verification flag on these; an account with a
      // number and an IFSC is as verified as this app can honestly claim.
      isVerified:
          (store['accountNumber'] ?? '').toString().isNotEmpty &&
          (store['ifscCode'] ?? '').toString().isNotEmpty,
    );
  }

  @override
  Future<void> updateBankDetails(BankDetailsModel bankDetails) =>
      _dio.patch<dynamic>(
        '/quick/restaurant/profile',
        data: {
          'accountHolderName': bankDetails.accountHolderName,
          'accountNumber': bankDetails.accountNumber,
          'ifscCode': bankDetails.ifscCode,
          'bankName': bankDetails.bankName,
          'branchName': bankDetails.branchName,
          'upiId': bankDetails.upiId,
        },
      );

  @override
  Future<bool> requestInstantPayout(double amount) async {
    // Settlement runs on the platform's cycle; there is no seller-facing
    // endpoint that releases money on demand, and inventing one would tell a
    // seller their money is coming when nothing was triggered.
    return false;
  }

  Future<Map<String, dynamic>> _finance() async {
    final response = await _dio.get<dynamic>('/quick/restaurant/finance');
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> _currentStore() async {
    final response = await _dio.get<dynamic>('/quick/restaurant/current');
    final data = _asMap(response.data);
    final nested = data['restaurant'];
    return nested is Map ? Map<String, dynamic>.from(nested) : data;
  }

  static PayoutStatus _toStatus(String wire) {
    switch (wire.toLowerCase()) {
      case 'paid':
      case 'settled':
      case 'completed':
      case 'captured':
        return PayoutStatus.completed;
      case 'failed':
      case 'reversed':
        return PayoutStatus.failed;
      default:
        return PayoutStatus.processing;
    }
  }

  static Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static List<Map<String, dynamic>> _asList(dynamic v) => v is List
      ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : const [];

  static num? _asNum(dynamic v) =>
      v is num ? v : num.tryParse((v ?? '').toString());

  static DateTime? _asDate(dynamic v) =>
      DateTime.tryParse((v ?? '').toString())?.toLocal();
}
