// Helper functions for logging and debugging
void printINFO(String message) {
  print('[INFO] $message');
}

void printERROR(String message) {
  print('[ERROR] $message');
}

void printDEBUG(String message) {
  print('[DEBUG] $message');
}

// Helper variable for language code
String hlCode = "en";

// Helper functions for music service
String formatDuration(Duration duration) {
  String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return "$minutes:$seconds";
}

String generateVisitorId() {
  // Simple visitor ID generation
  return "CgttN24wcmd5UzNSWSi2lvq2BjIKCgJKUBIEGgAgYQ%3D%3D";
}

int getDatestamp() {
  return DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
