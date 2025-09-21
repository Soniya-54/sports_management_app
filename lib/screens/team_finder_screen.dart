// lib/screens/team_finder_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'create_post_screen.dart';

class TeamFinderScreen extends StatelessWidget {
  const TeamFinderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Team'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query the 'team_posts' collection, order by newest first.
        stream: FirebaseFirestore.instance
            .collection('team_posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No teams are looking for players right now.'),
            );
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final postData = posts[index].data() as Map<String, dynamic>;
              final gameDate = (postData['gameDate'] as Timestamp).toDate();
              final formattedDate = DateFormat.yMMMd().format(gameDate); // e.g., "Sep 21, 2025"

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  leading: const Icon(Icons.group_add),
                  title: Text(
                    'Need ${postData['playersNeeded']} for ${postData['sportType']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'At ${postData['venueName']} on $formattedDate at ${postData['gameTime']}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement "Join Team" logic
                    },
                    child: const Text('Join'),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        // V-- 2. UPDATE THE ONPRESSED FUNCTION --V
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Create a post',
      ),
    );
  }
}