import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:taxi_driver/utils/Common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../model/SettingModel.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/ConformationDialog.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';
import 'AboutScreen.dart';
import 'ChangePasswordScreen.dart';
import 'DeleteAccountScreen.dart';
import 'LanguageScreen.dart';
import 'TermsConditionScreen.dart';

class SettingScreen extends StatefulWidget {
  @override
  SettingScreenState createState() => SettingScreenState();
}

class SettingScreenState extends State<SettingScreen> {
  SettingModel settingModel = SettingModel();
  String? privacyPolicy;
  String? termsCondition;
  String? mHelpAndSupport;

  bool isAvailable = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await driverDetail();
    await getAppSetting().then((value) {
      if (value.settingModel!.helpSupportUrl != null) mHelpAndSupport = value.settingModel!.helpSupportUrl!;
      settingModel = value.settingModel!;
      if (value.privacyPolicyModel!.value != null) privacyPolicy = value.privacyPolicyModel!.value!;
      if (value.termsCondition!.value != null) termsCondition = value.termsCondition!.value!;
      setState(() {});
    }).catchError((error) {
      log(error.toString());
    });
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
    });
  }

  Future<void> driverDetail() async {
    appStore.setLoading(true);
    await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
      if (value.data!.isAvailable == 1) {
        isAvailable = true;
      } else {
        isAvailable = false;
      }
      appStore.setLoading(false);
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
    });
  }

  Future<void> updateAvailable() async {
    appStore.setLoading(true);
    Map req = {
      "is_available": isAvailable ? 0 : 1,
    };
    updateStatus(req).then((value) {
      driverDetail();
    }).catchError((error) {
      appStore.setLoading(false);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.setting, style: boldTextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                settingItemWidget(Icons.lock_outline, language.changePassword, () {
                  launchScreen(context, ChangePasswordScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
                }),
                settingItemWidget(Icons.language, language.language, () {
                  launchScreen(context, LanguageScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
                }),
                settingItemWidget(Icons.assignment_outlined, language.privacyPolicy, () {
                  if (privacyPolicy != null) {
                    launchUrl(Uri.parse(privacyPolicy!));
                  } else {
                    toast(language.txtURLEmpty);
                  }
                }),
                settingItemWidget(Icons.help_outline, language.helpSupport, () {
                  if (mHelpAndSupport != null) {
                    launchUrl(Uri.parse(mHelpAndSupport!));
                  } else {
                    toast(language.txtURLEmpty);
                  }
                }),
                settingItemWidget(Icons.assignment_outlined, language.termsConditions, () {
                  if (termsCondition != null) {
                    launchScreen(context, TermsConditionScreen(title: language.termsConditions, subtitle: termsCondition), pageRouteAnimation: PageRouteAnimation.Slide);
                  } else {
                    toast(language.txtURLEmpty);
                  }
                }),
                settingItemWidget(
                  Icons.info_outline,
                  language.aboutUs,
                      () {
                    launchScreen(context, AboutScreen(settingModel: settingModel), pageRouteAnimation: PageRouteAnimation.Slide);
                  },
                ),
                settingItemWidget(Icons.delete_outline, language.deleteAccount, () {
                  launchScreen(context, DeleteAccountScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
                }),
                ListTile(
                  contentPadding: EdgeInsets.only(left: 16, right: 16),
                  leading: Icon(Icons.offline_bolt_outlined, size: 25, color: primaryColor),
                  title: Text(isAvailable ? language.available : language.notAvailable, style: primaryTextStyle()),
                  trailing: Switch(
                      value: isAvailable,
                      onChanged: (val) {
                        //
                      }),
                  onTap: () async {
                    if (appStore.currentRiderRequest == null) {
                      await showConfirmDialogCustom(
                        context,
                        title: !isAvailable ? language.youWillReceiveNewRidersAndNotifications : language.youWillNotReceiveNewRidersAndNotifications,
                        dialogType: DialogType.ACCEPT,
                        positiveText: language.yes,
                        negativeText: language.no,
                        primaryColor: primaryColor,
                        onAccept: (c) async {
                          updateAvailable();
                        },
                      );
                    } else {
                      toast(language.youCanNotThisActionsPerformBecauseYourCurrentRideIsNotCompleted);
                    }
                  },
                ),
              ],
            ),
          ),
          Observer(builder: (context) {
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          })
        ],
      ),
    );
  }

  Widget settingItemWidget(IconData icon, String title, Function() onTap, {bool isLast = false, IconData? suffixIcon}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16, right: 16),
          leading: Icon(icon, size: 25, color: primaryColor),
          title: Text(title, style: primaryTextStyle()),
          trailing: suffixIcon != null ? Icon(suffixIcon, color: Colors.green) : Icon(Icons.navigate_next, color: Colors.grey),
          onTap: onTap,
        ),
        if (!isLast) Divider(height: 0)
      ],
    );
  }
}
