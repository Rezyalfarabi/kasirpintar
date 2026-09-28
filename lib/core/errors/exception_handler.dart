import 'package:flutter/foundation.dart';
import 'package:kasir_pintar/core/errors/failures.dart';

class ExceptionHandler {
  static Failure handleError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('Error: $error');
      debugPrint('StackTrace: $stackTrace');
    }

    if (error is Failure) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('database') ||
        errorString.contains('sqlite') ||
        errorString.contains('drift')) {
      return DatabaseFailure(
        'Database error: $error',
        code: 'DATABASE_ERROR',
      );
    }

    if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('not granted')) {
      return PermissionFailure(
        'Permission denied: $error',
        code: 'PERMISSION_DENIED',
      );
    }

    if (errorString.contains('not found') ||
        errorString.contains('404')) {
      return NotFoundFailure(
        'Not found: $error',
        code: 'NOT_FOUND',
      );
    }

    if (errorString.contains('duplicate') ||
        errorString.contains('unique constraint') ||
        errorString.contains('already exists')) {
      return DuplicateFailure(
        'Duplicate entry: $error',
        code: 'DUPLICATE_ENTRY',
      );
    }

    if (errorString.contains('format') ||
        errorString.contains('parse') ||
        errorString.contains('invalid')) {
      return ParsingFailure(
        'Parsing error: $error',
        code: 'PARSING_ERROR',
      );
    }

    if (errorString.contains('storage') ||
        errorString.contains('file') ||
        errorString.contains('directory') ||
        errorString.contains('path')) {
      return StorageFailure(
        'Storage error: $error',
        code: 'STORAGE_ERROR',
      );
    }

    return UnknownFailure(
      'Unknown error: $error',
      code: 'UNKNOWN_ERROR',
    );
  }

  static Failure handleValidationError(String message) {
    return ValidationFailure(message, code: 'VALIDATION_ERROR');
  }
}