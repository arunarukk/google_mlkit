import 'dart:io';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  XFile? imageFile;
  List<DetectedObject>? objectss;
  List<ImageLabel>? imLabels;
  String scanned = '';

  ui.Image? iimage;

  getImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      imageFile = image;
      _loadImage(imageFile!);
      getRecoText();
      setState(() {});
    }
  }

  _loadImage(XFile file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then((value) => iimage = value);
    setState(() {});
  }

  getRecoText() async {
    final inImage = InputImage.fromFilePath(imageFile!.path);
    final textDet = GoogleMlKit.vision.textRecognizer();
    final dddd = GoogleMlKit.vision.objectDetector(
        options: ObjectDetectorOptions(
            mode: DetectionMode.single,
            classifyObjects: true,
            multipleObjects: true));
    final imageLabeler = GoogleMlKit.vision
        .imageLabeler(ImageLabelerOptions(confidenceThreshold: .7));
    List<ImageLabel> imageLabel = await imageLabeler.processImage(inImage);
    imLabels = imageLabel;

    List<DetectedObject> ffff = await dddd.processImage(inImage);
    RecognizedText recognizedText = await textDet.processImage(inImage);
    await textDet.close();
    await dddd.close();
    await imageLabeler.close();
    objectss = ffff;
    for (var element in ffff) {
      print(ffff.first.labels);
      print('1111111111  ${element.labels}');
    }
    for (var element in imageLabel) {
      print('21212     ${element.index}');
      print('21212     ${(element.confidence * 100).toStringAsFixed(2)}');
    }
    scanned = '';
    for (TextBlock element in recognizedText.blocks) {
      for (TextLine line in element.lines) {
        scanned = "$scanned${line.text}\n";
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (imageFile != null) Image.file(File(imageFile!.path)),
              Text(
                scanned,
                style: Theme.of(context).textTheme.headline4,
              ),
              if (iimage != null && objectss != null)
                FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: iimage!.width.toDouble(),
                    height: iimage!.height.toDouble(),
                    child: CustomPaint(
                      painter: ObjectPainter(iimage!, objectss!, imLabels),
                    ),
                  ),
                ),
              SizedBox(
                height: 10,
              ),
              if (imLabels != null)
                for (var element in imLabels!)
                  Text(
                      '${element.label}  ${(element.confidence * 100).toStringAsFixed(2)}%'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ObjectPainter extends CustomPainter {
  final ui.Image image;
  final List<DetectedObject> objects;
  final List<ImageLabel>? imLabels;
  final List<Rect> rects = [];

  ObjectPainter(this.image, this.objects, this.imLabels) {
    for (var i = 0; i < objects.length; i++) {
      rects.add(objects[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < objects.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(ObjectPainter oldDelegate) {
    return image != oldDelegate.image || objects != oldDelegate.objects;
  }
}
