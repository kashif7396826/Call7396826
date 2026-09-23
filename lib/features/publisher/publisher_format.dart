/// Matches publisher/dashboard.php's/numbers.php's/calls.php's own formatDuration() exactly
/// (m:ss, not h:mm:ss — these are individual call durations, never expected to run over an hour).
String formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}
