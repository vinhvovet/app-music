class LyricLine {
  final String text;
  final int startTime; // Thời gian bắt đầu (milliseconds)
  final int endTime;   // Thời gian kết thúc (milliseconds)

  LyricLine({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      text: json['text'] ?? '',
      startTime: json['startTime'] ?? 0,
      endTime: json['endTime'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  // Kiểm tra xem một thời điểm có nằm trong khoảng thời gian của câu này không
  bool isActiveAt(int currentTime) {
    return currentTime >= startTime && currentTime <= endTime;
  }
}

class LyricsData {
  final List<LyricLine> lines;

  LyricsData({required this.lines});

  factory LyricsData.fromJson(Map<String, dynamic> json) {
    List<dynamic> linesJson = json['lines'] ?? [];
    List<LyricLine> lines = linesJson
        .map((lineJson) => LyricLine.fromJson(lineJson))
        .toList();
    
    return LyricsData(lines: lines);
  }

  Map<String, dynamic> toJson() {
    return {
      'lines': lines.map((line) => line.toJson()).toList(),
    };
  }

  // Tìm câu lời đang được hát tại thời điểm hiện tại
  LyricLine? getCurrentLine(int currentTime) {
    for (LyricLine line in lines) {
      if (line.isActiveAt(currentTime)) {
        return line;
      }
    }
    return null;
  }

  // Lấy index của câu lời đang được hát
  int getCurrentLineIndex(int currentTime) {
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].isActiveAt(currentTime)) {
        return i;
      }
    }
    return -1;
  }
}
