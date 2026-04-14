import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'topic_model.dart';
import 'payment_page.dart';

class TopicDetailPage extends StatelessWidget {
  final Topic topic;
  final bool isPremiumUser;

  const TopicDetailPage({super.key, required this.topic, required this.isPremiumUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(topic.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildHeaderBadge(topic.difficulty, const Color(0xFFF1F5F9), const Color(0xFF0F172A)),
                const SizedBox(width: 10),
                _buildHeaderBadge(topic.category, const Color(0xFFF0FDF4), const Color(0xFF166534)),
                const Spacer(),
                if (isPremiumUser)
                  const Icon(Icons.verified, color: Colors.amber, size: 24),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSection(Icons.checklist, "1. Functional Requirements", "Core features: User authentication, real-time updates, and search functionality."),
            _buildSection(Icons.speed, "2. Non-functional Requirements", "High availability (99.99%), low latency (<200ms), and global scalability."),
            _buildSection(Icons.account_tree, "3. High-level Architecture", "Client -> Load Balancer -> API Gateway -> Microservices -> Cache -> DB."),

            const SizedBox(height: 32),
            
            _buildYoutubeSection(),
            
            const SizedBox(height: 32),
            
            if (!isPremiumUser)
              _buildSeniorPackPromo(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildSection(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF0F172A)),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 10),
            Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildYoutubeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.play_circle_fill, size: 50, color: Color(0xFFEF4444)),
          const SizedBox(height: 10),
          const Text("Architecture Deep Dive", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text("Watch the full architecture breakdown on YouTube", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () => launchUrl(Uri.parse("https://youtube.com")),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text("WATCH NOW"),
          ),
        ],
      ),
    );
  }

  void _showPlanSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Select a Plan", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPlanOption(context, "Monthly", r"$9.99"),
            _buildPlanOption(context, "Yearly", r"$59", subtitle: "Save 50%"),
            _buildPlanOption(context, "Lifetime", r"$99", subtitle: "Best Value"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
        ],
      ),
    );
  }

  Widget _buildPlanOption(BuildContext context, String title, String price, {String? subtitle}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFFF1F5F9),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)) : null,
        trailing: Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentPage(planName: title, price: price)));
        },
      ),
    );
  }

  Widget _buildSeniorPackPromo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
              SizedBox(width: 12),
              Text("Senior Pack", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Get full access to all 100+ system design cases.", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showPlanSelector(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("UPGRADE NOW", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
