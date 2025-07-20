// API用户模型（匹配后端API结构）
class ApiUser {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatar;
  final bool isActive;
  final bool isSuperuser;
  final String pointsBalance;
  final String totalPointsEarned;
  final String totalPointsSpent;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApiUser({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.phone,
    this.avatar,
    required this.isActive,
    required this.isSuperuser,
    required this.pointsBalance,
    required this.totalPointsEarned,
    required this.totalPointsSpent,
    required this.createdAt,
    required this.updatedAt,
  });

  // 从JSON创建ApiUser对象
  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'],
      phone: json['phone'],
      avatar: json['avatar'],
      isActive: json['is_active'] ?? true,
      isSuperuser: json['is_superuser'] ?? false,
      pointsBalance: json['points_balance'] ?? '0',
      totalPointsEarned: json['total_points_earned'] ?? '0',
      totalPointsSpent: json['total_points_spent'] ?? '0',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar': avatar,
      'is_active': isActive,
      'is_superuser': isSuperuser,
      'points_balance': pointsBalance,
      'total_points_earned': totalPointsEarned,
      'total_points_spent': totalPointsSpent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 转换为应用内DreamUser模型
  DreamUser toDreamUser() {
    return DreamUser(
      id: id.toString(),
      nickname: fullName ?? username,
      avatar: avatar ?? '',
      email: email,
      phone: phone,
      points: int.tryParse(pointsBalance) ?? 0, // 使用实际积分余额
      dreamCount: 0,
      followersCount: 0,
      followingCount: 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: isActive ? 'active' : 'inactive',
    );
  }
}

// 用户注册请求模型
class UserCreateRequest {
  final String username;
  final String email;
  final String password;
  final String? fullName;
  final String? phone;
  final String? avatar;

  UserCreateRequest({
    required this.username,
    required this.email,
    required this.password,
    this.fullName,
    this.phone,
    this.avatar,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'avatar': avatar,
    };
  }
}

// 用户登录请求模型
class UserLoginRequest {
  final String username;
  final String password;

  UserLoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

// 用户更新请求模型
class UserUpdateRequest {
  final String? fullName;
  final String? phone;
  final String? avatar;

  UserUpdateRequest({
    this.fullName,
    this.phone,
    this.avatar,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (fullName != null) data['full_name'] = fullName;
    if (phone != null) data['phone'] = phone;
    if (avatar != null) data['avatar'] = avatar;
    return data;
  }
}

// 登录响应Token模型
class AuthToken {
  final String accessToken;
  final String tokenType;

  AuthToken({
    required this.accessToken,
    required this.tokenType,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
    };
  }
}

// 邮箱验证码发送请求模型
class EmailVerificationRequest {
  final String email;
  final String? action;

  EmailVerificationRequest({
    required this.email,
    this.action,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      if (action != null) 'action': action,
    };
  }
}

// 邮箱验证码验证请求模型
class EmailCodeVerifyRequest {
  final String email;
  final String code;
  final String? action;

  EmailCodeVerifyRequest({
    required this.email,
    required this.code,
    this.action,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
      if (action != null) 'action': action,
    };
  }
}

// 带验证码的用户注册请求模型
class UserCreateWithVerificationRequest {
  final String username;
  final String email;
  final String password;
  final String verificationCode;
  final String? fullName;
  final String? phone;
  final String? avatar;

  UserCreateWithVerificationRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.verificationCode,
    this.fullName,
    this.phone,
    this.avatar,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'verification_code': verificationCode,
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (avatar != null) 'avatar': avatar,
    };
  }
}

// 邮箱验证码登录请求模型
class EmailLoginRequest {
  final String email;
  final String verificationCode;

  EmailLoginRequest({
    required this.email,
    required this.verificationCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'verification_code': verificationCode,
    };
  }
}

// 验证码响应模型
class EmailVerificationResponse {
  final bool success;
  final String message;
  final String? code;

  EmailVerificationResponse({
    required this.success,
    required this.message,
    this.code,
  });

  factory EmailVerificationResponse.fromJson(Map<String, dynamic> json) {
    return EmailVerificationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      code: json['code'],
    );
  }
}

// 用户注册响应模型（包含token）
class UserRegisterResponse {
  final ApiUser user;
  final String accessToken;
  final String tokenType;
  final String message;

