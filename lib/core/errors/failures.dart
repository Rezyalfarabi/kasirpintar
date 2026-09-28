abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

class DuplicateFailure extends Failure {
  const DuplicateFailure(super.message, {super.code});
}

class ParsingFailure extends Failure {
  const ParsingFailure(super.message, {super.code});
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}

extension FailureExtension on Failure {
  String get userMessage {
    switch (this) {
      case DatabaseFailure():
        return 'Terjadi kesalahan database. Silakan coba lagi.';
      case NetworkFailure():
        return 'Koneksi bermasalah. Periksa internet Anda.';
      case ValidationFailure():
        return message;
      case PermissionFailure():
        return 'Izin tidak diberikan. Buka pengaturan aplikasi.';
      case NotFoundFailure():
        return 'Data tidak ditemukan.';
      case DuplicateFailure():
        return 'Data sudah ada: $message';
      case ParsingFailure():
        return 'Format data tidak valid.';
      case StorageFailure():
        return 'Gagal menyimpan file.';
      default:
        return 'Terjadi kesalahan tidak diketahui.';
    }
  }
}