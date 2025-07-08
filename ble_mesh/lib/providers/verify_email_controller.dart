import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../cloud_services/auth_service.dart';

class VerifyEmailController extends ChangeNotifier {
  final AuthService authService = AuthService();
  bool _verificationStatus = false;
  Timer? _timer1, _timer2;
  int _countDown = 30;
  bool _canResend = false;
  bool _isSendingBlocked = false;

  // Gửi email xác thực
  void sendEmailVerification() async {
    if (_isSendingBlocked) {
      print("Sending blocked due to too many requests. Try again later.");
      return;
    }
    try {
      await authService.sendEmailVerification();
      _startCountdown();
    } catch (e) {
      if (e.toString().contains('auth/too-many-requests')) {
        _isSendingBlocked = true;
        print("Too many requests. Blocked temporarily.");
        Future.delayed(const Duration(minutes: 20), () {
          _isSendingBlocked = false; // Reset sau 20 phút
        });
      }
      print("Error sending email verification: $e");
      throw e;
    }
  }

  // Bắt đầu timer kiểm tra trạng thái xác thực email
  void setTimerForAutoRedirect() {
    _timer1 = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final User? currentUser = authService.currentUser;
      if (currentUser != null) {
        await currentUser.reload(); // Cập nhật trạng thái người dùng
        final User? refreshedUser = authService.currentUser;
        print("Email Verified = ${refreshedUser?.emailVerified}");
        if (refreshedUser != null && refreshedUser.emailVerified) {
          cancelTimer();
          verificationStatus = true;
        }
      }
    });
  }

  bool get verificationStatus => _verificationStatus;

  set verificationStatus(bool status) {
    _verificationStatus = status;
    notifyListeners();
  }

  int get countDown => _countDown;
  bool get canResend => _canResend;

  // Hàm khởi động đếm ngược
  void _startCountdown() {
    _canResend = false;
    _countDown = 30;
    _timer2 = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countDown > 0) {
        debugPrint("Count : $countDown");
        _countDown--;
      } else {
        _canResend = true;
        _timer2?.cancel();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  // Hủy timer
  void cancelTimer() {
    _countDown = 0;
    _verificationStatus = false;
    _canResend = false;
    _isSendingBlocked = false;
    _timer1?.cancel();
    _timer2?.cancel();

    // Đặt lại giá trị để tránh tham chiếu không cần thiết
    _timer1 = null;
    _timer2 = null;
  }
}
