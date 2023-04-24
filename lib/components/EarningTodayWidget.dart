import 'package:flutter/material.dart';

import '../main.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Extensions/app_common.dart';

class EarningTodayWidget extends StatefulWidget {
  @override
  EarningTodayWidgetState createState() => EarningTodayWidgetState();
}

class EarningTodayWidgetState extends State<EarningTodayWidget> {
  num totalCashRide = 0;
  num totalWalletRide = 0;
  num todayEarnings = 0;
  num todayRideRequest = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    appStore.setLoading(true);
    Map req = {
      "type": "today",
    };
    await earningList(req: req).then((value) {
      appStore.setLoading(false);

      totalCashRide = value.totalCashRide!;
      totalWalletRide = value.totalWalletRide!;
      todayEarnings = value.todayEarnings!;
      todayRideRequest = value.todayRideRequest!;

      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);

      log(error.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(top: 32, bottom: 16, right: 16, left: 16),
          child: Column(
            children: [
              Text('${printDate('${DateTime.now()}')}', style: boldTextStyle(size: 20)),
              SizedBox(height: 16),
              SizedBox(height: 16),
              earningText(title: language.totalCash, amount: totalCashRide),
              SizedBox(height: 16),
              earningText(title: language.totalWallet, amount: totalWalletRide),
              SizedBox(height: 16),
              earningText(title: language.totalRide, amount: todayRideRequest),
              SizedBox(height: 16),
              Divider(color: primaryColor),
              earningText(title: language.todayEarning, amount: todayEarnings),
              SizedBox(height: 16),
            ],
          ),
        ),
        Visibility(
          visible: appStore.isLoading,
          child: loaderWidget(),
        )
      ],
    );
  }
}
