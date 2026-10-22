import 'dart:io';
import 'dart:ui' as ui;

/// Front-camera captures are mirrored. Flip them so the saved photo matches the preview.
Future<File> unmirrorCameraPhoto(File source) async {
  final bytes = await source.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.translate(image.width.toDouble(), 0);
  canvas.scale(-1, 1);
  canvas.drawImage(image, ui.Offset.zero, ui.Paint());
  final flipped = await recorder.endRecording().toImage(image.width, image.height);
  final data = await flipped.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  flipped.dispose();
  if (data == null) {
    return source;
  }
  final out = File('${source.parent.path}${Platform.pathSeparator}capture_${DateTime.now().millisecondsSinceEpoch}.png');
  await out.writeAsBytes(data.buffer.asUint8List());
  return out;
}
