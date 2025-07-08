import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:toastification/toastification.dart';

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: CustomSpinkit1,
      ),
    );
  }
}

final CustomSpinkit1 = SpinKitFadingCircle(
  itemBuilder: (BuildContext context, int index) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: index.isEven ? Colors.red : Colors.green,
      ),
    );
  },
);

void showError(String message) {
  toastification.show(
    title: Text(message, softWrap: true),
    type: ToastificationType.error,
    style: ToastificationStyle.minimal,
    direction: TextDirection.ltr,
    autoCloseDuration: const Duration(seconds: 3),
  );
}

// final CustomSpinkit2 = SpinKitThreeInOut(
//   duration: const Duration(milliseconds: 720),
//   delay: const Duration(milliseconds: 50),
//   itemBuilder: (BuildContext context, int index) {
//     return DecoratedBox(
//       decoration: BoxDecoration(
//         color: index.isEven ? flexThemeDataLight.primaryColorLight : flexThemeDataLight.secondaryHeaderColor,
//         shape: BoxShape.circle,
//       ),
//     );
//   },
// );
//
// class CustomRefresh extends StatelessWidget {
//   final Future<void> Function() onRefresh;
//   final Widget child;
//
//   CustomRefresh({required this.onRefresh, required this.child});
//
//   static Future<void> handleRefresh() async {
//     await Future.delayed(const Duration(seconds: 1));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return LiquidPullToRefresh(
//       onRefresh: onRefresh,
//       color: flexThemeDataLight.secondaryHeaderColor,
//       height: 300,
//       backgroundColor: flexSchemeLight.onPrimary,
//       animSpeedFactor: 2,
//       child: SingleChildScrollView(
//         child: child,
//       ),
//     );
//   }
// }
