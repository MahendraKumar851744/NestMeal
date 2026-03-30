import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/providers/auth_provider.dart';
import 'package:nestmeal_app/providers/admin_provider.dart';
import 'package:nestmeal_app/screens/auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchPendingCooks();
    });
  }

  Future<void> _handleApprove(String cookId, String cookName) async {
    final provider = context.read<AdminProvider>();
    
    // Optional: Show loading indicator dialogue here if desired
    
    final success = await provider.approveCook(cookId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$cookName approved successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to approve cook'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
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
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryOrange,
          onRefresh: () => context.read<AdminProvider>().fetchPendingCooks(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCookVerificationSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCookVerificationSection() {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        final pendingCooks = provider.pendingCooks;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Pending Approvals',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(width: 8),
                if (pendingCooks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pendingCooks.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (provider.isLoading && pendingCooks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.error != null && pendingCooks.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.errorRed, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.errorRed),
                    ),
                  ],
                ),
              )
            else if (pendingCooks.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 48, color: AppTheme.successGreen),
                    const SizedBox(height: 12),
                    Text(
                      'All caught up!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No cooks are pending verification.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.greyText, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingCooks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final cook = pendingCooks[index];
                  
                  return Container(
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
                            cook.displayName.isNotEmpty ? cook.displayName[0].toUpperCase() : 'C',
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
                                cook.displayName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${cook.kitchenCity} • ${cook.timeAgo}',
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
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () => _handleApprove(cook.id, cook.displayName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Approve',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}