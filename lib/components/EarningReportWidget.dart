import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../main.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';

class EarningReportWidget extends StatefulWidget {
  @override
  EarningReportWidgetState createState() => EarningReportWidgetState();
}

class EarningReportWidgetState extends State<EarningReportWidget> {
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();

  DateTime? fromDate, toDate;
  num totalRideCount = 0;
  num totalCashRide = 0;
  num totalWalletRide = 0;
  num totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if (fromDateController.text.isNotEmpty && toDateController.text.isNotEmpty) {
      appStore.setLoading(true);
      Map req = {
        "type": "report",
        "from_date": fromDateController.text.toString(),
        "to_date": toDateController.text.toString(),
      };
      await earningList(req: req).then((value) {
        appStore.setLoading(false);

        if (value.totalCashRide != null) totalCashRide = value.totalCashRide!;
        if (value.totalWalletRide != null) totalWalletRide = value.totalWalletRide!;
        if (value.totalEarnings != null) totalEarnings = value.totalEarnings!;
        if (value.totalRideCount != null) totalRideCount = value.totalRideCount!;

        setState(() {});
      }).catchError((error) {
        appStore.setLoading(false);

        log(error.toString());
      });
    } else {
      toast(language.pleaseSelectFromDateAndToDate);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(top: 32, bottom: 16, left: 16, right: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(language.from, style: primaryTextStyle()),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: DateTimePicker(
                          controller: fromDateController,
                          type: DateTimePickerType.date,
                          lastDate: DateTime.now(),
                          firstDate: DateTime(2010),
                          onChanged: (value) {
                            fromDate = DateTime.parse(value);
                            fromDateController.text = value;
                            setState(() {});
                          },
                          decoration: inputDecoration(context, label: language.fromDate, suffixIcon: Icon(Icons.calendar_today)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(language.to, style: primaryTextStyle()),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: DateTimePicker(
                          controller: toDateController,
                          type: DateTimePickerType.date,
                          lastDate: DateTime.now(),
                          firstDate: fromDate ?? DateTime.now(),
                          onChanged: (value) {
                            toDate = DateTime.parse(value);
                            toDateController.text = value;
                            setState(() {});
                          },
                          decoration: inputDecoration(context, label: language.toDate, suffixIcon: Icon(Icons.calendar_today)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  AppButtonWidget(
                    width: MediaQuery.of(context).size.width,
                    color: primaryColor,
                    textStyle: boldTextStyle(color: Colors.white),
                    text: language.confirm,
                    onTap: () async {
                      init();
                    },
                  ),
                  SizedBox(height: 16),
                  if (fromDateController.text.isNotEmpty && toDateController.text.isNotEmpty) Text('${fromDateController.text} - ${toDateController.text}', style: boldTextStyle()),
                  SizedBox(height: 16),
                  earningText(title: language.totalCash, amount: totalCashRide),
                  SizedBox(height: 16),
                  earningText(title: language.totalWallet, amount: totalWalletRide),
                  SizedBox(height: 16),
                  earningText(title: language.totalRide, amount: totalRideCount),
                  SizedBox(height: 16),
                  Divider(color: primaryColor),
                  earningText(title: language.totalEarning, amount: totalEarnings),
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
      },
    );
  }
}
