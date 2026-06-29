import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final _remoteConfig = FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    await _remoteConfig.setDefaults({
      'ios_payment_enabled': true,
    });

    await _remoteConfig.fetchAndActivate();
  }

  static bool get iosPaymentEnabled =>
      _remoteConfig.getBool('ios_payment_enabled');
}