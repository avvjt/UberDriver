import 'dart:convert';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/screens/DriverDashboardScreen.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/AppButtonWidget.dart';
import 'package:taxi_driver/utils/Extensions/StringExtensions.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/CurrentRequestModel.dart';
import '../model/RideHistory.dart';
import '../model/RiderModel.dart';
import '../network/RestApis.dart';
import '../utils/Common.dart';
import '../utils/Extensions/ConformationDialog.dart';
import '../utils/Images.dart';
import 'RideHistoryScreen.dart';

class DetailScreen extends StatefulWidget {
  @override
  DetailScreenState createState() => DetailScreenState();
}

class DetailScreenState extends State<DetailScreen> {
  CurrentRequestModel? currentData;
  RiderModel? riderModel;
  Payment? payment;
  List<RideHistory> rideHistory = [];
  bool isPaymentDone = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    currentRideRequest();
    mqttForUser();
  }

  Future<void> currentRideRequest() async {
    appStore.setLoading(true);
    await getCurrentRideRequest().then((value) async {
      appStore.setLoading(false);
      currentData = value;
      await orderDetailApi();
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  Future<void> savePaymentApi() async {
    appStore.setLoading(true);
    Map req = {
      "id": currentData!.payment!.id,
      "rider_id": currentData!.payment!.riderId,
      "ride_request_id": currentData!.payment!.rideRequestId,
      "datetime": DateTime.now().toString(),
      "total_amount": currentData!.payment!.totalAmount,
      "payment_type": currentData!.payment!.paymentType,
      "txn_id": "",
      "payment_status": "paid",
      "transaction_detail": ""
    };
    log(req);
    await savePayment(req).then((value) {
      appStore.setLoading(false);
      launchScreen(context, DriverDashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  Future<void> orderDetailApi() async {
    appStore.setLoading(true);
    await rideDetail(orderId: currentData!.payment!.rideRequestId).then((value) {
      appStore.setLoading(false);

      riderModel = value.data;
      payment = value.payment!;
      rideHistory = value.rideHistory!;
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);

      log('${error.toString()}');
    });
  }

  mqttForUser() async {
    client.setProtocolV311();
    client.logging(on: true);
    client.keepAlivePeriod = 120;
    client.autoReconnect = true;

    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      debugPrint(e.toString());
      client.connect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      client.onSubscribed = onSubscribed;

      log('connected');
      debugPrint('connected');
    } else {
      client.connect();
    }

    void onconnected() {
      debugPrint('connected');
    }

    client.subscribe('ride_request_status_' + sharedPref.getInt(USER_ID).toString(), MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;

      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      if (jsonDecode(pt)['success_type'] == 'rating') {
        currentRideRequest();
      } else if (jsonDecode(pt)['success_type'] == 'change_payment_type') {
        currentRideRequest();
      } else if (jsonDecode(pt)['success_type'] == 'payment_status_message') {
        setState(() {
          isPaymentDone = true;
        });
        Future.delayed(
          Duration(seconds: 5),
          () {
            setState(() {
              isPaymentDone = false;
            });
            launchScreen(context, DriverDashboardScreen(), isNewTask: true);
          },
        );
      }
    });

    client.onConnected = onconnected;
  }

  void onConnected() {
    log('Connected');
  }

  void onSubscribed(String topic) {
    log('Subscription confirmed for topic $topic');
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.detailScreen, style: boldTextStyle(color: Colors.white)),
      ),
      body: currentData != null && riderModel != null
          ? Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: appStore.isDarkMode ? scaffoldSecondaryDark : primaryColor.withOpacity(0.05),
                          borderRadius: radius(),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Ionicons.calendar, color: textSecondaryColorGlobal, size: 18),
                                SizedBox(width: 8),
                                Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Text('${printDate(riderModel!.createdAt.validate())}', style: primaryTextStyle(size: 14)),
                                ),
                              ],
                            ),
                            Divider(height: 30, thickness: 1),
                            Text('${language.distance}: ${riderModel!.distance.toString()} ${riderModel!.distanceUnit.toString()}', style: boldTextStyle(size: 14)),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Column(
                                  children: [
                                    Icon(Icons.near_me, color: Colors.green),
                                    SizedBox(height: 4),
                                    SizedBox(
                                      height: 50,
                                      child: DottedLine(
                                        direction: Axis.vertical,
                                        lineLength: double.infinity,
                                        lineThickness: 1,
                                        dashLength: 2,
                                        dashColor: primaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Icon(Icons.location_on, color: Colors.red),
                                  ],
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 2),
                                      if (riderModel!.startTime != null) Text(riderModel!.startTime != null ? printDate(riderModel!.startTime!) : '', style: secondaryTextStyle(size: 12)),
                                      if (riderModel!.startTime != null) SizedBox(height: 4),
                                      Text(riderModel!.startAddress.validate(), style: primaryTextStyle(size: 14)),
                                      SizedBox(height: 22),
                                      if (riderModel!.endTime != null) Text(riderModel!.endTime != null ? printDate(riderModel!.endTime!) : '', style: secondaryTextStyle(size: 12)),
                                      if (riderModel!.endTime != null) SizedBox(height: 4),
                                      Text(riderModel!.endAddress.validate(), style: primaryTextStyle(size: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 30, thickness: 1),
                            inkWellWidget(
                              onTap: () {
                                launchScreen(context, RideHistoryScreen(rideHistory: rideHistory), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(language.viewHistory, style: primaryTextStyle(color: primaryColor)),
                                  Icon(Entypo.chevron_right, color: primaryColor, size: 18),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: appStore.isDarkMode ? scaffoldSecondaryDark : primaryColor.withOpacity(0.05),
                          borderRadius: radius(),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(language.paymentDetails, style: boldTextStyle(size: 16)),
                            Divider(height: 30, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(language.paymentType, style: primaryTextStyle()),
                                Text(paymentStatus(riderModel!.paymentType.validate()), style: boldTextStyle()),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(language.paymentStatus, style: primaryTextStyle()),
                                Text(paymentStatus(riderModel!.paymentStatus.validate()), style: boldTextStyle()),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (riderModel!.otherRiderData != null) SizedBox(height: 16),
                      if (riderModel!.otherRiderData != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 16),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(color: appStore.isDarkMode ? scaffoldSecondaryDark : primaryColor.withOpacity(0.05), borderRadius: radius()),
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(language.riderInformation, style: boldTextStyle()),
                                  Divider(height: 30, thickness: 1),
                                  Row(
                                    children: [
                                      Icon(FontAwesome.user, size: 18, color: textPrimaryColorGlobal),
                                      SizedBox(width: 12),
                                      Text(riderModel!.otherRiderData!.name.validate(), style: primaryTextStyle()),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          launchUrl(Uri.parse('tel:${riderModel!.otherRiderData!.conatctNumber.validate()}'), mode: LaunchMode.externalApplication);
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(defaultRadius)),
                                          child: Icon(Ionicons.ios_call, size: 18, color: Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(riderModel!.otherRiderData!.conatctNumber.validate(), style: primaryTextStyle()),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(color: appStore.isDarkMode ? scaffoldSecondaryDark : primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(language.priceDetail, style: boldTextStyle(size: 16)),
                            Divider(height: 30, thickness: 1),
                            (riderModel!.minimumFare ?? 0) == ((riderModel!.subtotal ?? 0) - (riderModel!.extraChargesAmount ?? 0))
                                ? totalCount(title: language.minimumFare, description: '', subTitle: '${riderModel!.minimumFare}')
                                : Column(
                              children: [
                                totalCount(title: language.basePrice, description: '', subTitle: '${riderModel!.baseFare}'),
                                SizedBox(height: 8),
                                totalCount(title: language.distancePrice, description: '', subTitle: riderModel!.perDistanceCharge.toString()),
                                SizedBox(height: 8),
                                totalCount(title: language.duration, description: '', subTitle: '${riderModel!.perMinuteDriveCharge}'),
                                SizedBox(height: 8),
                                totalCount(title: language.waitTime, description: '', subTitle: '${riderModel!.perMinuteWaitingCharge}'),
                              ],
                            ),
                            if (riderModel!.tips != null) totalCount(title: language.tip, description: '', subTitle: riderModel!.tips.toString()),
                            if (riderModel!.tips != null) SizedBox(height: 8),
                            if (riderModel!.extraCharges!.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(language.extraCharges, style: boldTextStyle()),
                                  SizedBox(height: 8),
                                  ...riderModel!.extraCharges!.map((e) {
                                    return Padding(
                                      padding: EdgeInsets.only(top: 4, bottom: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(e.key.validate().capitalizeFirstLetter(), style: primaryTextStyle()),
                                          Text(appStore.currencyPosition == LEFT ? '${appStore.currencyCode} ${e.value}' : '${e.value} ${appStore.currencyCode}', style: primaryTextStyle()),
                                        ],
                                      ),
                                    );
                                  }).toList()
                                ],
                              ),
                            if (riderModel!.couponData != null && riderModel!.couponDiscount != 0) SizedBox(height: 8),
                            if (riderModel!.couponData != null && riderModel!.couponDiscount != 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(language.couponDiscount, style: primaryTextStyle(color: Colors.red)),
                                  Text(
                                      appStore.currencyPosition == LEFT
                                          ? '-${appStore.currencyCode} ${riderModel!.couponDiscount.toString()}'
                                          : '-${riderModel!.couponDiscount.toString()} ${appStore.currencyCode}',
                                      style: primaryTextStyle(color: Colors.green)),
                                ],
                              ),
                            Divider(height: 30, thickness: 1),
                            riderModel!.tips != null
                                ? totalCount(title: language.total, description: '', subTitle: '${riderModel!.subtotal! + riderModel!.tips!}', isTotal: true)
                                : totalCount(title: language.total, description: '', subTitle: '${riderModel!.subtotal}', isTotal: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Visibility(visible: isPaymentDone, child: Center(child: Lottie.asset(paymentSuccessful, width: 400, height: 400, fit: BoxFit.contain))),
              ],
            )
          : Observer(builder: (context) {
              return Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              );
            }),
      bottomNavigationBar: currentData != null
          ? Padding(
              padding: EdgeInsets.all(16),
              child: currentData!.payment!.paymentType == CASH
                  ? AppButtonWidget(
                      text: language.cashCollected,
                      textStyle: boldTextStyle(color: Colors.white),
                      color: primaryColor,
                      onTap: () {
                        showConfirmDialogCustom(
                            primaryColor: primaryColor,
                            positiveText: language.yes,
                            negativeText: language.no,
                            dialogType: DialogType.CONFIRMATION,
                            title: language.areYouSureCollectThisPayment,
                            context, onAccept: (v) {
                          savePaymentApi();
                        });
                      },
                    )
                  : AppButtonWidget(
                      text: language.waitingForDriverConformation,
                      textStyle: boldTextStyle(color: Colors.white, size: 12),
                      color: primaryColor,
                      onTap: () {
                        if (currentData!.payment!.paymentStatus == COMPLETED) {
                          launchScreen(context, DriverDashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                        } else {
                          //currentRideRequest();
                          toast(language.waitingForDriverConformation);
                        }
                      },
                    ),
            )
          : SizedBox(),
    );
  }

  Widget chargesWidget({String? name, String? amount}) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name!, style: primaryTextStyle()),
          Text(amount!, style: primaryTextStyle()),
        ],
      ),
    );
  }
}
