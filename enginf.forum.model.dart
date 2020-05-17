import 'package:clientf/enginf_clientf_service/enginf.comment.model.dart';
import 'package:clientf/enginf_clientf_service/enginf.model.dart';
import 'package:clientf/enginf_clientf_service/enginf.post.model.dart';
import 'package:clientf/services/app.i18n.dart';
import 'package:clientf/services/app.service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 게시판 목록 (게시글 목록, 생성, 코멘트 생성 및 기타 기능) 하나에 대한 관련된 모델이다.
///
/// 각 페이지 별로 별도의 Model 이 생성된다.
/// 따라서 게시판 목록 페이지 별로 ChangeNotifer 를 해야 한다.
class EngineForumModel extends ChangeNotifier {
  String id;
  EngineModel f = EngineModel();

  List<EnginePost> posts = [];
  int limit = 10;

  bool loading = false;
  bool noMorePosts = false;

  bool disposed = false;

  final scrollController =
      ScrollController(initialScrollOffset: 0.0, keepScrollOffset: true);

  EngineForumModel();

  init({String id}) {
    this.id = id;
    print('init() forum id: ${this.id}');

    loadPage();

    scrollController.addListener(_scrollListener);
  }

  notifiyUpdates() {
    if (disposed) {
      print('model disposed: do not notify');
    } else {
      notifyListeners();
    }
  }

  loadPage() async {
    if (noMorePosts) {
      print('---------> No more posts on $id ! just return!');
      return;
    }
    loading = true;
    var req = {
      'categories': [id],
      'limit': limit,
      'includeComments': true,
    };
    if (posts.length > 0) {
      req['startAfter'] = posts[posts.length - 1].createdAt;
    }

    try {
      final _re = await f.postList(req);
      loading = false;
      if (_re.length < limit) {
        // print('---------> No more posts on $id !');
        noMorePosts = true;
      }
      // print('f.postList()');
      // print(_re);

      posts.addAll(_re);

      notifiyUpdates();

      // for (var _p in _re) {
      //   print(_p.title);
      // }
    } catch (e) {
      print(e);

      ///
      AppService.alert(null, t(e));
    }
  }

  void _scrollListener() {
    if (noMorePosts) {
      // print('---------> No more posts on $id ! just return!');
      return;
    }

    bool isBottom = scrollController.offset >=
        scrollController.position.maxScrollExtent - 200;

    if (!isBottom) return;
    if (loading) return;

    /// @warning `mount` check is needed here?

    print('_scrollListener() going to load on $id');
    loadPage();

    loading = true;
    notifiyUpdates();
  }

  updatePost(EnginePost post) {
    if (post == null) return;
    int i = posts.indexWhere((p) => p.id == post.id);
    posts.removeAt(i);
    posts.insert(i, post);
    notifiyUpdates();
  }

  /// 글의 코멘트 목록에 코멘트를 하나 끼워 넣는다.
  ///
  /// 코멘트 생성 시에 가짜(임시 코멘트) 정보를 넣을 수도 있다.
  ///
  /// @example
  /// ```dart
  ///   Provider.of<EngineForumModel>(context, listen: false)
  ///     .addComment(
  ///      commentToAdd, post, parentCommentId);
  /// ```
  addComment(comment, EnginePost post, String parentId, {bool notify: true}) {
    // var post =
    //     posts.firstWhere((post) => post.id == postId, orElse: () => null);
    // if (post == null) {
    //   print('addComment() critical error. This should never happened');
    //   return;
    // }

    var comments = post.comments;

    if (parentId != null) {
      var i = comments.indexWhere((c) => c.id == parentId);
      if (i == -1) {
        print(
            'addComment() critical error. finding comment. This should never happened');
        return;
      }

      /// Adding comment under another comment
      print(
          '--> No depth? Parent: comment[i]: ${comments[i]} /  Child: $comment');
      // comment.depth = comments[i].depth + 1;
      comments.insert(i + 1, comment);
    } else {
      comments.insert(0, comment);
    }

    // print('----> comment inserted');
    // print(comments);

    // for (var c in post.comments) { // test print
    //   print('content: ${c['content']}');
    // }
    if (notify) notifiyUpdates();
  }

  ///
  prepareCommentBox(EnginePost post) {
    post.tempComment = EngineComment();
  }
}

EngineForumModel forumModel(context) {
  return Provider.of<EngineForumModel>(context, listen: false);
}
