import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:taxi_driver/model/ComplaintModel.dart';
import 'package:taxi_driver/model/DriverRatting.dart';
import 'package:taxi_driver/model/RideHistory.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/screens/RideHistoryScreen.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Extensions/StringExtensions.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/AboutWidget.dart';
import '../components/GenerateInvoice.dart';
import '../main.dart';
import '../model/CurrentRequestModel.dart';
import '../model/RiderModel.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import 'ComplaintScreen.dart';

class RideDetailScreen extends StatefulWidget {
  final int orderId;

  RideDetailScreen({required this.orderId});

  @override
  RideDetailScreenState createState() => RideDetailScreenState();
}

class RideDetailScreenState extends State<RideDetailScreen> {
  RiderModel? riderModel;
  List<RideHistory> rideHistory = [];
  DriverRatting? riderRatting;
  ComplaintModel? complaintData;
  Payment? payment;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    appStore.setLoading(true);
    await rideDetail(orderId: widget.orderId).then((value) {
      appStore.setLoading(false);

      riderModel = value.data;
      rideHistory.addAll(value.rideHistory!);
      riderRatting = value.riderRatting;
      complaintData = value.complaintModel;
      if (value.payment != null) payment = value.payment;
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);

      log('error:${error.toString()}');
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
        title: Text(riderModel != null ? "${language.ride} #${riderModel!.id}" : "", style: boldTextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () {
              launchScreen(
                context,
                ComplaintScreen(driverRatting: riderRatting ?? DriverRatting(), complaintModel: complaintData, riderModel: riderModel),
                pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
              );
            },
            icon: Icon(MaterialCommunityIcons.head_question),
          )
        ],
      ),
      body: Stack(
        children: [
          if (riderModel != null)
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            inkWellWidget(
                              onTap: () {
                                generateInvoiceCall(riderModel, payment: payment);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(language.invoice, style: primaryTextStyle(color: primaryColor)),
                                  SizedBox(width: 4),
                                  Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(MaterialIcons.file_download, size: 18, color: primaryColor),
                                  ),
                                ],
                              ),
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
                              Text(language.riderInformation.capitalizeFirstLetter(), style: boldTextStyle()),
                              Divider(height: 30, thickness: 1),
                              Row(
                                children: [
                                  Icon(FontAwesome.user, size: 18, color: textPrimaryColorGlobal),
                                  SizedBox(width: 12),
                                  Text(riderModel!.otherRiderData!.name.validate(), style: primaryTextStyle()),
                                ],
                              ),
                              SizedBox(height: 10),
                              InkWell(
                                onTap: () {
                                  launchUrl(Uri.parse('tel:${riderModel!.otherRiderData!.conatctNumber.validate()}'), mode: LaunchMode.externalApplication);
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(2),
                                      decoration: BoxDecoration(color: Colors.green, borderRadius: radius(6)),
                                      child: Icon(Icons.call_sharp, color: Colors.white, size: 16),
                                    ),
                                    SizedBox(width: 8),
                                    Text(riderModel!.otherRiderData!.conatctNumber.validate(), style: primaryTextStyle())
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          contentPadding: EdgeInsets.zero,
                          content: AboutWidget(driverId: riderModel!.riderId),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(color: appStore.isDarkMode ? scaffoldSecondaryDark : primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(language.aboutRider, style: boldTextStyle(size: 16)),
                          Divider(height: 30, thickness: 1),
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(35),
                                child: commonCachedNetworkImage(riderModel!.driverProfileImage.validate(), height: 70, width: 70, fit: BoxFit.cover),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(riderModel!.riderName.validate(), style: boldTextStyle()),
                                    SizedBox(height: 6),
                                    if (riderRatting != null)
                                      RatingBar.builder(
                                        direction: Axis.horizontal,
                                        glow: false,
                                        allowHalfRating: false,
                                        ignoreGestures: true,
                                        wrapAlignment: WrapAlignment.spaceBetween,
                                        itemCount: 5,
                                        itemSize: 20,
                                        initialRating: double.parse(riderRatting!.rating.toString()),
                                        itemPadding: EdgeInsets.symmetric(horizontal: 0),
                                        itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                                        onRatingUpdate: (rating) {
                                          //
                                        },
                                      ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(riderModel!.riderContactNumber.validate(), style: primaryTextStyle(size: 14)),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            launchUrl(Uri.parse('tel:${riderModel!.riderContactNumber}'), mode: LaunchMode.externalApplication);
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(defaultRadius)),
                                            child: Icon(Icons.call_sharp, color: Colors.white, size: 20),
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: appStore.isDarkMode ? scaffoldSecondaryDark : primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(language.priceDetail, style: boldTextStyle(size: 16)),
                        Divider(height: 30, thickness: 1),
                        SizedBox(height: 12),
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
                        SizedBox(height: 8),
                        if (payment != null) totalCount(title: language.tip, description: '', subTitle: payment!.driverTips.toString()),
                        if (payment != null) SizedBox(height: 16),
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
                              Text(appStore.currencyPosition == LEFT ? '-${appStore.currencyCode} ${riderModel!.couponDiscount.toString()}' : '-${riderModel!.couponDiscount.toString()} ${appStore.currencyCode}',
                                  style: primaryTextStyle(color: Colors.green)),
                            ],
                          ),
                        Divider(height: 30, thickness: 1),
                        payment!.driverTips != 0
                            ? totalCount(title: language.total, description: '', subTitle: '${riderModel!.subtotal! + payment!.driverTips!}',isTotal: true)
                            : totalCount(title: language.total, description: '', subTitle: '${riderModel!.subtotal}',isTotal: true),
                      ],
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
