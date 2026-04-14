import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'supabase_service.dart';

class PaymentPage extends StatefulWidget {
  final String planName;
  final String price;
  final String priceId;

  const PaymentPage({
    super.key,
    required this.planName,
    required this.price,
    this.priceId = 'price_default_id',
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;
  final _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Secure Checkout"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF0F172A),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.amber, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "${widget.planName} Plan",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Amount to pay: ${widget.price}",
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Payment Method",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Securely pay using Stripe. Supports Credit Cards, PayWave, Google Pay, and Apple Pay.",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 48),
                  
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
                  else
                    ElevatedButton(
                      onPressed: () => _handleStripePayment(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 20),
                          SizedBox(width: 12),
                          Text("PAY SECURELY WITH STRIPE", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  const Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user_outlined, size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Text("PCI-DSS Compliant Gateway", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStripePayment(BuildContext context) async {
    setState(() => _isLoading = true);

    try {
      // Call Supabase Edge Function for Checkout Session
      final checkoutUrl = await _supabaseService.createCheckoutSession(widget.priceId);

      if (checkoutUrl != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Redirecting to Stripe...')),
          );
        }
        final uri = Uri.parse(checkoutUrl);
        final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!launched) {
          throw Exception('Could not open Stripe checkout.');
        }
        if (!mounted) return;

        // After returning from browser, we do NOT automatically grant premium.
        // They must be validated by the webhook and their new database status.
        Navigator.pop(context, false);
      } else {
        throw Exception('Failed to create checkout session. Have you initialized Supabase?');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (context.mounted) setState(() => _isLoading = false);
    }
  }
}
