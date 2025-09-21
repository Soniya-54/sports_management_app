// lib/screens/team_finder_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'create_post_screen.dart';

class TeamFinderScreen extends StatefulWidget {
  const TeamFinderScreen({super.key});

  @override
  State<TeamFinderScreen> createState() => _TeamFinderScreenState();
}

class _TeamFinderScreenState extends State<TeamFinderScreen> {
  String? _joiningPostId; // To show a loading indicator on a specific post

  Future<void> _joinTeam(DocumentSnapshot post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postData = post.data() as Map<String, dynamic>;
    final postId = post.id;
    final joinedPlayerIds = List<String>.from(postData['joinedPlayerIds'] ?? []);
    final playersNeeded = postData['playersNeeded'] ?? 0;

    // Safety checks
    if (postData['postedByUserId'] == user.uid) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You can't join your own post.")));
      return;
    }
    if (joinedPlayerIds.contains(user.uid)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You have already joined this team.")));
      return;
    }
    if (joinedPlayerIds.length >= playersNeeded) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("This team is already full.")));
      return;
    }
    
    setState(() { _joiningPostId = postId; });

    try {
      // Atomically add the current user's ID to the 'joinedPlayerIds' array
      await FirebaseFirestore.instance.collection('team_posts').doc(postId).update({
        'joinedPlayerIds': FieldValue.arrayUnion([user.uid]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the team!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join team: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) { setState(() { _joiningPostId = null; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Team'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('team_posts').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No teams are looking for players right now.'));
          }
          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postData = post.data() as Map<String, dynamic>;
              final gameDate = (postData['gameDate'] as Timestamp).toDate();
              final formattedDate = DateFormat.yMMMd().format(gameDate);

              // Determine the button state for the current user and post
              final joinedPlayerIds = List<String>.from(postData['joinedPlayerIds'] ?? []);
              final playersNeeded = postData['playersNeeded'] ?? 0;
              final isUserJoined = user != null && joinedPlayerIds.contains(user.uid);
              final isPostFull = joinedPlayerIds.length >= playersNeeded;
              final isMyPost = user != null && postData['postedByUserId'] == user.uid;
              final isLoading = _joiningPostId == post.id;
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  isThreeLine: true, // Allows for more space in the subtitle
                  leading: const Icon(Icons.group_add, size: 40),
                  title: Text(
                    'Need ${playersNeeded - joinedPlayerIds.length} for ${postData['sportType']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'At: ${postData['venueName']}\nOn: $formattedDate at ${postData['gameTime']}\nJoined: ${joinedPlayerIds.length} / $playersNeeded',
                  ),
                  trailing: isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: isUserJoined || isPostFull || isMyPost ? null : () => _joinTeam(post),
                        child: Text(isMyPost ? 'Your Post' : isUserJoined ? 'Joined' : isPostFull ? 'Full' : 'Join'),
                      ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreatePostScreen()));
        },
        child: const Icon(Icons.add),
        tooltip: 'Create a post',
      ),
    );
  }
}