import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/attendance_provider.dart';
import '../../config/api_config.dart';

class AttendanceHistory extends StatefulWidget {
  const AttendanceHistory({Key? key}) : super(key: key);

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  @override
  void initState() {
    super.initState();
    // Initialize Indonesian locale
    initializeDateFormatting('id_ID', null);
  }

  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy : HH:mm', 'id_ID');
    return dateFormat.format(dateTime);
  }

  String _formatTime(String time) {
    final timeParts = time.split(':');
    if (timeParts.length != 3) return time;
    return '${timeParts[0]}:${timeParts[1]}';
  }

  double _calculateDistance(double latitude, double longitude) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      ApiConfig.officeLatitude,
      ApiConfig.officeLongitude,
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Sudah Absen':
        return Colors.green[100]!;
      case 'Terlambat':
        return Colors.orange[100]!;
      case 'Pulang':
        return Colors.red[100]!;
      default:
        return Colors.red[100]!;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'Sudah Absen':
        return 'Hadir';
      case 'Terlambat':
        return 'Terlambat';
      case 'Pulang':
        return 'Pulang';
      default:
        return 'Tidak Hadir';
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case 'Sudah Absen':
        return Colors.green[800]!;
      case 'Terlambat':
        return Colors.orange[800]!;
      case 'Pulang':
        return Colors.red[800]!;
      default:
        return Colors.red[800]!;
    }
  }

  bool _isAfterCheckOutTime() {
    final now = DateTime.now();
    final checkOutTime = DateTime(
      now.year,
      now.month,
      now.day,
      ApiConfig.checkOutHour,
      ApiConfig.checkOutMinute,
    );
    return now.isAfter(checkOutTime);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Absensi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(height: 10),
        Consumer<AttendanceProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingHistory) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Text(
                  'Error: ${provider.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (provider.attendanceHistory.isEmpty) {
              return const Center(child: Text('Belum ada riwayat absensi'));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.attendanceHistory.length,
              itemBuilder: (context, index) {
                final history = provider.attendanceHistory[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.pink[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 32,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateTime(history.checkInDateTime),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          history.statusCheckIn,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _getStatusText(
                                                history.statusCheckIn,
                                              ),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: _getStatusTextColor(
                                                  history.statusCheckIn,
                                                ),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${_formatTime(history.checkIn)} : ${(_calculateDistance(history.latitudeCheckIn, history.longitudeCheckIn) / 1000).toStringAsFixed(1)} km',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _getStatusTextColor(
                                                history.statusCheckIn,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (history.statusCheckOut != null) ...[
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            history.statusCheckOut,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Pulang ',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: _getStatusTextColor(
                                                  history.statusCheckOut,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${_formatTime(history.checkOut!)} : ${(_calculateDistance(history.latitudeCheckIn, history.longitudeCheckIn) / 1000).toStringAsFixed(1)} km',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: _getStatusTextColor(
                                                  history.statusCheckOut,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (history.checkOut == null &&
                                  _isAfterCheckOutTime()) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      context
                                          .read<AttendanceProvider>()
                                          .checkOut(
                                            latitude: history.latitudeCheckIn,
                                            longitude: history.longitudeCheckIn,
                                            attendanceId: history.id,
                                          );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                    child: const Text('Absen Pulang'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
