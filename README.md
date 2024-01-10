# OpenCV + Flutter
OpenCVをFlutterで動かしてみました。
ここではdart:ffiを使用。
あくまでOpenCVをdart:ffiを用いて動かすことなので、ここではただ単に選択した画像を回転させるアプリケーションになります。
![demo](https://github.com/Inosuke0718/OpenCV_Flutter_Integration/assets/63226783/debb2481-2195-44b4-81ca-1de2024de4a0)

## dart:ffiとは
dart:ffiはforeign function interface. すなわち外部関数インターフェースの略で、
dartから外部のネイティブCライブラリをコールする仕組みを提供するライブラリです。DLLを⽂字通り動的に呼び出すことができます。

## dart:ffiによるDLLの呼び出しは、次の3ステップ
1. DLLをオープンしてDynamicLibraryオブジェクトを作成する
2. Cの関数を呼び出すための、dart関数を作成する
3. 作成したdart関数を使って呼び出す
