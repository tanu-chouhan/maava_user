import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maava_mart_seller/core/providers/repository_providers.dart';
import 'package:maava_mart_seller/features/payouts/domain/payout_model.dart';
import 'package:maava_mart_seller/features/payouts/domain/payout_repository.dart';

final payoutSummaryProvider =
    AsyncNotifierProvider<PayoutSummaryController, PayoutSummaryModel>(
      PayoutSummaryController.new,
    );

class PayoutSummaryController extends AsyncNotifier<PayoutSummaryModel> {
  late final PayoutRepository _repository;

  @override
  Future<PayoutSummaryModel> build() async {
    _repository = ref.watch(payoutRepositoryProvider);
    return _repository.getPayoutSummary();
  }

  Future<bool> requestPayout(double amount) async {
    final success = await _repository.requestInstantPayout(amount);
    if (success) {
      state = await AsyncValue.guard(() => _repository.getPayoutSummary());
      ref.invalidate(payoutTransactionsProvider);
    }
    return success;
  }
}

final payoutTransactionsProvider = FutureProvider<List<PayoutTransactionModel>>(
  (ref) async {
    final repository = ref.watch(payoutRepositoryProvider);
    return repository.getPayoutTransactions();
  },
);

final bankDetailsControllerProvider =
    AsyncNotifierProvider<BankDetailsController, BankDetailsModel>(
      BankDetailsController.new,
    );

class BankDetailsController extends AsyncNotifier<BankDetailsModel> {
  late final PayoutRepository _repository;

  @override
  Future<BankDetailsModel> build() async {
    _repository = ref.watch(payoutRepositoryProvider);
    return _repository.getBankDetails();
  }

  Future<void> updateBankDetails(BankDetailsModel details) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateBankDetails(details);
      return details;
    });
  }
}