  UserRegisterResponse({
    required this.user,
    required this.accessToken,
    required this.tokenType,
    required this.message,
  });

  factory UserRegisterResponse.fromJson(Map<String, dynamic> json) {
    return UserRegisterResponse(
      user: ApiUser.fromJson(json['user']),
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'access_token': accessToken,
      'token_type': tokenType,
      'message': message,
    };
  }
}

// API响应包装模型
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? true,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'],
      errors: json['errors'],
    );
  }
}

// 梦境帖子模型
class DreamPost {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final DreamUser author;
  final int likes;
  final int comments;
  final List<String> tags;
  final DateTime publishTime;
  final String category;

  DreamPost({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.author,
    required this.likes,
    required this.comments,
    required this.tags,
    required this.publishTime,
    required this.category,
  });

  // 从JSON创建DreamPost对象
  factory DreamPost.fromJson(Map<String, dynamic> json) {
    return DreamPost(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      author: DreamUser.fromJson(json['author'] ?? {}),
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      publishTime: DateTime.tryParse(json['publishTime'] ?? '') ?? DateTime.now(),
      category: json['category'] ?? '',
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'author': author.toJson(),
      'likes': likes,
      'comments': comments,
      'tags': tags,
      'publishTime': publishTime.toIso8601String(),
      'category': category,
    };
  }

  // 复制并修改某些字段
  DreamPost copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    DreamUser? author,
    int? likes,
    int? comments,
    List<String>? tags,
    DateTime? publishTime,
    String? category,
  }) {
    return DreamPost(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      tags: tags ?? this.tags,
      publishTime: publishTime ?? this.publishTime,
      category: category ?? this.category,
    );
  }
}

// 用户模型
class DreamUser {
  final String id;
  final String nickname;
  final String avatar;
  final String? email;
  final String? phone;
  final String? bio;
  final int? dreamCount;
  final int? followersCount;
  final int? followingCount;
  final int? points; // 用户积分
  final String? wxOpenId; // 微信OpenID
  final String? wxUnionId; // 微信UnionID
  final DateTime? createdAt; // 创建时间
  final DateTime? updatedAt; // 更新时间
  final String? status; // 用户状态：active, banned, deleted

  DreamUser({
    required this.id,
    required this.nickname,
    required this.avatar,
    this.email,
    this.phone,
    this.bio,
    this.dreamCount,
    this.followersCount,
    this.followingCount,
    this.points,
    this.wxOpenId,
    this.wxUnionId,
    this.createdAt,
    this.updatedAt,
    this.status,
  });

  // 从JSON创建DreamUser对象
  factory DreamUser.fromJson(Map<String, dynamic> json) {
    return DreamUser(
      id: json['id'].toString(),
      nickname: json['nickname'] ?? '',
      avatar: json['avatar'] ?? '',
      email: json['email'],
      phone: json['phone'],
      bio: json['bio'],
      dreamCount: json['dreamCount'] ?? 0,
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      points: json['points'] ?? 0,
      wxOpenId: json['wxOpenId'],
      wxUnionId: json['wxUnionId'],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : null,
      status: json['status'] ?? 'active',
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'avatar': avatar,
      'email': email,
      'phone': phone,
      'bio': bio,
      'dreamCount': dreamCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'points': points,
      'wxOpenId': wxOpenId,
      'wxUnionId': wxUnionId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status,
    };
  }

