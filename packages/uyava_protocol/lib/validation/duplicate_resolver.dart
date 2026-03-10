/// Helpers for resolving duplicate payloads by identifier.
///
/// These utilities centralize the "last writer wins" policy so that hosts,
/// the core engine, and the SDK can surface consistent diagnostics.

class UyavaDuplicateRecord {
  const UyavaDuplicateRecord({
    required this.id,
    required this.previousIndex,
    required this.nextIndex,
  });

  /// The identifier shared by the conflicting payloads.
  final String id;

  /// The index where the first occurrence appeared in the raw list.
  final int previousIndex;

  /// The index where the newer occurrence appeared in the raw list.
  final int nextIndex;
}

class UyavaDeduplicatedEntry<T> {
  const UyavaDeduplicatedEntry({required this.value, required this.index});

  /// The most recent payload associated with [id].
  final T value;

  /// The index of the most recent payload in the raw list.
  final int index;
}

class UyavaDeduplicationResult<T> {
  const UyavaDeduplicationResult._({
    required this.latestById,
    required this.duplicates,
  });

  /// Map of identifier to the latest payload + index (last writer wins).
  final Map<String, UyavaDeduplicatedEntry<T>> latestById;

  /// Metadata describing which entries were replaced by newer payloads.
  final List<UyavaDuplicateRecord> duplicates;

  bool get hasDuplicates => duplicates.isNotEmpty;
}

typedef UyavaIdSelector<T> = String? Function(T entry);

/// Applies last-writer-wins deduplication to [entries], retaining metadata about
/// conflicts for diagnostics while keeping the most recent payload for each id.
UyavaDeduplicationResult<T> dedupeById<T>(
  Iterable<T> entries,
  UyavaIdSelector<T> idSelector,
) {
  final Map<String, UyavaDeduplicatedEntry<T>> latestById =
      <String, UyavaDeduplicatedEntry<T>>{};
  final List<UyavaDuplicateRecord> duplicates = <UyavaDuplicateRecord>[];
  var index = 0;
  for (final T entry in entries) {
    final String? id = idSelector(entry);
    if (id == null || id.isEmpty) {
      index++;
      continue;
    }
    final UyavaDeduplicatedEntry<T>? previous = latestById[id];
    if (previous != null) {
      duplicates.add(
        UyavaDuplicateRecord(
          id: id,
          previousIndex: previous.index,
          nextIndex: index,
        ),
      );
    }
    latestById[id] = UyavaDeduplicatedEntry<T>(value: entry, index: index);
    index++;
  }
  return UyavaDeduplicationResult<T>._(
    latestById: Map<String, UyavaDeduplicatedEntry<T>>.unmodifiable(latestById),
    duplicates: List<UyavaDuplicateRecord>.unmodifiable(duplicates),
  );
}
