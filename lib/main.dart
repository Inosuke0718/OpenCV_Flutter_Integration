import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart'; // 追加プラグインの指定
import 'package:path_provider/path_provider.dart'; // 追加プラグインの指定

/*
main関数: アプリケーションのエントリーポイントで、MyHomePageをルートウィジェットとして設定しています。
*/
void main() {
  runApp(const MaterialApp(
    home: MyHomePage(),
  ));
}

/*
MyHomePageクラス: StatefulWidgetを継承し、アプリの状態を管理します。createStateメソッドで状態オ
ブジェクトを⽣成します。
*/
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/*
_MyHomePageStateクラス: アプリの状態を管理するStateクラスです。いくつかの変数が定義されており、画像
ファイルのパスや画像ウィジェット、ライブラリ関数などを保持しています。
*/
class _MyHomePageState extends State<MyHomePage> {
  String imagefile = ""; // AppBarタイトル
  Image? img; // 画像表⽰Widget
  late String _outpath;
  late DynamicLibrary dylib;
  late Function rotimage;
/*
initStateメソッド: Stateオブジェクトの初期化時に呼ばれるメソッドで、プラットフォームがAndroidか
Windowsかによってオープンする共有ライブラリのファイル名を切り分けています。共有ライブラリをオープンして⽣成された
dylibオブジェクトから、RotImgという関数をロードしています。
*/
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      dylib = DynamicLibrary.open("libOpenCV_ffi.so");
    } else
      20;
    if (Platform.isWindows) {
      dylib = DynamicLibrary.open("OpenCVProc.dll");
    } else if (Platform.isLinux) {
      dylib = DynamicLibrary.open("/home/pie/libOpenCV_ffi.so");
    }
    rotimage = dylib.lookupFunction<
        Void Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
        void Function(Pointer<Utf8>, Pointer<Utf8>, int)>("RotImg");
  }

/*
didChangeDependenciesメソッド: ウィジェットの依存関係が変更されたときに呼ばれるメソッドで、⼀時ディレク
トリのパスを取得し、出⼒ファイルのパスを設定しています。
*/
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    final directory = await getTemporaryDirectory();
    _outpath = "${directory.path}/output.jpg";
  }

/*
_loadImageメソッド: 非同期でファイル選択ダイアログを開き、画像ファイルを選択して読み込むメソッドです。選択
した画像ファイルのパスをimagefileにセットし、画像ウィジェットにセットしています。
*/
  void _loadImage() async {
    var res = await FilePicker.platform.pickFiles(); // ファイル選択ダイアログ
    if (res != null) {
      setState(() {
        // 状態変化を通知するメソッド
        imagefile = res.files[0].path ?? ""; // AppBarタイトルにファイル名セット
        img = Image.file(File(imagefile)); // Image Widgetに画像セット
      });
    }
  }

/*
_rotateImageメソッド: 非同期で画像を回転させるメソッドです。rotimage関数を使って画像ファイルを回転さ
せ、出⼒ファイルに保存します。その後、出⼒ファイルを読み込んで画像ウィジェットにセットしています。
*/
  void _rotateImage() async {
    final outpathPointer = _outpath.toNativeUtf8();
    final inpathPointer = imagefile.toNativeUtf8();
    rotimage(inpathPointer, outpathPointer, 0);
    Uint8List imageData = File(_outpath).readAsBytesSync();
    img = Image.memory(imageData);
    imagefile = _outpath;

    setState(() {});
  }

/*
21
buildメソッド: ウィジェットの階層構造を定義するメソッドで、アプリケーションのUIを構築しています。AppBarには
画像ファイル名が表⽰され、回転ボタンと画像選択ボタンが配置されています。また、画像は中央に表⽰され、画像が
選択されていない場合は「no image」というテキストが表⽰されます。
*/
  @override
  Widget build(BuildContext context) {
    //Scaffold: 基本的なマテリアルデザインのビジュアルレイアウト構造を提供します。
    return Scaffold(
      //AppBar: アプリケーションの上部に表⽰されるバーで、画像ファイル名が表⽰されます。
      //また、回転ボタンと画像選択ボタンが配置されています。これらのボタンは、
      //それぞれ_rotateImageメソッドと_loadImageメソッドを呼び出すために使⽤されます。
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(imagefile),
        actions: [
          // ここに並べたボタンWidgetがAppBarに並ぶ
          IconButton(
              onPressed: _rotateImage, icon: const Icon(Icons.rotate_right)),
          IconButton(onPressed: _loadImage, icon: const Icon(Icons.image))
        ],
      ),
      //body: アプリケーションの主要なコンテンツ領域で、画像ウィジェット（img）が配置されています。
      //imgは、画像ファイルが選択されている場合に画像を表⽰し、選択されていない場合には「no image」
      //というテキストが表⽰されます。
      body: Center(
        child: img ??
            const Text(
              'no image',
            ),
      ),
    );
  }
}
