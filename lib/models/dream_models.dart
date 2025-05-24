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
  final String? bio;
  final int? dreamCount;
  final int? followersCount;
  final int? followingCount;

  DreamUser({
    required this.id,
    required this.nickname,
    required this.avatar,
    this.email,
    this.bio,
    this.dreamCount,
    this.followersCount,
    this.followingCount,
  });

  // 从JSON创建DreamUser对象
  factory DreamUser.fromJson(Map<String, dynamic> json) {
    return DreamUser(
      id: json['id'].toString(),
      nickname: json['nickname'] ?? '',
      avatar: json['avatar'] ?? '',
      email: json['email'],
      bio: json['bio'],
      dreamCount: json['dreamCount'],
      followersCount: json['followersCount'],
      followingCount: json['followingCount'],
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'avatar': avatar,
      'email': email,
      'bio': bio,
      'dreamCount': dreamCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
    };
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