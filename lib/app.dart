import 'features/registration/registration_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/availability/availability_screen.dart';
import 'features/consultation/consultation_screen.dart';
import 'shared/widgets/workspace_widgets.dart';

class DoctorApp extends StatelessWidget {
  const DoctorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pocket Doctor · Doctor',
    debugShowCheckedModeBanner: false,
    theme: doctorTheme,
    home: const SessionGate(),
  );
}

class SessionGate extends ConsumerStatefulWidget {
  const SessionGate({super.key});
  @override
  ConsumerState<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends ConsumerState<SessionGate>
    with WidgetsBindingObserver {
  bool obscured = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted) unawaited(ref.read(authProvider.notifier).restore());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (ref.read(authProvider).session != null) {
        unawaited(ref.read(authProvider.notifier).refresh());
      }
      setState(() => obscured = false);
    } else {
      setState(() => obscured = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (obscured || auth.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Checking your session',
          ),
        ),
      );
    }
    if (auth.session == null) return LoginScreen(message: auth.message);
    if (auth.session!.registrationRequired) return const RegistrationScreen();
    if (!auth.session!.ready) {
      return Scaffold(
        appBar: AppBar(title: const Brand()),
        body: SafeArea(
          child: FormPage(
            children: [
              Text(
                'Doctor account status',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Notice(auth.session!.status.replaceAll('_', ' ')),
              const Text(
                'Pocket Doctor manages verification and account access. Contact the platform team for assistance.',
              ),
              FilledButton(
                onPressed: () => ref.read(authProvider.notifier).refresh(),
                child: const Text('Check status'),
              ),
              OutlinedButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      );
    }
    return Workspace(key: ValueKey(auth.generation));
  }
}

class Workspace extends ConsumerStatefulWidget {
  const Workspace({super.key});
  @override
  ConsumerState<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends ConsumerState<Workspace> {
  int tab = 0;
  String? appointmentId;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: appointmentId == null && tab == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) {
        setState(() {
          if (appointmentId != null) {
            appointmentId = null;
          } else {
            tab = 0;
          }
        });
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Brand(),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: appointmentId != null
            ? ConsultationScreen(
                id: appointmentId!,
                onBack: () => setState(() => appointmentId = null),
              )
            : switch (tab) {
                1 => const AvailabilityScreen(),
                2 => const ProfileScreen(),
                _ => DashboardScreen(
                  onOpen: (id) => setState(() => appointmentId = id),
                ),
              },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() {
          tab = index;
          appointmentId = null;
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule),
            label: 'Availability',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    ),
  );
}
