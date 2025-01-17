import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:lotti/sync/secure_storage.dart';
import 'package:lotti/sync/vector_clock.dart';
import 'package:lotti/utils/file_utils.dart';

const String hostKey = 'VC_HOST';
const String nextAvailableCounterKey = 'VC_NEXT_AVAILABLE_COUNTER';

class VectorClockService {
  Future<void> increment() async {
    int next = await getNextAvailableCounter() + 1;
    setNextAvailableCounter(next);
  }

  Future<String> setNewHost() async {
    String host = uuid.v4();
    SecureStorage.writeValue(hostKey, host);
    return host;
  }

  Future<String> getHost() async {
    String? host = await SecureStorage.readValue(hostKey);
    host ??= await setNewHost();
    return host;
  }

  Future<void> setNextAvailableCounter(int nextAvailableCounter) async {
    SecureStorage.writeValue(
      nextAvailableCounterKey,
      nextAvailableCounter.toString(),
    );
  }

  Future<int> getNextAvailableCounter() async {
    int? nextAvailableCounter;
    String? nextAvailableCounterString =
        await SecureStorage.readValue(nextAvailableCounterKey);

    if (nextAvailableCounterString != null) {
      nextAvailableCounter = int.parse(nextAvailableCounterString);
    } else {
      nextAvailableCounter = 0;
      await setNextAvailableCounter(nextAvailableCounter);
    }
    return nextAvailableCounter;
  }

  Future<String> getHostHash() async {
    var bytes = utf8.encode(await getHost());
    var digest = sha1.convert(bytes);
    return digest.toString();
  }

  // TODO: only increment after successful insertion
  Future<VectorClock> getNextVectorClock({VectorClock? previous}) async {
    String host = await getHost();
    int nextAvailableCounter = await getNextAvailableCounter();
    increment();

    return VectorClock({
      ...?previous?.vclock,
      host: nextAvailableCounter,
    });
  }
}
