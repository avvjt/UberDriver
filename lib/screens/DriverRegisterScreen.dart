import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi_driver/Services/AuthService.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Extensions/StringExtensions.dart';

import '../model/ServiceModel.dart';
import '../model/UserDetailModel.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import 'TermsConditionScreen.dart';

class DriverRegisterScreen extends StatefulWidget {
  bool socialLogin;
  String? userName;
  bool isOtp;
  String? countryCode;
  String? privacyPolicyUrl;
  String? termsConditionUrl;

  DriverRegisterScreen({this.socialLogin = false, this.userName, this.isOtp = false, this.countryCode, this.privacyPolicyUrl, this.termsConditionUrl});

  @override
  DriverRegisterScreenState createState() => DriverRegisterScreenState();
}

class DriverRegisterScreenState extends State<DriverRegisterScreen> {
  AuthServices authService = AuthServices();

  List<GlobalKey<FormState>> formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController firstController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController carModelController = TextEditingController();
  TextEditingController carProductionController = TextEditingController();
  TextEditingController carPlateController = TextEditingController();
  TextEditingController carColorController = TextEditingController();

  FocusNode firstNameFocus = FocusNode();
  FocusNode lastNameFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode passFocus = FocusNode();

  bool mIsCheck = false;
  bool isAcceptedTc = false;
  String countryCode = defaultCountryCode;

  int currentIndex = 0;

  List<ServiceList> listServices = [];

  List<String> gender = [MALE, FEMALE, OTHER];
  String selectGender = MALE;

  int vehicleTypeIndex = 0;

