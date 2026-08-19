import '../../feed/models/post_model.dart';

class ProfileData {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? email;
  final String? bio;
  final String? relationshipStatus;
  final bool showRelationshipStatus;

  const ProfileData({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.email,
    this.bio,
    this.relationshipStatus,
    this.showRelationshipStatus = false,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      bio: json['bio'] as String?,
      relationshipStatus: json['relationship_status'] as String?,
      showRelationshipStatus: json['show_relationship_status'] as bool? ?? false,
    );
  }
}

class ProfileState {
  final ProfileData? profile;
  final List<PostModel> posts;
  final int followersCount;
  final int followingCount;
  final int totalLikes;
  final bool isFollowing;

  const ProfileState({
    this.profile,
    this.posts = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.totalLikes = 0,
    this.isFollowing = false,
  });

  ProfileState copyWith({
    ProfileData? profile,
    List<PostModel>? posts,
    int? followersCount,
    int? followingCount,
    int? totalLikes,
    bool? isFollowing,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      posts: posts ?? this.posts,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      totalLikes: totalLikes ?? this.totalLikes,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
