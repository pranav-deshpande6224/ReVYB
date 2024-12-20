import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:resell/Authentication/android_ios/Models/new_user.dart';
import 'package:resell/Authentication/android_ios/screens/email_verification_a_i.dart';
import 'package:resell/UIPart/android_ios/screens/bottom_nav_a_i.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthHandler {
  static AuthHandler authHandlerInstance = AuthHandler();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final fireStore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  NewUser newUser = NewUser();

  showErrorDialog(BuildContext context, String title, String content) {
    if (Platform.isIOS) {
      showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return CupertinoAlertDialog(
              title: Text(
                title,
                style: GoogleFonts.lato(),
              ),
              content: Text(
                content,
                style: GoogleFonts.lato(),
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text(
                    'Okay',
                    style: GoogleFonts.lato(),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                )
              ],
            );
          });
    } else if (Platform.isAndroid) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              title,
              style: GoogleFonts.lato(),
            ),
            content: Text(
              content,
              style: GoogleFonts.lato(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  'Okay',
                  style: GoogleFonts.lato(color: Colors.blue),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> signUp(String email, String password, BuildContext context,
      BuildContext signUpContext, String fName) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      newUser.user = userCredential.user;
      newUser.user!.updateDisplayName(fName);
      if (!context.mounted) return;
      await storeSignUpData(context, email, fName);
      if (!context.mounted) return;
      Navigator.pop(signUpContext);
      if (Platform.isIOS) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (ctx) => EmailVerificationAI(
              email: email,
            ),
          ),
        );
      } else if (Platform.isAndroid) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => EmailVerificationAI(email: email),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        if (!context.mounted) return;
        Navigator.pop(signUpContext);
        showErrorDialog(context, 'Alert', 'The password provided is too weak');
      } else if (e.code == 'email-already-in-use') {
        if (!context.mounted) return;
        Navigator.pop(signUpContext);
        showErrorDialog(context, 'Alert', 'Email already in use');
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(signUpContext);
      showErrorDialog(context, 'Alert', e.toString());
    }
  }

  Future<void> signIn(String email, String password, BuildContext context,
      BuildContext loginContext) async {
    try {
      await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      newUser.user = firebaseAuth.currentUser;
      if (newUser.user!.emailVerified) {
        final pref = await SharedPreferences.getInstance();
        await pref.setString('uid', newUser.user!.uid);
        if (!context.mounted) return;
        Navigator.of(loginContext).pop();
        if (Platform.isIOS) {
          Navigator.of(context).pushAndRemoveUntil(
            CupertinoPageRoute(
              builder: (context) => const BottomNavAI(),
            ),
            (Route<dynamic> route) => false,
          );
        } else if (Platform.isAndroid) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const BottomNavAI(),
            ),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        if (!context.mounted) return;
        Navigator.of(loginContext).pop();
        if (Platform.isIOS) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (ctx) => EmailVerificationAI(
                email: email,
              ),
            ),
          );
        } else if (Platform.isAndroid) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => EmailVerificationAI(
                email: email,
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        if (!context.mounted) return;
        Navigator.of(loginContext).pop();
        showErrorDialog(context, 'Alert',
            "You might not have an account, or your password could be wrong.");
      } else if (e.code == 'too-many-requests') {
        if (!context.mounted) return;
        Navigator.of(loginContext).pop();
        showErrorDialog(context, 'Alert',
            "You have entered wrong password too many times. Please try again later.");
      } else {
        showErrorDialog(context, 'Alert', e.toString());
      }
    }
  }

  Future<void> googleSignIn(WidgetRef ref, BuildContext context,
      BuildContext googleSignInContext) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      final googleAuth = await googleUser?.authentication;
      if (googleAuth != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await firebaseAuth.signInWithCredential(credential);
        User? user = firebaseAuth.currentUser;
        if (user != null) {
          final isUserExists = await checkUserExistOrNot(user.email!);
          if (!isUserExists) {
            // this means user is done with googlesignin
            if (!context.mounted) return;
            newUser.user = user;
            await storeSignUpData(
                context, newUser.user!.email!, newUser.user!.displayName!);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('uid', newUser.user!.uid);
            if (context.mounted) {
              Navigator.of(googleSignInContext).pop();
              moveToHome(context);
            }
          } else {
            //user already there
            final userName = await getName(user.email!);
            newUser.user = user;
            await newUser.user!.updateDisplayName(userName);
            await newUser.user!.reload();
            newUser.user = firebaseAuth.currentUser;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('uid', newUser.user!.uid);
            if (context.mounted) {
              Navigator.of(googleSignInContext).pop();
              moveToHome(context);
            }
          }
        }
      } else {
        if (!googleSignInContext.mounted) return;
        Navigator.of(googleSignInContext).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      Navigator.of(googleSignInContext).pop();
      showErrorDialog(context, 'Alert', e.toString());
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(googleSignInContext).pop();
    }
  }

  void moveToHome(BuildContext context) {
    if (Platform.isIOS) {
      Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(
          builder: (context) => const BottomNavAI(),
        ),
        (Route<dynamic> route) => false,
      );
    } else if (Platform.isAndroid) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const BottomNavAI(),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> storeSignUpData(
      BuildContext context, String email, String firstName) async {
    if (newUser.user != null) {
      try {
        await fireStore.collection('users').doc(newUser.user!.uid).set(
          {
            'email': email,
            'firstName': firstName,
            'online': true,
            'lastSeen': DateTime.now().millisecondsSinceEpoch,
            'fcmToken': ''
          },
        );
      } catch (e) {
        if (!context.mounted) return;
        showErrorDialog(context, 'Alert', e.toString());
      }
    }
  }

  Future<void> storeFCMToken(String token) async {
    if (newUser.user != null) {
      try {
        await fireStore
            .collection('users')
            .doc(newUser.user!.uid)
            .update({'fcmToken': token});
      } catch (e) {
        // HANDLE THIS CASE OF ERROR LATER
      }
    }
  }

  void sendLinkToEmail() {
    if (newUser.user != null) {
      newUser.user!.sendEmailVerification();
    }
  }

  Future<bool> checkUserExistOrNot(String email) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await fireStore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  Future<String> getName(String email) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await fireStore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      String name = querySnapshot.docs.first.data()['firstName'];
      return name;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> forgetPassword(String email, BuildContext context,
      BuildContext foregetPasswordContext) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      if (!context.mounted) return;
      Navigator.of(foregetPasswordContext).pop();
      FocusScope.of(context).unfocus();
      showAlert(context, email);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      Navigator.of(foregetPasswordContext).pop();
      showErrorDialog(
        context,
        'Alert',
        e.toString(),
      );
    }
  }

  void showAlert(BuildContext context, String email) {
    if (Platform.isAndroid) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              'Alert',
              style: GoogleFonts.lato(),
            ),
            content: Text(
              'Reset Password link has been sent to your Email: $email',
              style: GoogleFonts.lato(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Okay',
                  style: GoogleFonts.lato(
                    color: Colors.blue,
                  ),
                ),
              )
            ],
          );
        },
      );
    } else if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            'Alert',
            style: GoogleFonts.lato(),
          ),
          content: Text(
            'Reset Password link has been sent to your Email: $email',
            style: GoogleFonts.lato(),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> changingUserToOnline() async {
    await fireStore.collection('users').doc(newUser.user!.uid).update(
      {
        'online': true,
      },
    );
  }

  Future<void> changeTheLastSeenTime() async {
    await fireStore.collection('users').doc(newUser.user!.uid).update(
        {'lastSeen': DateTime.now().millisecondsSinceEpoch, 'online': false});
  }
}
