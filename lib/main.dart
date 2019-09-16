import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'package:flutter/services.dart';

List<CameraDescription> cameras;

Future<Null> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    cameras = await availableCameras();
  } on QRReaderException catch (e) {
    logError(e.code, e.description);
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  runApp(new MyApp());
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');



class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  QRReaderController controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final navigatorKey = GlobalKey<NavigatorState>();

  AnimationController animationController;

  @override
  void initState() {
    super.initState();

    animationController = new AnimationController(
      vsync: this,
      duration: new Duration(seconds: 5),
    );

    animationController.addListener(() {
      this.setState(() {});
    });
    animationController.forward();
    verticalPosition = Tween<double>(begin: 0.0, end: 300.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.linear))
      ..addStatusListener((state) {
        if (state == AnimationStatus.completed) {
          animationController.reverse();
        } else if (state == AnimationStatus.dismissed) {
          animationController.forward();
        }
      });

    // pick the first available camera
    onNewCameraSelected(cameras[0]);
  }

  Animation<double> verticalPosition;

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      home: new Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            new Container(
              child: new Padding(
                padding: const EdgeInsets.all(0.0),
                child: new Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
            ),
            Center(
              child: Stack(
                children: <Widget>[
                  SizedBox(
                    height: 300.0,
                    width: 300.0,
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.redAccent, width: 2.0)),
                    ),
                  ),
                  Positioned(
                    top: verticalPosition.value,
                    child: Container(
                      width: 300.0,
                      height: 2.0,
                      color: Colors.redAccent,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'No camera selected',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: QRReaderPreview(controller),
      );
    }
  }



  void onCodeRead(dynamic value) {
    getGuestData(value.toString());
    new Future.delayed(const Duration(seconds: 5), controller.startScanning);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = new QRReaderController(cameraDescription, ResolutionPreset.low,
        [CodeFormat.qr, CodeFormat.pdf417], onCodeRead);

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}', Colors.redAccent);
      }
    });

    try {
      await controller.initialize();
    } on QRReaderException catch (e) {
      logError(e.code, e.description);
      showInSnackBar('Error: ${e.code}\n${e.description}', Colors.redAccent);
    }

    if (mounted) {
      setState(() {});
      controller.startScanning();
    }
  }

  void showInSnackBar(String message, Color color) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(behavior: SnackBarBehavior.floating, backgroundColor: color, duration: const Duration(seconds: 5), content: new Text(message)));
  }

  Future getGuestData(String id) async {
    final Firestore _db = Firestore.instance;
    _db.collection('guests').document(id).get().then((doc) {
      if (doc.exists) {
        updateData(id);
        showInSnackBar('${doc['name']} registered successfully', Colors.green);
      } else {
        showInSnackBar('QR Code value does not exist in database', Colors.redAccent);
      }
    });
  }

  updateData(String id) async {
    final Firestore _db = Firestore.instance;
     await _db.collection('guests')
        .document(id)
        .updateData({'date': new DateTime.now()});
  }

}