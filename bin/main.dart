library watch;

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:watcher/watcher.dart';


File classFile;
List<String> lines = [];
String header = '';
String footer = '';
String basePathStr = '';
String className = '';

void main(List<String> arguments) async{
  if (arguments.length != 2) {
    print('Usage: watch <assets directory path> <assets output path>');
    return;
  }
  var createdDir = await createAssetsFile(arguments[0], isDir: true);
  var watcher = DirectoryWatcher(p.relative(arguments[0]));
  var path = arguments[1];
  classFile = File(path);
  className = classFile.path.split('/').last.split('.').first;
  basePathStr = arguments[0].replaceAll('./', '');
  var existingFiles = await filesInDirectory(Directory(arguments[0]));
  var attachWatcher = (){
    if(existingFiles.isNotEmpty){
      for(var i = 0;i<existingFiles.length;i++){
        addAsset(existingFiles[i].path);
        if(i == existingFiles.length-1){
          watcher.events.listen((event) {
            decideEvent(event);
          }).onError((e) {
            print(e);
          });
        }
      }
    }else{
      watcher.events.listen((event) {
        decideEvent(event);
      }).onError((e) {
        print(e);
      });
    }

  };

  await createAssetsFile(path).then((nf) {
    if (nf != null) {
      putClassCode(classFile).then((f) {
        setFileStr(() {
          attachWatcher();
        });
      });
    }else{
      setFileStr(() {
        attachWatcher();
      });
    }
  });

}

void decideEvent(WatchEvent event) async{
  if (event.type == ChangeType.REMOVE) {
    classFile = await removeAsset(event.path);
  } else if (event.type == ChangeType.ADD) {
    classFile = await addAsset(event.path);
  }
}

Future<File> putClassCode(File myFile) {
  return myFile
      .writeAsString('''class $className{
  static final String basePath = "$basePathStr/";

}''');
}

typedef onFileCreated(dynamic file);

Future<dynamic> createAssetsFile(String path,
    {bool isDir = false}) async {
  var myFile;
  if (!isDir) {
    myFile = classFile;
  } else {
    myFile = Directory(path);
  }
  var checkFile = await myFile.exists();
  if (!checkFile) {
    return myFile.create(recursive: true);
  } else {
    return Future<Null>((){
      return null;
    });
  }
}

void setFileStr(Function onDone){
  classFile.readAsString().then((contents){
    lines = contents.split('\n');
    header = lines.first.trim();
    basePathStr = lines[1];
    footer = lines.last.trim();
    lines.removeAt(0);
    lines.removeAt(1);
    lines.removeLast();
    onDone();
  });
}

Future<File> addAsset(String assetPath) async {
  var fileName = assetPath.split('/').last.split('.').first;
  var fileExt = assetPath.split('/').last.split('.').last;
  await removeAsset(assetPath);
  lines.add('   static final String ${ReCase(fileName).camelCase} = $className.basePath+"$fileName.$fileExt";');
  return classFile.writeAsString('''$header
  ${lines.join("\n")}
$footer''', flush: true);
}

Future<File>  removeAsset(String assetPath) async {
  var fileName = assetPath.split('/').last.split('.').first;
  var index = lines.indexWhere(
      (line) => line.contains('String ${ReCase(fileName).camelCase}'));
  if (index >= 0) {
    lines.removeAt(index);
    return classFile.writeAsString('''$header
  ${lines.join("\n")}
$footer''', flush: true);
  }
}

Future<List<File>> filesInDirectory(Directory dir) async {
  var files = <File>[];
  await for (FileSystemEntity entity in dir.list(recursive: false, followLinks: false)) {
    var type = await FileSystemEntity.type(entity.path);
    if (type == FileSystemEntityType.FILE) {
      files.add(entity);
    }
  }
  return files;
}
