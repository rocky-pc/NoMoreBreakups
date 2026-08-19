import '../../feed/models/post_model.dart';

class ProfileState {
  final List<PostModel> posts;
  final int followersCount;
  final int followingCount;
  final int totalLikes;

  const ProfileState({
    this.posts = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.totalLikes = 0,
  });

  ProfileState copyWith({
    List<PostModel>? posts,
    int? followersCount,
    int? followingCount,
    int? totalLikes,
  }) {
    return ProfileState(
      posts: posts ?? this.posts,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      totalLikes: totalLikes ?? this.totalLikes,
    );
  }
}
