library watch;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:watcher/watcher.dart';

void main(List<String> arguments) {
  if (arguments.length != 2) {
    print('Usage: watch <assets directory path> <assets output path>');
    return;
  }

  var watcher = DirectoryWatcher(p.absolute(arguments[0]));
  var path = arguments[1];
  watcher.events.listen((event) {
    createAssetsFile(path,(){
      if(event.type == ChangeType.ADD){
        addAsset(path, event.path);
      }
      if(event.type == ChangeType.REMOVE){
        removeAsset(path, event.path);
      }
    });
  }).onError((e){
    print(e);
  });
}

void createAssetsFile(String path,Function onDone) async{
  var myFile = File(path);
  var checkFile = await myFile.exists();
  if(!checkFile){
    await myFile.create(recursive: true);
    await myFile.writeAsString('''class Assets{

}''');
    onDone();
  }else{
    onDone();
  }
}

void addAsset(String path,String assetPath){
  var fileName = assetPath.split('/').last.split('.').first;
  var fileExt = assetPath.split('/').last.split('.').last;
  var classFile = File(path);
  classFile.readAsString().then((String contents) {
    var lines = contents.split('\n');
    var header = lines.first.trim();
    var footer = lines.last.trim();
    lines.removeAt(0);
    lines.removeLast();
    lines.add(' static final String ${ReCase(fileName).camelCase} = "$fileName.$fileExt";');
    classFile.writeAsStringSync('''$header
  ${lines.join("\n")}
$footer''',flush: true);
  });
}

void removeAsset(String path,String assetPath){
  var fileName = assetPath.split('/').last.split('.').first;
  var classFile = File(path);
  classFile.readAsString().then((String contents) {
    var lines = contents.split('\n');
    var header = lines.first.trim();
    var footer = lines.last.trim();
    lines.removeAt(0);
    lines.removeLast();
    var index = lines.indexWhere((line)=>line.contains('static final String ${ReCase(fileName).camelCase}'));
    lines.removeAt(index);
    classFile.writeAsStringSync('''$header
  ${lines.join("\n")}
$footer''',flush: true);
  });
}

