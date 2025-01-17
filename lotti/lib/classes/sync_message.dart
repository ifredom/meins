import 'package:freezed_annotation/freezed_annotation.dart';

import 'journal_entities.dart';
import 'measurables.dart';

part 'sync_message.freezed.dart';
part 'sync_message.g.dart';

enum SyncEntryStatus { initial, update }

@freezed
class SyncMessage with _$SyncMessage {
  factory SyncMessage.journalEntity({
    required JournalEntity journalEntity,
    required SyncEntryStatus status,
  }) = SyncJournalEntity;

  factory SyncMessage.entityDefinition({
    required EntityDefinition entityDefinition,
    required SyncEntryStatus status,
  }) = SyncEntityDefinition;

  factory SyncMessage.fromJson(Map<String, dynamic> json) =>
      _$SyncMessageFromJson(json);
}
