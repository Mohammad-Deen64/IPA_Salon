import 'package:dr_salon_app/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    ApiConfig.setRuntimeOverride(null);
  });

  test('default is the Render cloud host', () {
    expect(ApiConfig.platformDefault, 'https://dr-salon-ai-api.onrender.com');
    expect(ApiConfig.baseUrl, contains('onrender.com'));
  });

  test('runtime override wins over the platform default', () {
    ApiConfig.setRuntimeOverride('https://dr-salon-ai-api.onrender.com/');
    expect(ApiConfig.baseUrl, 'https://dr-salon-ai-api.onrender.com');
  });
}
