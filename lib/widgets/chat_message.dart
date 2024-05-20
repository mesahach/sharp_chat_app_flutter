import 'package:chat_app/widgets/chart_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatefulWidget {
  const ChatMessages({super.key});

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  void setUpPushNotification() async {
    final firebaseMsg = FirebaseMessaging.instance;
    await firebaseMsg.requestPermission();
    final token = await firebaseMsg.getToken();

    firebaseMsg.subscribeToTopic('chat');
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setUpPushNotification();
  }

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (context, chatSnapshots) {
        if (chatSnapshots.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
          const Center(
            child: Text("No messages yet"),
          );
        }

        if (chatSnapshots.hasError) {
          const Center(
            child: Text("Some thing went wrong"),
          );
        }

        // if (chatSnapshots.hasData) {
        final loadedMessages = chatSnapshots.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.only(
            left: 13,
            right: 13,
            bottom: 40,
          ),
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (context, index) {
            final message = loadedMessages[index].data();
            final nextMessage = index + 1 < loadedMessages.length
                ? loadedMessages[index + 1].data()
                : null;

            final currentMessageUsernameId = message['userId'];
            final nextMessageUsernameId =
                nextMessage != null ? nextMessage['userId'] : null;
            final nextUserIsSame =
                nextMessageUsernameId == currentMessageUsernameId;

            if (nextUserIsSame) {
              return MessageBubble.next(
                message: message['text'],
                isMe: authenticatedUser.uid == currentMessageUsernameId,
              );
            } else {
              return MessageBubble.first(
                userImage: message['userImage'],
                username: message['username'],
                message: message['text'],
                isMe: authenticatedUser.uid == currentMessageUsernameId,
              );
            }
          },
        );
        // }
      },
    );
  }
}
