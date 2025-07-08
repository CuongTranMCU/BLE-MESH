import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

import '../themes/mycolors.dart';
import 'constant_values.dart';

Text getText({
  String? feedback,
  double fontSize = 16,
  FontWeight? fontWeight,
}) {
  late Text text;
  if (feedback == "No Fire") {
    text = Text(
      'Safety',
      style: TextStyle(color: Colors.green, fontSize: fontSize, fontWeight: fontWeight),
    );
  } else if (feedback == "Potential Fire") {
    text = Text(
      'Warning',
      style: TextStyle(color: Colors.orange, fontSize: fontSize, fontWeight: fontWeight),
    );
  } else if (feedback == "Fire") {
    text = Text(
      'Fire',
      style: TextStyle(color: Colors.red, fontSize: fontSize, fontWeight: fontWeight),
    );
  } else if (feedback == "Big Fire") {
    text = Text(
      'Big Fire',
      style: TextStyle(color: const Color(0xFFFF0000), fontSize: fontSize, fontWeight: fontWeight),
    );
  } else {
    text = Text(
      'Undefined',
      style: TextStyle(color: Colors.grey, fontSize: fontSize, fontWeight: fontWeight),
    );
  }
  return text;
}

Color getColor({String? feedback}) {
  late Color color;

  if (feedback == "No Fire") {
    color = Colors.green;
  } else if (feedback == "Potential Fire") {
    color = Colors.orange;
  } else if (feedback == "Fire") {
    color = Colors.red;
  } else if (feedback == "Big Fire") {
    color = const Color(0xFFFF0000);
  } else {
    color = Colors.grey;
  }
  return color;
}

Icon getIcon({String? feedback}) {
  if (feedback == "Fire" || feedback == "Big Fire") {
    return const Icon(
      Icons.local_fire_department_rounded,
      color: Colors.red,
      size: 32,
    );
  } else if (feedback == "Potential Fire") {
    return const Icon(
      Icons.warning_amber_rounded,
      color: Colors.orange,
      size: 32,
    );
  } else if (feedback == "No Fire") {
    return const Icon(
      Icons.check_circle_outline,
      color: Colors.green,
      size: 32,
    );
  } else {
    return const Icon(
      Icons.bug_report,
      color: Colors.grey,
      size: 32,
    );
  }
}

Widget getBLESignal(int rssi) {
  const double width = 48;
  const double height = 48;

  if (rssi <= -90) {
    return Image.asset('assets/icons/no connection.png', width: width, height: height);
  } else if (rssi > -90 && rssi <= -80) {
    return Image.asset('assets/icons/low.png', width: width, height: height);
  } else if (rssi > -80 && rssi <= -72) {
    return Image.asset('assets/icons/lightly medium.png', width: width, height: height);
  } else if (rssi > -72 && rssi <= -67) {
    return Image.asset('assets/icons/medium.png', width: width, height: height);
  } else if (rssi > -67 && rssi <= -55) {
    return Image.asset('assets/icons/lightly high.png', width: width, height: height);
  } else if (rssi > -55 && rssi <= -20) {
    return Image.asset('assets/icons/high.png', width: width, height: height);
  } else {
    return Image.asset('assets/icons/error.png', width: width, height: height);
  }
}

Color getLedRGB(List<bool>? ledRGBSignal) {
  if (ledRGBSignal == null) {
    return Colors.grey;
  }

  if (ledRGBSignal[0]) {
    return Colors.red;
  } else if (ledRGBSignal[1]) {
    return Colors.green;
  } else if (ledRGBSignal[2]) {
    return Colors.blue;
  } else {
    return Colors.grey;
  }
}

Widget wifiIcon(int dBm) {
  const double width = 32;
  const double height = 32;

  if (dBm <= -90) {
    return Image.asset("assets/icons/wifi0.png", width: width, height: height);
  } else if (dBm <= -80 && dBm > -90) {
    return Image.asset("assets/icons/wifi1.png", width: width, height: height);
  } else if (dBm <= -70 && dBm > -80) {
    return Image.asset("assets/icons/wifi2.png", width: width, height: height);
  } else if (dBm <= -67 && dBm > -70) {
    return Image.asset("assets/icons/wifi3.png", width: width, height: height);
  } else if (dBm <= -30 && dBm > -67) {
    return Image.asset("assets/icons/wifi4.png", width: width, height: height);
  } else {
    return Image.asset("assets/icons/wifi5.png", width: width, height: height);
  }
}

