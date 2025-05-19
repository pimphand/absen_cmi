<?php

namespace App\Http\Controllers;

use App\Models\Attendance;
use Carbon\Carbon;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function checkIn(Request $request)
    {
        try {
            $user = auth()->user();
            $today = Carbon::now()->format('Y-m-d');

            // Check if already checked in today
            $existingAttendance = Attendance::where('user_id', $user->id)
                ->whereDate('check_in', $today)
                ->first();

            if ($existingAttendance) {
                return response()->json([
                    'message' => 'Anda sudah melakukan absensi hari ini',
                ], 400);
            }

            // Validate request
            $request->validate([
                'latitude_check_in' => 'required|numeric',
                'longitude_check_in' => 'required|numeric',
                'jarak' => 'required|numeric',
            ]);

            // Create new attendance record
            $attendance = new Attendance();
            $attendance->user_id = $user->id;
            $attendance->check_in = Carbon::now();
            $attendance->latitude_check_in = $request->latitude_check_in;
            $attendance->longitude_check_in = $request->longitude_check_in;
            $attendance->jarak = $request->jarak;
            $attendance->status = 'hadir';
            $attendance->save();

            return response()->json([
                'message' => 'Absensi berhasil',
                'data' => $attendance,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Terjadi kesalahan: ' . $e->getMessage(),
            ], 500);
        }
    }
}
