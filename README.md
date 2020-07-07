# Assets Indexer for Dart

# IMPORTANT!
You need [Dart SDK](https://dart.dev/get-dart) or [Flutter SDK](https://flutter.dev/docs/get-started/install) to use this CLI tool. 
Also if you already have Flutter installed, you can simply add `PATH_TO_FLUTTER_SDK/bin/cache/dart-sdk/bin` to your `environment PATH`.

### Install dependencies
~~~~
cd FlutterAssetsIndexer && pub get
~~~~

### Add Alias for easy access
~~~~
alias assetsIndexer='dart PATH_TO_CLONED_DIR/bin/main.dart $1 $2'
~~~~

### Now this command will be available in terminal as below
~~~~
assetsIndexer YOUR_IMAGES_DIR_RELATIVE_PATH <SPACE> PATH_TO_INDEXED_FILE
~~~~

#### **Example**
~~~~
assetsIndexer lib/assets/images lib/assets/generated/Images.dart
~~~~
### Now Use it in code as below
~~~~
Image.asset(Images.logo)
~~~~

### Don't forget to import it as below
~~~~
import "Images.dart"
~~~~ 
