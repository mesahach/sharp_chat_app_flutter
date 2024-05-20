import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  var textInputController = TextEditingController();

  void _submitMessage() async {
    FocusScope.of(context).unfocus();

    final enteredText = textInputController.text;
    textInputController.clear();
    if (enteredText.trim().isEmpty) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    // send to firebase
    await FirebaseFirestore.instance.collection('chats').add({
      "text": enteredText,
      "createdAt": Timestamp.now(),
      "userId": user.uid,
      "username": userData.data()!['username'],
      "userImage": userData.data()!['image_url'],
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    textInputController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 15,
        bottom: 5,
        right: 1,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textInputController,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              enableSuggestions: true,
              enableInteractiveSelection: true,
              decoration: const InputDecoration(
                labelText: 'Send a message...',
              ),
            ),
          ),
          IconButton.filled(
            // color: Theme.of(context).colorScheme.primary,
            iconSize: 30,
            icon: const Icon(Icons.send),
            onPressed: _submitMessage,
          )
        ],
      ),
    );
  }
}
