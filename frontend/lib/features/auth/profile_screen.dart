import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_provider.dart';
import 'payment_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: profile.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF4500)),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(profileProvider.notifier).loadProfile(),
                color: const Color(0xFFFF4500),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Avatar
                    _buildAvatar(profile.email),
                    const SizedBox(height: 24),

                    // Email
                    Text(
                      profile.email ?? 'No email',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Badge
                    _buildStatusBadge(profile.isPro),
                    const SizedBox(height: 40),

                    // Upgrade Button (only if not Pro)
                    if (!profile.isPro) ...[
                      _buildUpgradeButton(),
                      const SizedBox(height: 24),
                    ],

                    // Stats Section
                    _buildStatsSection(),
                    const SizedBox(height: 40),

                    // Sign Out Button
                    _buildSignOutButton(),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildAvatar(String? email) {
    final initial = (email?.isNotEmpty == true) 
        ? email![0].toUpperCase() 
        : '?';

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF4500), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4500).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isPro) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isPro 
            ? const Color(0xFFFFD700).withOpacity(0.2) 
            : Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPro ? const Color(0xFFFFD700) : Colors.grey[600]!,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPro ? Icons.workspace_premium : Icons.explore,
            color: isPro ? const Color(0xFFFFD700) : Colors.grey[400],
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isPro ? 'NOMAD' : 'EXPLORER',
            style: TextStyle(
              color: isPro ? const Color(0xFFFFD700) : Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please log in first'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Redirecting to secure payment...'),
              backgroundColor: Color(0xFFFF4500),
            ),
          );

          final success = await PaymentService.upgradePro(userId);
          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open payment page'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium),
            SizedBox(width: 8),
            Text(
              'Upgrade to Nomad (\$9.99)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR JOURNEY',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.place, '0', 'Places'),
              _buildStatItem(Icons.map, '0', 'Trips'),
              _buildStatItem(Icons.star, '0', 'Reviews'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF4500), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return TextButton(
      onPressed: () async {
        await ref.read(profileProvider.notifier).signOut();
      },
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Text(
            'Sign Out',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

