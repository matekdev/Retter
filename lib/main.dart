import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutterreddit/common/loadingPostIndicator.dart';
import 'package:flutterreddit/common/popupMenu.dart';
import 'package:flutterreddit/common/config.dart';
import 'package:flutterreddit/common/pullToRefresh.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterreddit/mainpage_viewmodel.dart';
import 'package:flutterreddit/common/subredditPost.dart';
import 'package:flutterreddit/drawer.dart';
import 'package:flutterreddit/common/launchURL.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Config config = Config(
    isAndroid: Platform.isAndroid,
    sharedPreferences: await SharedPreferences.getInstance(),
  );

  runApp(MaterialApp(
    title: 'Retter',
    theme: ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xFF030303),
      accentColor: Colors.blueAccent,
      splashColor: Colors.blueGrey,
    ),
    home: MainPage(
      viewModel: MainPageViewModel(
        reddit: await config.onAppOpenLogin(),
        config: config,
      ),
    ),
  ));
}

class MainPage extends StatelessWidget {
  final MainPageViewModel viewModel;

  const MainPage({this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      return Scaffold(
        backgroundColor: Color(0xFF121212),
        resizeToAvoidBottomInset: false,
        drawer: _buildDrawer(context),
        body: _buildCustomScrollView(context),
      );
    });
  }

  Widget _buildDrawer(BuildContext context) {
    return Observer(builder: (_) {
      return SubDrawer(
        savedSubs: viewModel.savedSubs,
        onSavedSubredditTap: (String subredditClicked) {
          viewModel.changeToSubreddit(subredditClicked);
          Navigator.pop(context);
        },
        onSubmitted: (String enteredText) {
          viewModel.changeToSubreddit(enteredText);
          Navigator.pop(context);
        },
        onDeleteSubredditTap: (String subredditDeleted) {
          viewModel.deleteSubreddit(subredditDeleted);
        },
      );
    });
  }

  Widget _buildTitle() {
    return Observer(builder: (_) {
      return Text(
        'r/${viewModel.currentSubreddit != null ? viewModel.currentSubreddit.displayName : viewModel.defaultSubredditString}',
        style: GoogleFonts.inter(),
      );
    });
  }

  Widget _buildCustomScrollView(BuildContext context) {
    return CustomScrollView(
      physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      controller: viewModel.scrollController,
      slivers: <Widget>[
        SliverAppBar(
          floating: true,
          flexibleSpace: FlexibleSpaceBar(
            title: _buildTitle(),
          ),
          actions: [
            Observer(builder: (_) {
              return CustomPopupMenu(
                isLoggedIn: viewModel?.redditor != null,
                onTap: (popupMenuOptions optionSelected) async {
                  switch (optionSelected) {
                    case popupMenuOptions.Login:
                      await viewModel.login();
                      break;
                    case popupMenuOptions.Logout:
                      await viewModel.logout();
                      break;
                  }
                },
              );
            }),
          ],
        ),
        CupertinoSliverRefreshControl(
          builder: (
            BuildContext context,
            RefreshIndicatorMode refreshState,
            double pulledExtent,
            double refreshTriggerPullDistance,
            double refreshIndicatorExtent,
          ) {
            return buildPullToRefresh(
              context,
              refreshState,
              pulledExtent,
              refreshTriggerPullDistance,
              refreshIndicatorExtent,
            );
          },
          onRefresh: () async {
            viewModel.refreshPosts();
          },
        ),
        if (viewModel.loadedPostSuccessfully) _buildPosts(context),
      ],
    );
  }

  Widget _buildPosts(BuildContext context) {
    return Observer(builder: (_) {
      return SliverList(
        delegate: SliverChildListDelegate(
          List.generate(viewModel.submissionContent.length + 1, (index) {
            var isLastIndex = index == viewModel.submissionContent.length;
            if (isLastIndex && !viewModel.hasLoadedAllAvailablePosts) {
              return buildLoadingPostIndicator('Loading posts...');
            } else if (isLastIndex && viewModel.hasLoadedAllAvailablePosts) {
              return Container();
            }

            var submissionData = viewModel.submissionContent.elementAt(index);
            return SubredditPost(
              context: context,
              submissionData: submissionData,
              isViewingPost: false,
              isLoggedIn: viewModel?.redditor != null,
              onSubredditTap: (String enteredText) {
                viewModel.changeToSubreddit(enteredText);
              },
              onProfileTap: (String username) {
                // TODO: Setup profile page
                // viewModel.goToProfilePage(
                //   context,
                //   username,
                // );
              },
              onTap: () async {
                if (submissionData.isSelf) {
                  viewModel.goToPostPage(
                    context,
                    submissionData,
                    viewModel.changeToSubreddit,
                    (String username) {
                      // TODO: setup profile page
                      // viewModel.goToProfilePage(context, username);
                    },
                  );
                } else {
                  await launchURL(submissionData.url.toString());
                }
              },
              onCommentTap: () {
                viewModel.goToPostPage(
                  context,
                  submissionData,
                  viewModel.changeToSubreddit,
                  (String username) {
                    // TODO: go to profile page
                    // viewModel.goToProfilePage(context, username);
                  },
                );
              },
            );
          }),
        ),
      );
    });
  }
}
