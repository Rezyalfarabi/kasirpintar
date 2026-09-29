import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Membetulkan berkas .xlsx yang menulis path absolut pada
/// `xl/_rels/workbook.xml.rels`, misalnya `Target="/xl/worksheets/sheet1.xml"`.
///
/// Package `excel` 4.0.6 membaca tempat worksheet dengan `findFile('xl/$target')`
/// tanpa menormalkan path absolut (padahal untuk shared strings ia punya logika
/// `_absSharedStringsTarget`). Berkas asli buatan Excel/LibreOffice memakai
/// path absolut, sehingga lookup-nya menjadi `xl//xl/worksheets/sheet1.xml`,
/// tidak ketemu, lalu `file!.decompress()` melempar null check saat parsing.
///
/// Normalisasi cukup menghapus awalan `/xl/` pada atribut `Target` di berkas
/// rels; sisanya dipindahkan apa adanya ke berkas hasil.
Uint8List normalizeExcelWorkbookTargets(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    return bytes;
  }

  final rels = archive.findFile('xl/_rels/workbook.xml.rels');
  if (rels == null) return bytes;

  Uint8List content;
  try {
    rels.decompress();
    content = rels.content as Uint8List;
  } catch (_) {
    return bytes;
  }

  final text = utf8.decode(content);
  final normalized = text
      .replaceAll('Target="/xl/', 'Target="')
      .replaceAll("Target='/xl/", "Target='");
  if (normalized == text) return bytes;

  final out = Archive();
  for (final file in archive.files) {
    if (!file.isFile) continue;
    if (file.name == 'xl/_rels/workbook.xml.rels') {
      final newContent = Uint8List.fromList(utf8.encode(normalized));
      out.addFile(ArchiveFile(file.name, newContent.length, newContent));
    } else {
      try {
        file.decompress();
      } catch (_) {
        // Berkas yang tidak bisa didekompres ikut disalin mentah.
      }
      out.addFile(ArchiveFile(file.name, file.content.length, file.content));
    }
  }

  final encoded = ZipEncoder().encode(out);
  return encoded == null ? bytes : Uint8List.fromList(encoded);
}