import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:surf_detect/ui/camera_page.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class TransCmd {
  SendPort? sendport;
  String? srcdir;
  String? dstdir;
  int rotangl;

  TransCmd(this.sendport, this.srcdir, this.dstdir, this.rotangl);
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isCameraReady = false;

  late String _outpath;
  late Pointer<Utf8> outpathPointer;
  late DynamicLibrary dylib;
  late Function cameraopen;
  late Function cameraclose;
  // late Function capture;
  bool onGo = true;
  bool busy = false;
  int mode = 0;

  String srcdir = "";
  String dstdir = "";
  int rotangle = 180;
  String transmsg = "";
  String imgPath = "";

  @override
  void initState() {
    super.initState();

    availableCameras().then((cameras) {
      if (cameras.isNotEmpty && _cameraController == null) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
        );

        _cameraController!.initialize().then((_) {
          setState(() {
            _isCameraReady = true;
          });
        });
      }
    });

    super.initState();
    dylib = DynamicLibrary.open("libOpenCV_ffi.so");
    cameraopen = dylib.lookupFunction<Void Function(), void Function()>("open");

    cameraclose =
        dylib.lookupFunction<Void Function(), void Function()>("close");
    Function rotImg = dylib.lookupFunction<
        Void Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
        void Function(Pointer<Utf8>, Pointer<Utf8>, int)>("RotImg");
  }

  static void isoTrans(TransCmd cmd) {
    String srcpath = cmd.srcdir ?? "";
    String dstdir = cmd.dstdir ?? "";
    DynamicLibrary dylib = DynamicLibrary.open("libOpenCV_ffi.so");

    Function rotImg = dylib.lookupFunction<
        Void Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
        void Function(Pointer<Utf8>, Pointer<Utf8>, int)>("RotImg");

    try {
      final outPath =
          "$dstdir/${srcpath.split('/').last}".toNativeUtf8().cast<Uint8>();
      final inPath = srcpath.toNativeUtf8().cast<Uint8>();
      rotImg(inPath, outPath, cmd.rotangl);
    } catch (e) {
      cmd.sendport?.send(e.toString());
    }
    cmd.sendport?.send("end");
    // imgPath = "$dstdir/${srcpath.split('/').last}";
  }

  /*
isoTrans関数を新しいIsolateで実⾏し、画像変換処理を実⾏します。
ReceivePortを使って、メインIsolateと新しいIsolate間の通信を⾏います。
*/
  void trans(srcdir) {
    final ReceivePort receivePort = ReceivePort();
    // 通信側からのコールバック
    receivePort.listen((message) {
      if (message == "end") {
        receivePort.close();
      }
      setState(() {
        transmsg = message;
      });
    });
    Isolate.spawn(
        isoTrans,
        TransCmd(receivePort.sendPort, srcdir, "/storage/emulated/0/DCIM",
            rotangle));
  }

  void _onTakePicture(BuildContext context) async {
    XFile image = await _cameraController!.takePicture();
    trans(image.path);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoPreview(
          imagePath: image.path,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a photo')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: _cameraController != null && _isCameraReady
                  ? CameraPreview(_cameraController!)
                  : Container(
                      color: Colors.grey,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _cameraController != null
                    ? () => _onTakePicture(context)
                    : null,
                child: const Text('Take a photo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
