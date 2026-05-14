import 'dart:ui';
void main() {
  Color c = const Color(0xFF00FF00);
  try {
    print(c.toARGB32());
  } catch (e) {
    print("Error: $e");
    print(c.value);
  }
}
