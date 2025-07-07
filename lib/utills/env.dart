import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'JIMENG_SC_KEY', obfuscate: true)
  static final String jimengScKey = _Env.jimengScKey;

  @EnviedField(varName: 'JIMENG_KEY_ID', obfuscate: true)
  static final String jimengKeyId = _Env.jimengKeyId;

  @EnviedField(varName: 'YIJU_APP_ID', obfuscate: true)
  static final String yijuAppId = _Env.yijuAppId;

  @EnviedField(varName: 'YIJU_APP_SC', obfuscate: true)
  static final String yijuAppSc = _Env.yijuAppSc;

  @EnviedField(varName: 'BACKEND_API_URL', obfuscate: true)
  static final String backendApiUrl = _Env.backendApiUrl;
}