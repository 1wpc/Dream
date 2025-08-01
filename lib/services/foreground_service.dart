import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// 前台服务回调函数 - 必须是顶级函数
@pragma('vm:entry-point')
void startCallback() {
  print('前台服务回调函数被调用');
  FlutterForegroundTask.setTaskHandler(MeditationForegroundTaskHandler());
}

// 前台服务处理器
class MeditationForegroundTaskHandler extends TaskHandler {
  int _remainingTime = 0;
  bool _isRunning = false;
  Timer? _timer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('前台服务已启动: $timestamp, starter: $starter');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // 使用内部计时器处理
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _timer?.cancel();
    print('前台服务已销毁');
  }

  @override
  void onReceiveData(Object data) async {
    print('前台服务收到数据: $data');
    if (data is Map<String, dynamic>) {
      switch (data['action']) {
        case 'start_timer':
          _remainingTime = data['duration'] ?? 0;
          _isRunning = true;
          print('开始计时器，时长: $_remainingTime 秒');
          _startInternalTimer();
          break;
        case 'stop_timer':
          _isRunning = false;
          _remainingTime = 0;
          _timer?.cancel();
          print('停止计时器');
          break;
        case 'pause_timer':
          _isRunning = false;
          _timer?.cancel();
          print('暂停计时器');
          break;
        case 'resume_timer':
          _isRunning = true;
          print('恢复计时器');
          _startInternalTimer();
          break;
      }
    }
  }

  void _startInternalTimer() {
    _timer?.cancel();
    print('启动内部计时器，剩余时间: $_remainingTime 秒');
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning && _remainingTime > 0) {
        _remainingTime--;
        print('计时器更新: $_remainingTime 秒剩余');
        
        // 发送剩余时间到主线程
        FlutterForegroundTask.sendDataToMain({
          'type': 'timer_update',
          'remainingTime': _remainingTime,
        });
        
        // 更新通知
        FlutterForegroundTask.updateService(
          notificationTitle: '冥想进行中',
          notificationText: _formatTime(_remainingTime),
        );
        
        // 计时结束
        if (_remainingTime <= 0) {
          _isRunning = false;
          timer.cancel();
          print('计时器完成');
          FlutterForegroundTask.sendDataToMain({
            'type': 'timer_completed',
          });
        }
      } else {
        print('计时器停止: _isRunning=$_isRunning, _remainingTime=$_remainingTime');
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

// 前台服务管理类
class ForegroundServiceManager {
  static bool _isInitialized = false;
  static ReceivePort? _receivePort;
  static Function(int)? _onTimerUpdate;
  static Function()? _onTimerCompleted;
  static StreamSubscription? _dataSubscription;

  // 初始化前台服务
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'meditation_timer',
          channelName: '冥想计时器',
          channelDescription: '冥想计时器前台服务',
          channelImportance: NotificationChannelImportance.HIGH,
          priority: NotificationPriority.HIGH,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
        ),
      );

      // 不在初始化时设置 receivePort，等服务启动后再获取
      _isInitialized = true;
      print('前台服务初始化完成');
      return true;
    } catch (e) {
      print('前台服务初始化失败: $e');
      return false;
    }
  }

  // 启动冥想计时器
  static Future<bool> startMeditationTimer(int durationInSeconds) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
       // 启动前台服务
       await FlutterForegroundTask.startService(
         notificationTitle: '冥想计时器',
         notificationText: '准备开始冥想 ${_formatTime(durationInSeconds)}',
         callback: startCallback,
       );

       // 等待服务启动，增加等待时间
       await Future.delayed(const Duration(milliseconds: 2000));
       
       // 确认服务已启动
       final isRunning = await FlutterForegroundTask.isRunningService;
       if (!isRunning) {
         print('前台服务启动失败');
         return false;
       }
       
       // 多次尝试获取receivePort
       for (int i = 0; i < 5; i++) {
         _receivePort = FlutterForegroundTask.receivePort;
         if (_receivePort != null) {
           print('前台服务启动成功，receivePort获取成功，第${i+1}次尝试');
           break;
         }
         print('receivePort为空，第${i+1}次尝试，等待500ms后重试');
         await Future.delayed(const Duration(milliseconds: 500));
       }
       
       print('前台服务启动完成，receivePort状态: ${_receivePort != null}');
       
       // 发送启动计时器命令
       FlutterForegroundTask.sendDataToTask({
         'action': 'start_timer',
         'duration': durationInSeconds,
       });
       
       return true;
    } catch (e) {
      print('启动冥想计时器失败: $e');
      return false;
    }
  }

  // 停止冥想计时器
  static Future<bool> stopMeditationTimer() async {
    try {
      FlutterForegroundTask.sendDataToTask({
        'action': 'stop_timer',
      });
      
      await FlutterForegroundTask.stopService();
      return true;
    } catch (e) {
      print('停止冥想计时器失败: $e');
      return false;
    }
  }

  // 暂停计时器
  static void pauseTimer() {
    FlutterForegroundTask.sendDataToTask({
      'action': 'pause_timer',
    });
  }

  // 恢复计时器
  static void resumeTimer() {
    FlutterForegroundTask.sendDataToTask({
      'action': 'resume_timer',
    });
  }

  // 监听前台服务消息
  static void listenToForegroundService(Function(dynamic) onData) {
    print('设置前台服务数据监听器');
    
    // 取消之前的监听器
    _dataSubscription?.cancel();
    
    // 尝试多次获取receivePort，因为可能需要等待服务完全启动
    _setupListener(onData, 0);
  }
  
  // 递归设置监听器，最多尝试10次
  static void _setupListener(Function(dynamic) onData, int attempt) {
    if (attempt >= 10) {
      print('前台服务监听器设置失败，已达到最大尝试次数');
      return;
    }
    
    final receivePort = FlutterForegroundTask.receivePort;
    if (receivePort != null) {
      _dataSubscription = receivePort.listen((data) {
        print('前台服务监听器收到数据: $data');
        onData(data);
      });
      print('前台服务监听器设置成功');
    } else {
      print('前台服务receivePort为空，第${attempt + 1}次尝试，1000ms后重试');
      Future.delayed(const Duration(milliseconds: 1000), () {
        _setupListener(onData, attempt + 1);
      });
    }
  }



  // 格式化时间
  static String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // 检查前台服务是否正在运行
  static Future<bool> isServiceRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }

  // 请求权限
  static Future<bool> requestPermissions() async {
    try {
      // 请求通知权限
      final notificationPermission = await FlutterForegroundTask.requestNotificationPermission();
      print('通知权限: $notificationPermission');
      
      return notificationPermission == NotificationPermission.granted;
    } catch (e) {
      print('权限请求失败: $e');
      return false;
    }
  }
}