library watch;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quartet/quartet.dart';
import 'package:watcher/watcher.dart';


File classFile;
List<String > templateFile;
List<String> lines = [];
String header = '';
String footer = '';
String basePathStr = '';
String className = '';
const String BASE_PATH_HOLDER = '{{BASE_PATH}}';
const String CLASS_NAME_HOLDER = '{{CLASS_NAME}}';
const String VAR_NAME_HOLDER = '{{VAR_NAME}}';
const String FILE_NAME_HOLDER = '{{FILE_NAME}}';

void main(List<String> arguments) async{
  if (arguments.length != 2) {
    print('Usage: watch <assets directory path> <assets output path>');
    return;
  }
  var createdDir = await createAssetsFile(arguments[0], isDir: true);
  //var watcher = DirectoryWatcher(p.relative(arguments[0]));
  var path = arguments[1];
  classFile = File(path);
  if(await classFile.exists()){
    await classFile.delete();
  }
  var tplPath = Platform.script.path;
  var tplSplit = tplPath.split('/');
  tplSplit.removeLast();
  tplPath = tplSplit.join('/');
  templateFile = File('${tplPath}/../AppImages.templ').readAsLinesSync();
  className = classFile.path.split('/').last.split('.').first;
  basePathStr = arguments[0].replaceAll('./', '');
  var existingFiles = await filesInDirectory(Directory(arguments[0]));
  var attachWatcher = (){
    if(existingFiles.isNotEmpty){
      for(var i = 0;i<existingFiles.length;i++){
        addAsset(existingFiles[i].path);
        if(i == existingFiles.length-1){
          print('DONE : Mapped ${existingFiles.length} Files');
          //connectWatcher(watcher);
        }
      }
    }else{
     //connectWatcher(watcher);
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


void connectWatcher(DirectoryWatcher watcher){
  watcher.events.listen((event) {
    decideEvent(event);
  }).onError((e) {
    print(e);
  });
}

void decideEvent(WatchEvent event) async{
  print('Change Detected');
  if (event.type == ChangeType.REMOVE) {
    print('Removing Assets');
    classFile = await removeAsset(event.path);
  } else if (event.type == ChangeType.ADD) {
    print('Adding Assets');
    var f = await addAsset(event.path);
    if(f != null){
      classFile = f;
    }
  }
}

Future<File> putClassCode(File myFile) {
  var classNameLine = templateFile[0].replaceAll(CLASS_NAME_HOLDER, className);
  var basePathLine = templateFile[1].replaceAll(BASE_PATH_HOLDER, basePathStr);
  var closingLine = templateFile[3];
  return myFile
      .writeAsString(classNameLine+'\n'+basePathLine+'\n\n'+closingLine);
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
    lines = lines.join('\n').split(';');
    lines = lines.map((line)=>line.trim()).toList();
    onDone();
  });
}

Future<File> addAsset(String assetPath) async {
  var fileName = assetPath.split('/').last.split('.').first;
  var fileExt = assetPath.split('/').last.split('.').last;
  if(fileName.isEmpty){
    return null;
  }
  var varLine = templateFile[2]
      .replaceAll(VAR_NAME_HOLDER, camelCase(fileName))
      .replaceAll(FILE_NAME_HOLDER, '$fileName.$fileExt')
      .replaceAll(CLASS_NAME_HOLDER, className);
  await removeAsset(varLine);
  lines.add(varLine);
  return classFile.writeAsString('''$header
${basePathStr}
${lines.join("\n")}
$footer''', flush: true);
}

Future<File>  removeAsset(String line) async {
  var index = lines.indexWhere(
      (line) => line.contains(line));
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
