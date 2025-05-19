import 'package:flutter/material.dart';

class CurrentLocation extends StatelessWidget {
  final bool isInOffice;

  const CurrentLocation({Key? key, required this.isInOffice}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.location_on,
          size: 18,
          color: isInOffice ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(
          isInOffice
              ? 'Lokasi anda saat ini : Di Dalam Kantor'
              : 'Lokasi anda saat ini : Diluar Kantor',
          style: TextStyle(
            fontSize: 12,
            color: isInOffice ? Colors.green[700] : Colors.red[700],
          ),
        ),
      ],
    );
  }
}
