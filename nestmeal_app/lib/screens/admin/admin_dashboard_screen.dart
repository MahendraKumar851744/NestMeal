import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/providers/auth_provider.dart';
import 'package:nestmeal_app/screens/auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Placeholder data for admin dashboard stats
  final Map<String, dynamic> _stats = {
    'total_sales': 45250,
    'active_cooks': 12,
    'total_orders': 328,
    'customers': 156,
  };

  // Placeholder pending cooks
  final List<Map<String, dynamic>> _pendingCooks = [
    {
      'id': '1',
      'name': 'Priya Sharma',
      'kitchen_type': 'North Indian',
      'date': '2 days ago',
      'status': 'pending_verification',
    },
    {
      'id': '2',
      'name': 'Rajesh Kumar',
      'kitchen_type': 'South Indian',
      'date': '3 days ago',
      'status': 'pending_verification',
    },
    {
      'id': '3',
      'name': 'Anita Patel',
      'kitchen_type': 'Gujarati',
      'date': '5 days ago',
      'status': 'pending_verification',
    },
  ];

  // Placeholder recent activity
  final List<Map<String, dynamic>> _recentActivity = [
    {
      'color': Colors.green,
      'description': 'New cook registration: Meena\'s Kitchen',
      'time': '2 min ago',
    },
    {
      'color': Colors.red,
      'description': 'Order #1042 cancelled by customer',
      'time': '15 min ago',
    },
    {
      'color': Colors.orange,
      'description': 'Low stock alert: Butter Chicken (Cook #5)',
      'time': '1 hour ago',
    },
    {
      'color': Colors.green,
      'description': 'Payment processed: A\$2,450',
      'time': '2 hours ago',
    },
    {
      'color': Colors.blue,
      'description': 'New customer signup: john@email.com',
      'time': '3 hours ago',
    },
  ];

  void _approveCook(int index) {
    setState(() {
      _pendingCooks.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cook approved successfully!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'NestMeal Admin',
              style: TextStyle(fontSize: 12, color: AppTheme.greyText),
            ),
            Text(
              'Dashboard',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid (2x2)
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // Cook Verification Section
            _buildCookVerificationSection(),
            const SizedBox(height: 24),

            // Recent Activity Section
            _buildRecentActivitySection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _AdminStatCard(
          icon: Icons.attach_money,
          iconColor: AppTheme.successGreen,
          label: 'Total Sales',
          value: 'A\$${_stats['total_sales']}',
        ),
        _AdminStatCard(
          icon: Icons.restaurant,
          iconColor: AppTheme.primaryOrange,
          label: 'Active Cooks',
          value: '${_stats['active_cooks']}',
        ),
        _AdminStatCard(
          icon: Icons.receipt_long,
          iconColor: Colors.indigo,
          label: 'Total Orders',
          value: '${_stats['total_orders']}',
        ),
        _AdminStatCard(
          icon: Icons.people,
          iconColor: Colors.teal,
          label: 'Customers',
          value: '${_stats['customers']}',
        ),
      ],
    );
  }

  Widget _buildCookVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Cook Verification',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(width: 8),
            if (_pendingCooks.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_pendingCooks.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_pendingCooks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No pending verifications',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.greyText),
            ),
          )
        else
          ...List.generate(_pendingCooks.length, (index) {
            final cook = _pendingCooks[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.15),
                    child: Text(
                      cook['name'][0],
                      style: TextStyle(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cook['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cook['kitchen_type']} \u2022 ${cook['date']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _approveCook(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () {
                        // Review action placeholder
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Review'),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActivity.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppTheme.lightGrey),
            itemBuilder: (context, index) {
              final activity = _recentActivity[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: activity['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        activity['description'] as String,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activity['time'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _AdminStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
