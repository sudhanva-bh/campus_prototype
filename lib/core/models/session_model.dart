class ClassSession {
  final String id;
  final String courseId;
  final String courseName;
  final String room;
  final String type;
  final String instructorId;
  
  // Raw Scheduling Data (Rules)
  final String startTimeStr; // "14:00"
  final String endTimeStr;   // "15:30"
  final bool isRecurring;
  final int? dayOfWeek;      // 1 = Monday, 7 = Sunday
  final DateTime? startDate;
  final DateTime? endDate;
  final List<DateTime> excludedDates;

  // Derived (Computed) Properties for UI
  final DateTime? activeStartTime; 
  final DateTime? activeEndTime;

  ClassSession({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.room,
    required this.type,
    required this.instructorId,
    required this.startTimeStr,
    required this.endTimeStr,
    this.isRecurring = false,
    this.dayOfWeek,
    this.startDate,
    this.endDate,
    this.excludedDates = const [],
    this.activeStartTime,
    this.activeEndTime,
  });

  factory ClassSession.fromJson(Map<String, dynamic> json) {
    // Helper to parse dates (YYYY-MM-DD)
    DateTime? parseDate(dynamic date) {
      if (date is String && date.isNotEmpty) return DateTime.tryParse(date);
      return null;
    }

    // Helper to parse excluded dates list
    List<DateTime> parseExcluded(dynamic list) {
      if (list is List) {
        return list.map((e) => parseDate(e)).whereType<DateTime>().toList();
      }
      return [];
    }

    return ClassSession(
      id: json['session_id'] ?? json['id'] ?? '',
      courseId: json['course_id'] ?? '',
      courseName: json['course_name'] ?? json['course_id'] ?? 'Unknown Course',
      room: json['room'] ?? 'TBD',
      type: json['type'] ?? 'Lecture',
      instructorId: json['faculty_id'] ?? '', // API uses 'faculty_id'
      
      // Store raw time strings directly
      startTimeStr: json['start_time'] ?? '09:00',
      endTimeStr: json['end_time'] ?? '10:00',
      
      isRecurring: json['recurring'] ?? false,
      dayOfWeek: json['day_of_week'],
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      excludedDates: parseExcluded(json['excluded_dates']),
    );
  }

  // Create a specific instance for a specific date
  ClassSession? resolveForDate(DateTime date) {
    // 1. Check Date Range
    if (startDate != null && date.isBefore(startDate!)) return null;
    if (endDate != null && date.isAfter(endDate!.add(const Duration(days: 1)))) return null;

    // 2. Check Day of Week (if recurring)
    if (isRecurring && dayOfWeek != null) {
      if (date.weekday != dayOfWeek) return null;
    }

    // 3. Check Excluded Dates
    for (var excluded in excludedDates) {
      if (excluded.year == date.year && excluded.month == date.month && excluded.day == date.day) {
        return null;
      }
    }

    // 4. Construct DateTime objects for this specific day
    try {
      final startParts = startTimeStr.split(':');
      final endParts = endTimeStr.split(':');
      
      final startDt = DateTime(
        date.year, date.month, date.day, 
        int.parse(startParts[0]), int.parse(startParts[1])
      );
      
      final endDt = DateTime(
        date.year, date.month, date.day, 
        int.parse(endParts[0]), int.parse(endParts[1])
      );

      // Return a copy with active times set
      return ClassSession(
        id: id,
        courseId: courseId,
        courseName: courseName,
        room: room,
        type: type,
        instructorId: instructorId,
        startTimeStr: startTimeStr,
        endTimeStr: endTimeStr,
        isRecurring: isRecurring,
        dayOfWeek: dayOfWeek,
        startDate: startDate,
        endDate: endDate,
        excludedDates: excludedDates,
        activeStartTime: startDt,
        activeEndTime: endDt,
      );
    } catch (e) {
      print("Error resolving time for session $id: $e");
      return null;
    }
  }
}