  XFile? imageProfile;
  int radioValue = -1;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if (sharedPref.getString(PLAYER_ID).validate().isEmpty) {
      await saveOneSignalPlayerId().then((value) {
        //
      });
    }
    await getServices().then((value) {
      listServices.addAll(value.data!);
      vehicleTypeIndex = listServices[0].id!;
      setState(() {});
    }).catchError((error) {
      log(error.toString());
    });
  }

  Future<void> register() async {
    hideKeyboard(context);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (isAcceptedTc) {
        appStore.setLoading(true);

        authService
            .signUpWithEmailPassword(
          context,
          name: firstController.text.trim(),
          mobileNumber: widget.socialLogin ? '${widget.countryCode}${widget.userName}' : '$countryCode${phoneController.text.trim()}',
          email: emailController.text.trim(),
          fName: firstController.text.trim(),
          lName: lastNameController.text.trim(),
          userName: widget.socialLogin ? widget.userName : userNameController.text.trim(),
          password: widget.socialLogin ? widget.userName : passController.text.trim(),
          userType: 'driver',
          socialLoginName: widget.socialLogin,
          isOtp: widget.isOtp,
          serviceId: listServices[vehicleTypeIndex].id,
          gender: selectGender,
          userDetail: UserDetail(
            carModel: carModelController.text.trim(),
            carColor: carColorController.text.trim(),
            carPlateNumber: carPlateController.text.trim(),
            carProductionYear: carProductionController.text.trim(),
          ),
        )
            .then((res) async {
          appStore.setLoading(false);

          //
        }).catchError((e) {
          appStore.setLoading(false);
          toast(e.toString());
        });
      } else {
        toast(language.pleaseAcceptTermsOfServicePrivacyPolicy);
      }
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.signUp, style: boldTextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          Form(
            key: formKey,
            child: Stepper(
              currentStep: currentIndex,
              onStepCancel: () {
                if (currentIndex > 0) {
                  currentIndex--;
                  setState(() {});
                }
              },
              onStepContinue: () {
                if (formKeys[currentIndex].currentState!.validate()) {
                  if (currentIndex == 1 && listServices.isEmpty) {
                    return toast(language.pleaseSelectService);
                  } else if (currentIndex <= 5) {
                    currentIndex++;
                    setState(() {});
                  } else {
                    register();
                  }
                }
              },
              onStepTapped: (int index) {
                currentIndex = index;
                setState(() {});
              },
              steps: [
                Step(
                  isActive: currentIndex <= 0,
                  state: currentIndex <= 0 ? StepState.disabled : StepState.complete,
                  title: Text(language.userDetail, style: boldTextStyle()),
                  content: Form(
                    key: formKeys[0],
                    child: Column(
                      children: [
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                textFieldType: TextFieldType.NAME,
                                controller: firstController,
                                focus: firstNameFocus,
                                nextFocus: lastNameFocus,
                                errorThisFieldRequired: language.thisFieldRequired,
                                decoration: inputDecoration(context, label: language.firstName),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                textFieldType: TextFieldType.NAME,
                                controller: lastNameController,
                                focus: lastNameFocus,
                                nextFocus: emailFocus,
                                errorThisFieldRequired: language.thisFieldRequired,
                                decoration: inputDecoration(context, label: language.lastName),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                textFieldType: TextFieldType.EMAIL,
                                focus: emailFocus,
                                controller: emailController,
                                nextFocus: userNameFocus,
                                errorThisFieldRequired: language.thisFieldRequired,
                                decoration: inputDecoration(context, label: language.email),
                              ),
                            ),
                            SizedBox(width: 16),
                            if (widget.socialLogin != true)
                              Expanded(
                                child: AppTextField(
                                  textFieldType: TextFieldType.USERNAME,
                                  focus: userNameFocus,
                                  controller: userNameController,
                                  nextFocus: phoneFocus,
                                  errorThisFieldRequired: language.thisFieldRequired,
                                  decoration: inputDecoration(context, label: language.userName),
                                ),
                              ),
                          ],
                        ),
                        if (widget.socialLogin != true) SizedBox(height: 16),
                        if (widget.socialLogin != true)
                          AppTextField(
                            controller: phoneController,
                            textFieldType: TextFieldType.PHONE,
                            focus: phoneFocus,
                            nextFocus: passFocus,
                            decoration: inputDecoration(
                              context,
                              label: language.phoneNumber,
                              prefixIcon: IntrinsicHeight(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CountryCodePicker(
                                      padding: EdgeInsets.zero,
                                      initialSelection: countryCode,
                                      showCountryOnly: false,
                                      dialogSize: Size(MediaQuery.of(context).size.width - 60, MediaQuery.of(context).size.height * 0.6),
                                      showFlag: true,
                                      showFlagDialog: true,
                                      showOnlyCountryWhenClosed: false,
                                      alignLeft: false,
                                      textStyle: primaryTextStyle(),
                                      dialogBackgroundColor: Theme.of(context).cardColor,
                                      barrierColor: Colors.black12,
                                      dialogTextStyle: primaryTextStyle(),
                                      searchDecoration: InputDecoration(
                                        iconColor: Theme.of(context).dividerColor,
                                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                                      ),
                                      searchStyle: primaryTextStyle(),
                                      onInit: (c) {
                                        countryCode = c!.dialCode!;
                                      },
                                      onChanged: (c) {
                                        countryCode = c.dialCode!;
                                      },
                                    ),
                                    VerticalDivider(color: Colors.grey.withOpacity(0.5)),
                                  ],
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value!.trim().isEmpty) return language.thisFieldRequired;
                              if (value.trim().length < 10 || value.trim().length > 14) return language.contactLength;
                              return null;
                            },
                          ),
                        if (widget.socialLogin != true) SizedBox(height: 16),
                        if (widget.socialLogin != true)
                          AppTextField(
                            controller: passController,
                            focus: passFocus,
                            autoFocus: false,
                            textFieldType: TextFieldType.PASSWORD,
                            errorThisFieldRequired: language.thisFieldRequired,
                            decoration: inputDecoration(context, label: language.password),
                          ),
                      ],
                    ),
                  ),
                ),
                Step(
                  isActive: currentIndex <= 1,
                  state: currentIndex <= 1 ? StepState.disabled : StepState.complete,
                  title: Text(language.selectService, style: boldTextStyle()),
                  content: Form(
                    key: formKeys[1],
                    child: listServices.isNotEmpty
                        ? Column(
                            children: listServices.map((e) {
                              return inkWellWidget(
                                onTap: () {
                                  vehicleTypeIndex = listServices.indexOf(e);
                                  setState(() {});
                                  print(listServices[vehicleTypeIndex].id);
                                },
                                child: Container(
                                  margin: EdgeInsets.only(
                                    bottom: 8,
                                  ),
                                  padding: EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: vehicleTypeIndex == listServices.indexOf(e) ? Colors.green : primaryColor.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(defaultRadius),
                                  ),
                                  child: Row(
                                    children: [
                                      commonCachedNetworkImage(e.serviceImage, fit: BoxFit.contain, height: 50, width: 50),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Text(e.name.validate(), style: boldTextStyle()),
                                      ),
                                      Visibility(
                                        visible: vehicleTypeIndex == listServices.indexOf(e),
                                        child: Icon(Icons.check_circle_outline, color: Colors.green),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        : emptyWidget(),
                  ),
                ),
                Step(
                  isActive: currentIndex <= 2,
                  state: currentIndex <= 2 ? StepState.disabled : StepState.complete,
                  title: Text(language.carModel, style: boldTextStyle()),
                  content: Form(
                    key: formKeys[2],
                    child: AppTextField(textFieldType: TextFieldType.NAME, controller: carModelController),
                  ),
                ),
                Step(
                  isActive: currentIndex <= 3,
                  state: currentIndex <= 3 ? StepState.indexed : StepState.complete,
                  title: Text(language.carProductionYear, style: boldTextStyle()),
                  content: Form(
                    key: formKeys[3],
                    child: AppTextField(textFieldType: TextFieldType.PHONE, controller: carProductionController),
                  ),
                ),
                Step(
                  isActive: currentIndex <= 4,
                  state: currentIndex <= 4 ? StepState.disabled : StepState.complete,
                  title: Text(language.carPlateNumber, style: boldTextStyle()),
                  content: Form(
                    key: formKeys[4],
                    child: AppTextField(textFieldType: TextFieldType.NAME, controller: carPlateController),
                  ),
                ),
                Step(
                  isActive: currentIndex <= 5,
                  state: currentIndex <= 5 ? StepState.disabled : StepState.complete,
                  title: Text(language.carColor, style: boldTextStyle()),
                  content: Form(
                    key: formKeys[5],
                    child: AppTextField(textFieldType: TextFieldType.NAME, controller: carColorController),
                  ),
                ),
                Step(
                  isActive: currentIndex <= 6,
                  state: currentIndex <= 6 ? StepState.disabled : StepState.complete,
                  title: Text(language.selectGender, style: boldTextStyle()),
                  content: Form(
                    key: formKeys[6],
                    child: Column(
                      children: [
                        DropdownButtonFormField(
                          decoration: inputDecoration(context, label: ""),
                          value: selectGender,
                          onChanged: (String? value) {
                            setState(() {
                              selectGender = value!;
                            });
                          },
                          items: gender
                              .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    "${value.capitalizeFirstLetter()}",
                                    style: primaryTextStyle(),
                                  )))
                              .toList(),
                        ),
                        SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: primaryColor,
                          title: RichText(
                            text: TextSpan(children: [
                              TextSpan(text: '${language.agreeToThe} ', style: secondaryTextStyle()),
                              TextSpan(
                                text: language.termsConditions,
                                style: boldTextStyle(color: primaryColor, size: 14),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    if (widget.termsConditionUrl != null && widget.termsConditionUrl!.isNotEmpty) {
                                      launchScreen(context, TermsConditionScreen(title: language.termsConditions, subtitle: widget.termsConditionUrl), pageRouteAnimation: PageRouteAnimation.Slide);
                                    } else {
                                      toast(language.txtURLEmpty);
                                    }
                                  },
                              ),
                              TextSpan(text: ' & ', style: secondaryTextStyle()),
                              TextSpan(
                                text: language.privacyPolicy,
                                style: boldTextStyle(color: primaryColor, size: 14),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    if (widget.privacyPolicyUrl != null && widget.privacyPolicyUrl!.isNotEmpty) {
                                      launchScreen(context, TermsConditionScreen(title: language.privacyPolicy, subtitle: widget.privacyPolicyUrl), pageRouteAnimation: PageRouteAnimation.Slide);
                                    } else {
                                      toast(language.txtURLEmpty);
                                    }
                                  },
                              ),
                            ]),
                            textAlign: TextAlign.left,
                          ),
                          value: isAcceptedTc,
                          onChanged: (val) async {
                            isAcceptedTc = val!;
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
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
}
