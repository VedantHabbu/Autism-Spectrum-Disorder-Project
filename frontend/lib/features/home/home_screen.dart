import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../widgets/disclaimer_banner.dart';
import '../child_profile/child_profile_screen.dart';
import '../observation/free_text_observation_screen.dart';
import '../observation/guided_observation_screen.dart';
import '../observation/observation_history_screen.dart';
import '../observation_period/observation_period_screen.dart';

/// App home / navigation shell.
///
/// Checks backend connectivity on load (Flutter -> FastAPI /health), then
/// links to each caregiver workflow screen. Reached only once the
/// caregiver is signed in (see AuthGate); sign-out is in the app bar.
/// Screens beyond free-text analysis are not yet wired to Supabase.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.apiClient, this.authService});

  final ApiClient? apiClient;

  /// Present once the caregiver is signed in; enables sign-out.
  final AuthService? authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();
  bool? _backendReachable;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    final reachable = await _apiClient.checkHealth();
    if (mounted) {
      setState(() => _backendReachable = reachable);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ASD Screening Support'),
        actions: [
          if (widget.authService != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: widget.authService!.currentEmail == null
                  ? 'Sign out'
                  : 'Sign out (${widget.authService!.currentEmail})',
              onPressed: () => widget.authService!.signOut(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DisclaimerBanner(),
          const SizedBox(height: 12),
          _BackendStatusTile(reachable: _backendReachable, onRetry: _checkBackend),
          const SizedBox(height: 16),
          _NavigationTile(
            icon: Icons.child_care,
            title: 'Child profile',
            subtitle: 'Create or view a child profile',
            onTap: () => _push(const ChildProfileScreen()),
          ),
          _NavigationTile(
            icon: Icons.event_note,
            title: 'Observation period',
            subtitle: 'Start a doctor-defined monitoring window',
            onTap: () => _push(const ObservationPeriodScreen()),
          ),
          _NavigationTile(
            icon: Icons.edit_note,
            title: 'Free-text observation',
            subtitle: 'Write an observation and see the NLP interpretation',
            onTap: () => _push(const FreeTextObservationScreen()),
          ),
          _NavigationTile(
            icon: Icons.checklist,
            title: 'Guided observation',
            subtitle: 'Answer structured prompts for each behavioural domain',
            onTap: () => _push(const GuidedObservationScreen()),
          ),
          _NavigationTile(
            icon: Icons.history,
            title: 'Observation history',
            subtitle: 'Review past observations for a child',
            onTap: () => _push(const ObservationHistoryScreen()),
          ),
        ],
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _BackendStatusTile extends StatelessWidget {
  const _BackendStatusTile({required this.reachable, required this.onRetry});

  final bool? reachable;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (reachable) {
      null => (Icons.sync, Colors.grey, 'Checking backend connection...'),
      true => (Icons.check_circle, Colors.green, 'Backend connected'),
      false => (Icons.cloud_off, Colors.red, 'Backend unreachable'),
    };
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        subtitle: reachable == false
            ? const Text('Start the FastAPI service and check the API base URL.')
            : null,
        trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: onRetry),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
