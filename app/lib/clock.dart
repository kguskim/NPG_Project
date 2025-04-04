import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Clock extends StatefulWidget {
  const Clock({Key? key}) : super(key: key);

  State<StatefulWidget> createState() {
    return _ClockState();
  }
}

class _ClockState extends State<Clock> {
  String _time = "";

  void initState() {
    Timer.periodic(const Duration(seconds: 1), _getTime);
    super.initState();
  }

  void _getTime(Timer timer) {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('HH:mm:ss');
    String formattedTime = formatter.format(now);
    setState(() => _time = formattedTime);
  }

  Widget build(BuildContext context) {
    return Text(
      _time,
      style: const TextStyle(
        fontSize: 50.0,
        color: Color.fromARGB(255, 255, 255, 255),
      ),
    );
  }
}
