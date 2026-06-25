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

    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 800), () {
      unawaited(flush());
    });
  }

  Future<void> flush() {
    final currentDraft = draft;
    final currentRepository = repository;
    if (currentDraft == null || currentRepository == null) {
      return Future<void>.value();
    }

    final shouldKeep = hasContent();
    final payload = buildPayload();
    final title = buildTitle();
    _saveQueue = _saveQueue.then((_) {
      if (!shouldKeep) {
        return currentRepository.deleteDraft(currentDraft.id);
      }

      return currentRepository.saveDraft(
        currentDraft.copyWith(
          title: title,
          updatedAt: DateTime.now(),
          payload: payload,
        ),
      );
    });
    return _saveQueue;
  }

  Future<void> complete() async {
    _timer?.cancel();
    await flush();
    _submitted = true;
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
