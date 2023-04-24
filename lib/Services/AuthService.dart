import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:taxi_driver/components/OTPDialog.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:taxi_driver/screens/DriverDashboardScreen.dart';
import 'package:taxi_driver/screens/VerifyDeliveryPersonScreen.dart';
import 'package:taxi_driver/utils/Extensions/StringExtensions.dart';

import '../main.dart';
import '../model/LoginResponse.dart';
import '../network/RestApis.dart';
import '../screens/DriverRegisterScreen.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class AuthServices {
  Future<void> updateUserData(UserData user) async {
    userService.updateDocument({
      'player_id': sharedPref.getString(PLAYER_ID),
      'updatedAt': Timestamp.now(),
    }, user.uid);
  }

  Future<void> signUpWithEmailPassword(
    context, {
    String? name,
    String? email,
    String? password,
    String? mobileNumber,
    String? fName,
    String? lName,
    String? userName,
    bool socialLoginName = false,
    String? userType,
    String? uID,
    bool isOtp = false,
    UserDetail? userDetail,
    int? serviceId,
    String? gender,
    bool isExist = true,
  }) async {
    UserCredential? userCredential = await _auth.createUserWithEmailAndPassword(email: email!, password: password!);
    if (userCredential.user != null) {
      User currentUser = userCredential.user!;

      UserData userModel = UserData();

      /// Create user
      userModel.uid = currentUser.uid.validate();
      userModel.email = email;
      userModel.contactNumber = mobileNumber.validate();
      userModel.username = userName.validate();
      userModel.userType = userType.validate();
      userModel.displayName = fName.validate() + " " + lName.validate();
      userModel.firstName = fName.validate();
      userModel.lastName = lName.validate();
      userModel.createdAt = Timestamp.now().toDate().toString();
      userModel.updatedAt = Timestamp.now().toDate().toString();
      userModel.playerId = sharedPref.getString(PLAYER_ID).validate();
      sharedPref.setString(UID, userCredential.user!.uid.validate());

      await userService.addDocumentWithCustomId(currentUser.uid, userModel.toJson()).then((value) async {
        Map req = {
          'first_name': fName,
          'last_name': lName,
          'username': userName,
          'email': email,
          "user_type": "driver",
          "contact_number": mobileNumber,
          'password': password,
          "player_id": sharedPref.getString(PLAYER_ID).validate(),
          "uid": userModel.uid,
          "gender": gender,
          if (socialLoginName) 'login_type': 'mobile',
          "user_detail": {
            'car_model': userDetail!.carModel.validate(),
            'car_color': userDetail.carColor.validate(),
            'car_plate_number': userDetail.carPlateNumber.validate(),
            'car_production_year': userDetail.carProductionYear.validate(),
          },
          'service_id': serviceId,
        };

        log(req);
        if (!isExist) {
          updateProfileUid();
          if (sharedPref.getInt(IS_Verified_Driver) == 1) {
            launchScreen(context, DriverDashboardScreen());
          } else {
            launchScreen(context, VerifyDeliveryPersonScreen(isShow: true), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
          }
        } else {
          await signUpApi(req).then((value) {
            if (sharedPref.getInt(IS_Verified_Driver) == 1) {
              launchScreen(context, DriverDashboardScreen());
            } else {
              launchScreen(context, VerifyDeliveryPersonScreen(isShow: true), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
            }
          }).catchError((error) {
            toast(error.toString());
            log('${error.toString()}');
          });
        }

        appStore.setLoading(false);
      }).catchError((e) {
        appStore.setLoading(false);
        toast('${e.toString()}');
        log('${e.toString()}');
      });
    } else {
      throw "errorSomethingWentWrong";
    }
  }

  Future<void> signInWithEmailPassword(context, {required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password).then((value) async {
      appStore.setLoading(true);
      final User user = value.user!;
      UserData userModel = await userService.getUser(email: user.email);
      await updateUserData(userModel);

      appStore.setLoading(true);
      //Login Details to SharedPreferences
      sharedPref.setString(UID, userModel.uid.validate());
      sharedPref.setString(USER_EMAIL, userModel.email.validate());
      sharedPref.setBool(IS_LOGGED_IN, true);

      //Login Details to AppStore
      appStore.setUserEmail(userModel.email.validate());
      appStore.setUId(userModel.uid.validate());

      //
    }).catchError((e) {
      toast(e.toString());
      log(e.toString());
    });
  }

  Future<void> loginFromFirebaseUser(User currentUser, {LoginResponse? loginDetail, String? fullName, String? fName, String? lName}) async {
    UserData userModel = UserData();

    if (await userService.isUserExist(loginDetail!.data!.email)) {
      ///Return user data
      await userService.userByEmail(loginDetail.data!.email).then((user) async {
        userModel = user;
        appStore.setUserEmail(userModel.email.validate());
        appStore.setUId(userModel.uid.validate());

        await updateUserData(user);
      }).catchError((e) {
        log(e);
        throw e;
      });
    } else {
      /// Create user
      userModel.uid = currentUser.uid.validate();
      userModel.id = loginDetail.data!.id;
      userModel.email = loginDetail.data!.email.validate();
      userModel.username = loginDetail.data!.username.validate();
      userModel.contactNumber = loginDetail.data!.contactNumber.validate();
      userModel.username = loginDetail.data!.username.validate();
      userModel.email = loginDetail.data!.email.validate();

      if (Platform.isIOS) {
        userModel.username = fullName;
      } else {
        userModel.username = loginDetail.data!.username.validate();
      }

      userModel.contactNumber = loginDetail.data!.contactNumber.validate();
      userModel.profileImage = loginDetail.data!.profileImage.validate();
      userModel.playerId = sharedPref.getString(PLAYER_ID);

      sharedPref.setString(UID, currentUser.uid.validate());
      log(sharedPref.getString(UID)!);
      sharedPref.setString(USER_EMAIL, userModel.email.validate());
      sharedPref.setBool(IS_LOGGED_IN, true);

      log(userModel.toJson());

      await userService.addDocumentWithCustomId(currentUser.uid, userModel.toJson()).then((value) {
        //
      }).catchError((e) {
        throw e;
      });
    }
  }

  Future<void> loginWithOTP(BuildContext context, String phoneNumber) async {
    return await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {},
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          toast('The provided phone number is not valid.');
          throw 'The provided phone number is not valid.';
        } else {
          toast(e.toString());
          throw e.toString();
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        Navigator.pop(context);
        appStore.setLoading(false);
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(content: OTPDialog(verificationId: verificationId, isCodeSent: true, phoneNumber: phoneNumber)),
          barrierDismissible: false,
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        //
      },
    );
  }

  Future deleteUserFirebase() async {
    if (FirebaseAuth.instance.currentUser != null) {
      FirebaseAuth.instance.currentUser!.delete();
      await FirebaseAuth.instance.signOut();
    }
  }
}