  // 复制并修改某些字段
  DreamUser copyWith({
    String? id,
    String? nickname,
    String? avatar,
    String? email,
    String? phone,
    String? bio,
    int? dreamCount,
    int? followersCount,
    int? followingCount,
    int? points,
    String? wxOpenId,
    String? wxUnionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return DreamUser(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      dreamCount: dreamCount ?? this.dreamCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      points: points ?? this.points,
      wxOpenId: wxOpenId ?? this.wxOpenId,
      wxUnionId: wxUnionId ?? this.wxUnionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}

// 评论模型
class DreamComment {
  final String id;
  final String dreamId;
  final String authorId;
  final String content;
  final int likes;
  final DateTime createdAt;
  final DreamUser? author; // 可选，关联用户信息

  DreamComment({
    required this.id,
    required this.dreamId,
    required this.authorId,
    required this.content,
    required this.likes,
    required this.createdAt,
    this.author,
  });

  // 从JSON创建DreamComment对象
  factory DreamComment.fromJson(Map<String, dynamic> json) {
    return DreamComment(
      id: json['id'].toString(),
      dreamId: json['dreamId'].toString(),
      authorId: json['authorId'].toString(),
      content: json['content'] ?? '',
      likes: json['likes'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      author: json['author'] != null ? DreamUser.fromJson(json['author']) : null,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dreamId': dreamId,
      'authorId': authorId,
      'content': content,
      'likes': likes,
      'createdAt': createdAt.toIso8601String(),
      'author': author?.toJson(),
    };
  }
}

// 分类模型
class DreamCategory {
  final String id;
  final String name;
  final int count;

  DreamCategory({
    required this.id,
    required this.name,
    required this.count,
  });

  // 从JSON创建DreamCategory对象
  factory DreamCategory.fromJson(Map<String, dynamic> json) {
    return DreamCategory(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'count': count,
    };
  }
}

// 积分交易记录模型
class PointTransaction {
  final String id;
  final String userId;
  final int amount;
  final String type; // 'earn', 'spend', 'refund'
  final String description;
  final String? serviceType; // 'ai_analysis', 'image_generation', 'daily_checkin'
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // 额外的元数据

  PointTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    this.serviceType,
    required this.createdAt,
    this.metadata,
  });

  // 从JSON创建PointTransaction对象
  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      amount: json['amount'] ?? 0,
      type: json['type'] ?? 'earn',
      description: json['description'] ?? '',
      serviceType: json['serviceType'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      metadata: json['metadata'],
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'description': description,
      'serviceType': serviceType,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

// 订单模型
class Order {
  final String id;
  final String userId;
  final double amount; // 支付金额
  final int points; // 获得积分
  final String status; // 'pending', 'paid', 'failed', 'refunded'
  final String? paymentMethod; // 'wechat', 'alipay'
  final String? tradeNo; // 第三方交易号
  final DateTime createdAt;
  final DateTime? paidAt;
  final Map<String, dynamic>? metadata;

  Order({
    required this.id,
    required this.userId,
    required this.amount,
    required this.points,
    required this.status,
    this.paymentMethod,
    this.tradeNo,
    required this.createdAt,
    this.paidAt,
    this.metadata,
  });

  // 从JSON创建Order对象
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      amount: (json['amount'] ?? 0.0).toDouble(),
      points: json['points'] ?? 0,
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'],
      tradeNo: json['tradeNo'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
      metadata: json['metadata'],
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'points': points,
      'status': status,
      'paymentMethod': paymentMethod,
      'tradeNo': tradeNo,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

// 签到记录模型
class CheckInRecord {
  final String id;
  final String userId;
  final DateTime checkInDate;
  final int points; // 获得积分
  final int consecutiveDays; // 连续签到天数
  final DateTime createdAt;

  CheckInRecord({
    required this.id,
    required this.userId,
    required this.checkInDate,
    required this.points,
    required this.consecutiveDays,
    required this.createdAt,
  });

  // 从JSON创建CheckInRecord对象
  factory CheckInRecord.fromJson(Map<String, dynamic> json) {
    return CheckInRecord(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      checkInDate: DateTime.tryParse(json['checkInDate'] ?? '') ?? DateTime.now(),
      points: json['points'] ?? 0,
      consecutiveDays: json['consecutiveDays'] ?? 1,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'checkInDate': checkInDate.toIso8601String(),
      'points': points,
      'consecutiveDays': consecutiveDays,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// 积分任务模型
class PointTask {
  final String id;
  final String title;
  final String description;
  final int points; // 完成任务获得的积分
  final String type; // 'daily', 'weekly', 'monthly', 'one_time'
  final String? condition; // 任务条件
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  PointTask({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.type,
    this.condition,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  // 从JSON创建PointTask对象
  factory PointTask.fromJson(Map<String, dynamic> json) {
    return PointTask(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      points: json['points'] ?? 0,
      type: json['type'] ?? 'daily',
      condition: json['condition'],
      isActive: json['isActive'] ?? true,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'type': type,
      'condition': condition,
      'isActive': isActive,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}