Widget buildWeatherInfo({IconData? icon, String image = "", required String value, required String label}) {
  return Column(
    children: [
      (icon != null)
          ? Icon(
              icon,
              color: Colors.white,
              size: 34,
            )
          : Image.asset(
              image,
              width: 34,
              height: 34,
              color: Colors.white,
            ),
      const SizedBox(height: 5),
      Text(value, style: const TextStyle(color: TextColor, fontSize: 18)),
      const SizedBox(height: 5),
      Text(label, style: const TextStyle(color: TextColor, fontSize: 14)),
    ],
  );
}

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.textInputType,
    required this.validatorFunction,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
    this.isPassword = false,
  });

  final TextEditingController? controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String hintText;
  final TextInputType textInputType;
  final bool isPassword;
  final int? maxLength;
  final String? Function(String?) validatorFunction;

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  final FocusNode focusNode = FocusNode();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.textInputType,
      obscureText: widget.isPassword ? _obscureText : false,
      maxLength: widget.maxLength,
      focusNode: focusNode,
      validator: (value) {
        return widget.validatorFunction(value);
      },
      decoration: InputDecoration(
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon ??
            (widget.isPassword
                ? IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null),
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: TextColor01),
        filled: true,
        fillColor: focusNode.hasFocus ? FocusedColor : EnabledBorderColor,
        border: InputBorder.none,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: FocusedBorderColor, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: EnabledBorderColor, width: 1.2),
        ),
        errorStyle: const TextStyle(color: ErrorTextColor),
      ),
      style: const TextStyle(color: TextColor01),
    );
  }
}

class CustomDropdownButton2<T> extends StatefulWidget {
  // Giới hạn T cho enum nếu cần
  final T selectedItem;
  final List<T> items;
  final void Function(T?) onSelected;
  final double width;

  const CustomDropdownButton2({
    super.key,
    required this.selectedItem,
    required this.items,
    required this.onSelected,
    this.width = 140,
  });

  @override
  State<CustomDropdownButton2<T>> createState() => _CustomDropdownButton2State<T>();
}

class _CustomDropdownButton2State<T> extends State<CustomDropdownButton2<T>> {
  bool isMenuOpen = false;

  String _itemToString(T item) {
    if (item is HostLabel) {
      return item.protocol;
    } else if (item is ConnectionTypeLabel) {
      return item.type;
    }
    return item.toString();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        value: widget.selectedItem,
        isExpanded: true,
        items: widget.items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              _itemToString(item),
              style: TextStyle(
                fontSize: 14,
                color: (item == widget.selectedItem) ? TextColor03 : TextColor01,
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),

        selectedItemBuilder: (BuildContext context) {
          return widget.items.map((item) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Text(
                _itemToString(item),
                style: TextStyle(
                  color: (isMenuOpen) ? TextColor03 : TextColor01,
                  fontWeight: FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList();
        },
        onChanged: widget.onSelected,
        onMenuStateChange: (isOpen) {
          setState(() {
            isMenuOpen = isOpen;
          });
        },
        buttonStyleData: ButtonStyleData(
          width: widget.width,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isMenuOpen ? FocusedBorderColor : EnabledBorderColor,
              width: isMenuOpen ? 2.0 : 1.2,
            ),
            color: isMenuOpen ? FocusedColor : EnabledBorderColor,
          ),
        ),

        // --- Tùy chỉnh giao diện icon ---
        iconStyleData: const IconStyleData(
          icon: Icon(Icons.arrow_drop_down),
          iconSize: 28,
          iconEnabledColor: IconColor02, // Màu icon khi bật
          iconDisabledColor: Colors.grey, // Màu icon khi tắt
        ),

        // --- Tùy chỉnh giao diện danh sách thả xuống ---
        dropdownStyleData: DropdownStyleData(
          maxHeight: 200, // Chiều cao tối đa của dropdown
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white, // Màu nền dropdown ví dụ
          ),
          offset: const Offset(0, -5), // Điều chỉnh vị trí dropdown
          elevation: 8,
          scrollbarTheme: const ScrollbarThemeData(
            // Tùy chỉnh thanh cuộn nếu cần
            radius: Radius.circular(40),
            thickness: WidgetStatePropertyAll(6),
            thumbVisibility: WidgetStatePropertyAll(true),
          ),
        ),

        // --- Tùy chỉnh giao diện từng mục trong danh sách ---
        menuItemStyleData: MenuItemStyleData(
          height: 40, // Chiều cao từng mục
          padding: const EdgeInsets.symmetric(horizontal: 12), // Padding từng mục
        ),
      ),
    );
  }
}
