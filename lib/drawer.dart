import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubDrawer extends StatelessWidget {
  final void Function(String enteredText) onSubmitted;
  final void Function(String subreddit) onSavedSubredditTap;
  final void Function(String subreddit) onDeleteSubredditTap;
  final List<String> savedSubs;

  const SubDrawer({
    this.onSubmitted,
    this.onSavedSubredditTap,
    this.onDeleteSubredditTap,
    this.savedSubs,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color(0xFF121212),
        child: ListView(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                onSubmitted: (String enteredText) {
                  onSubmitted(enteredText);
                },
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey, width: 2.0),
                  ),
                  hintText: 'Enter a subreddit',
                  hintStyle: GoogleFonts.inter(),
                ),
              ),
            ),
            ..._buildSavedSubs(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSavedSubs() {
    List<Widget> widgetSubs = [];
    if (savedSubs != null) {
      for (var sub in savedSubs) {
        widgetSubs.add(
          _buildSavedSub(sub),
        );
      }
    }
    return widgetSubs;
  }

  Widget _buildSavedSub(String title) {
    return Material(
      color: Color(0xFF121212),
      child: ListTile(
        title: Text(
          'r/$title',
          style: GoogleFonts.inter(),
        ),
        trailing: IconButton(
          icon: Icon(Icons.remove),
          onPressed: () {
            onDeleteSubredditTap(title);
          },
        ),
        onTap: () {
          onSavedSubredditTap(title);
        },
      ),
    );
  }
}
