import 'package:flutter/material.dart';
import 'loading_shimmer.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/branding/doctor-app-icon.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  semanticLabel: 'Pocket Doctor Doctor',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Doctor. In Your Pocket.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 180,
                child: LoadingShimmer(
                  height: 6,
                  label: 'Checking your session',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
