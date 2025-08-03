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
        final data = {
          'type': 'timer_update',
          'remainingTime': _remainingTime,
        };
        print('准备发送数据到主线程: $data');
        FlutterForegroundTask.sendDataToMain(data);
        print('数据已发送到主线程');
        
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
          final completedData = {'type': 'timer_completed'};
          print('准备发送完成数据到主线程: $completedData');
          FlutterForegroundTask.sendDataToMain(completedData);
          print('完成数据已发送到主线程');
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
         // ignore: invalid_use_of_visible_for_testing_member
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
       
       // 设置全局监听器而不是直接监听器
       if (!_isGlobalListenerSetup) {
         _setupGlobalListener();
       }
       
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

  // 全局数据回调函数列表
  static final List<Function(dynamic)> _dataCallbacks = [];
  static bool _isGlobalListenerSetup = false;
  
  // 流控制器
  static StreamController<dynamic>? _streamController;
  static Stream<dynamic>? _dataStream;
  
  // 获取数据流
  static Stream<dynamic> get dataStream {
    if (_streamController == null) {
      _streamController = StreamController<dynamic>.broadcast();
      _dataStream = _streamController!.stream;
      print('创建前台服务数据流');
    }
    return _dataStream!;
  }
  
  // 监听前台服务数据（回调方式，保持向后兼容）
  static void listenToForegroundService(Function(dynamic) onData) {
    print('添加前台服务数据回调');
    
    // 添加回调函数到列表
    _dataCallbacks.add(onData);
    
    // 如果全局监听器还没有设置，则设置一次
    if (!_isGlobalListenerSetup) {
      _setupGlobalListener();
    }
  }
  
  // 设置流监听器
  static void setupListener() {
    print('设置前台服务流监听器');
    if (!_isGlobalListenerSetup) {
      _setupGlobalListener();
    }
  }
  
  // 直接设置监听器
  
  // 移除数据回调
  static void removeDataCallback(Function(dynamic) onData) {
    _dataCallbacks.remove(onData);
    print('移除前台服务数据回调，剩余回调数量: ${_dataCallbacks.length}');
  }
  
  // 设置全局监听器（只设置一次）
  static void _setupGlobalListener() {
    if (_isGlobalListenerSetup) {
      print('全局监听器已经设置，跳过');
      return;
    }
    
    print('开始设置全局前台服务监听器');
    
    // 确保流控制器已创建
    if (_streamController == null) {
      _streamController = StreamController<dynamic>.broadcast();
      _dataStream = _streamController!.stream;
      print('创建前台服务数据流');
    }
    
    // 尝试设置监听器
    _attemptSetupListener(0);
  }
  
  // 递归尝试设置监听器
  static void _attemptSetupListener(int attempt) {
    if (attempt >= 10) {
      print('前台服务监听器设置失败，已达到最大尝试次数');
      return;
    }
    
    // ignore: invalid_use_of_visible_for_testing_member
    final receivePort = FlutterForegroundTask.receivePort;
    if (receivePort != null) {
      try {
        // 先取消任何现有的订阅
        if (_dataSubscription != null) {
          print('取消现有的数据订阅');
          _dataSubscription!.cancel();
          _dataSubscription = null;
        }
        
        _dataSubscription = receivePort.listen((data) {
          print('全局监听器收到数据: $data，分发给 ${_dataCallbacks.length} 个回调');
          
          // 分发数据给流控制器
          if (_streamController != null && !_streamController!.isClosed) {
            _streamController!.add(data);
            print('数据已添加到流控制器');
          }
          
          // 分发数据给所有注册的回调函数（保持向后兼容）
          for (final callback in _dataCallbacks) {
            try {
              callback(data);
            } catch (e) {
              print('回调函数执行出错: $e');
            }
          }
        });
        _isGlobalListenerSetup = true;
        print('全局前台服务监听器设置成功');
      } catch (e) {
        print('设置监听器时出错: $e');
        // 如果是Stream已被监听的错误，尝试使用现有的监听器
        if (e.toString().contains('Stream has already been listened to')) {
          print('检测到Stream已被监听，尝试使用现有监听器');
          _isGlobalListenerSetup = true;
          // 尝试通过定时器模拟数据接收，作为备用方案
          _setupFallbackDataSource();
          return;
        }
        Future.delayed(const Duration(milliseconds: 1000), () {
          _attemptSetupListener(attempt + 1);
        });
      }
    } else {
      print('前台服务receivePort为空，第${attempt + 1}次尝试，1000ms后重试');
      Future.delayed(const Duration(milliseconds: 1000), () {
        _attemptSetupListener(attempt + 1);
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

  // 备用数据源 - 当无法直接监听receivePort时使用
  static Timer? _fallbackTimer;
  static int _lastKnownTime = 0;
  
  static void _setupFallbackDataSource() {
    print('设置备用数据源');
    
    // 取消现有的备用计时器
    _fallbackTimer?.cancel();
    
    // 创建一个定时器来检查前台服务状态
    _fallbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 尝试从前台服务获取当前状态
      // 这里我们模拟计时器数据，实际应用中可以通过其他方式获取
      if (_streamController != null && !_streamController!.isClosed) {
        // 模拟计时器更新数据
        if (_lastKnownTime > 0) {
          _lastKnownTime--;
          final data = {
            'type': 'timer_update',
            'remainingTime': _lastKnownTime
          };
          _streamController!.add(data);
          print('备用数据源发送数据: $data');
          
          if (_lastKnownTime <= 0) {
            final completionData = {'type': 'timer_completed'};
            _streamController!.add(completionData);
            timer.cancel();
          }
        }
      } else {
        timer.cancel();
      }
    });
  }
  
  // 设置初始时间（供备用数据源使用）
  static void setInitialTime(int seconds) {
    _lastKnownTime = seconds;
    print('设置初始时间: $_lastKnownTime 秒');
  }
}