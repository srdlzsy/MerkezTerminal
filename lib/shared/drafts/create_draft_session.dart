import 'dart:async';

import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft.dart';
import 'package:furpa_merkez_terminal/shared/drafts/create_draft_repository.dart';

class CreateDraftSession with WidgetsBindingObserver {
  CreateDraftSession({
    required this.draft,
    required this.repository,
    required this.hasContent,
    required this.buildPayload,
    required this.buildTitle,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  final CreateDraft? draft;
  final CreateDraftRepository? repository;
  final bool Function() hasContent;
  final Map<String, dynamic> Function() buildPayload;
  final String Function() buildTitle;

  Timer? _timer;
  Future<void> _saveQueue = Future<void>.value();
  bool _dirty = true;
  bool _submitted = false;
  bool _disposed = false;

  void listenTo(Iterable<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.addListener(scheduleSave);
    }
  }

  void scheduleSave() {
    if (_disposed || draft == null || repository == null) {
      return;
    }

    _dirty = true;
    _timer?.cancel();
    // Large PDA forms can contain thousands of product rows. Coalesce rapid
    // scanner/text changes so the full draft is not serialized on every key.
    _timer = Timer(const Duration(milliseconds: 300), () {
      unawaited(flush());
    });
  }

  Future<void> flush() {
    _timer?.cancel();
    _timer = null;

    final currentDraft = draft;
    final currentRepository = repository;
    if (currentDraft == null || currentRepository == null || !_dirty) {
      return _saveQueue;
    }

    _dirty = false;
    final shouldKeep = hasContent();
    final payload = buildPayload();
    final title = buildTitle();
    Future<void> persist() async {
      try {
        if (!shouldKeep) {
          await currentRepository.deleteDraft(currentDraft.id);
          return;
        }

        await currentRepository.saveDraft(
          currentDraft.copyWith(
            title: title,
            updatedAt: DateTime.now(),
            payload: payload,
          ),
        );
      } catch (_) {
        _dirty = true;
        rethrow;
      }
    }

    // A failed background write must not poison every later autosave.
    _saveQueue = _saveQueue.then(
      (_) => persist(),
      onError: (error, stackTrace) => persist(),
    );
    return _saveQueue;
  }

  Future<void> complete() async {
    _timer?.cancel();
    await flush();
    _submitted = true;
  }

  void resumeAfterFailedSubmit() {
    _submitted = false;
    _dirty = true;
  }

  void dispose() {
    if (_disposed) {
      return;
    }

    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (!_submitted) {
      unawaited(flush());
    }
    _disposed = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _timer?.cancel();
      unawaited(flush());
    }
  }
}
