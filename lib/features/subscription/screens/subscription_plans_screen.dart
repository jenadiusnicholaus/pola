import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';
import '../../../features/profile/services/profile_service.dart';
import 'payment_method_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final SubscriptionService _subscriptionService =
      Get.find<SubscriptionService>();
  final ProfileService _profileService = Get.find<ProfileService>();
  List<SubscriptionPlan> plans = [];
  bool isLoading = true;
  String? errorMessage;
  String? currentPlanType;
  bool isSubscriptionActive = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
    _loadPlans();
  }

  void _loadCurrentSubscription() {
    try {
      final profile = _profileService.currentProfile;
      if (profile != null) {
        currentPlanType = profile.subscription.planType;
        isSubscriptionActive = profile.subscription.isActive;
        debugPrint('📋 Current subscription plan type: $currentPlanType, active: $isSubscriptionActive');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading current subscription: $e');
    }
  }

  Future<void> _loadPlans() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedPlans = await _subscriptionService.getPlans();
      setState(() {
        plans = loadedPlans;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load subscription plans';
      });
      debugPrint('Error loading plans: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading subscription plans...'),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadPlans,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : plans.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No subscription plans available',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: plans.length,
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        return _buildPlanCard(plan, theme, isSubscriptionActive);
                      },
                    ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, ThemeData theme, bool isSubscriptionActive) {
    final isPopular = plan.isPopular;
    final isDark = theme.brightness == Brightness.dark;
    final isCurrentPlan = plan.planType == currentPlanType;
    // Allow resubscribing if subscription is expired (not active)
    final canSubscribe = !isCurrentPlan || !isSubscriptionActive;
    final isExpiredCurrentPlan = isCurrentPlan && !isSubscriptionActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCurrentPlan ? 6 : (isPopular ? 8 : 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentPlan
            ? BorderSide(color: isExpiredCurrentPlan ? Colors.red : Colors.green, width: 2)
            : (isPopular
                ? const BorderSide(color: Colors.amber, width: 2)
                : BorderSide.none),
      ),
      child: Stack(
        children: [
          if (isCurrentPlan)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isExpiredCurrentPlan ? Colors.red : Colors.green,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isExpiredCurrentPlan ? Icons.warning_amber : Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isExpiredCurrentPlan ? 'EXPIRED' : 'CURRENT PLAN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isPopular
                                  ? Colors.amber.shade700
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            plan.nameSwahili,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plan.currency} ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      plan.price == 0 ? 'FREE' : plan.price.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isPopular
                            ? Colors.amber.shade700
                            : theme.colorScheme.primary,
                      ),
                    ),
                    if (plan.price > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          plan.durationDisplay,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                  ],
                ),
                if (plan.discount != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      plan.discount!,
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Features:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ...plan.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color:
                              isPopular ? Colors.amber.shade700 : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        canSubscribe ? () => _handleSubscribe(plan) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !canSubscribe
                          ? Colors.grey.shade400
                          : (isExpiredCurrentPlan
                              ? Colors.red
                              : (isPopular
                                  ? Colors.amber
                                  : theme.colorScheme.primary)),
                      foregroundColor: !canSubscribe
                          ? Colors.grey.shade700
                          : (isPopular ? Colors.black : Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: !canSubscribe ? 0 : (isPopular ? 4 : 2),
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!canSubscribe) ...[
                          const Icon(Icons.check_circle, size: 20),
                          const SizedBox(width: 8),
                        ],
                        if (isExpiredCurrentPlan) ...[
                          const Icon(Icons.refresh, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          !canSubscribe
                              ? 'Current Plan'
                              : (isExpiredCurrentPlan
                                  ? 'Renew Subscription'
                                  : (plan.price == 0
                                      ? 'Start Free Trial'
                                      : 'Subscribe Now')),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubscribe(SubscriptionPlan plan) {
    Get.to(() => PaymentMethodScreen(plan: plan));
  }
}
