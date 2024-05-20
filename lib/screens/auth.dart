import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailControler = TextEditingController();
  final passwordControler = TextEditingController();
  final usernameControler = TextEditingController();

  File? _selectedImgage;
  bool _isAuthenticating = false;

  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;

  void _submit() async {
    final email = emailControler.text.trim();
    final password = passwordControler.text.trim();
    final username = usernameControler.text.trim();

    final isValidate = _formKey.currentState!.validate();
    if (!isValidate) {
      return;
    }
    try {
      if (_isLogin) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        if (_selectedImgage == null) {
          return;
        }
        setState(() {
          _isAuthenticating = true;
        });

        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');

        await storageRef.putFile(_selectedImgage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': username,
          'email': email,
          'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        //
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? "Authentication failed.",
          ),
        ),
      );

      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    emailControler.dispose();
    passwordControler.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            UserImagePicker(
                              onPickedImage: (File pickedImage) {
                                _selectedImgage = pickedImage;
                              },
                            ),
                          if (!_isLogin)
                            TextFormField(
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: "Username",
                              ),
                              autocorrect: false,
                              autofocus: true,
                              textCapitalization: TextCapitalization.none,
                              controller: usernameControler,
                              validator: (value) {
                                if (value == null) {
                                  return "Please enter your valid username";
                                } else if (value.trim().isEmpty ||
                                    value.contains('@') ||
                                    value.trim().length < 4 ||
                                    value.trim().contains(RegExp(r'[A-Z]'))) {
                                  return "Usernam must be at least 4 strings, lowercase and no special characters";
                                }
                                return null;
                              },
                            ),
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "Email Address",
                            ),
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            controller: emailControler,
                            validator: (value) {
                              if (value == null) {
                                return "Please enter your email address";
                              } else if (value.trim().isEmpty ||
                                  !value.contains('@') ||
                                  !value.contains('.')) {
                                return "Please provide a valid email address";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 2),
                          TextFormField(
                            obscureText: true,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              labelText: "Password",
                            ),
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            controller: passwordControler,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  value.trim().length < 6) {
                                return "Type in your account password";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (!_isAuthenticating)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              onPressed: _submit,
                              child: Text(_isLogin ? 'Login' : 'Signup'),
                            ),
                          const SizedBox(height: 12),
                          if (_isAuthenticating)
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
                          if (!_isAuthenticating)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(_isLogin
                                  ? 'Create an account'
                                  : 'I already have an account'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
