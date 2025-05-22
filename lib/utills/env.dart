import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'JIMENG_SC_KEY', obfuscate: true)
  static final String jimengScKey = _Env.jimengScKey;

  @EnviedField(varName: 'JIMENG_KEY_ID', obfuscate: true)
  static final String jimengKeyId = _Env.jimengKeyId;
}