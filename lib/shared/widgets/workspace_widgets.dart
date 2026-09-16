import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/api_failure.dart';
import 'loading_shimmer.dart';
export 'loading_shimmer.dart';

String friendlyError(Object error) => switch (error) {
  ApiFailure() => error.message,
  FormatException() => error.message,
  _ => 'We could not complete that request. Please try again.',
};

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'POCKET DOCTOR',
        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
      ),
      Text('Your Doctor. In Your Pocket.', style: TextStyle(fontSize: 12)),
    ],
  );
}

class Notice extends StatelessWidget {
  const Notice(this.message, {this.error = false, super.key});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: error ? const Color(0xFFFFF1F0) : const Color(0xFFE5F7EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: error ? const Color(0xFFAE303B) : const Color(0xFF061D43),
        ),
      ),
    ),
  );
}

class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    required this.value,
    required this.retry,
    required this.builder,
    super.key,
  });
  final AsyncValue<T> value;
  final VoidCallback retry;
  final Widget Function(T) builder;
  @override
  Widget build(BuildContext context) {
    if (value.isLoading) {
      return const LoadingShimmer(label: 'Loading workspace');
    }
    if (value.hasError) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Notice(friendlyError(value.error!), error: true),
          FilledButton(onPressed: retry, child: const Text('Retry')),
        ],
      );
    }
    return builder(value.requireValue);
  }
}

class FormPage extends StatelessWidget {
  const FormPage({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.all(20),
    children: children
        .map(
          (widget) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: widget,
          ),
        )
        .toList(),
  );
}
