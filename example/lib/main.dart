import 'dart:io';

import 'package:thumbnails/thumbnails.dart';
import 'package:camera_camera/page/video.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camera_camera/camera_camera.dart' show Camera, CameraMode, CameraOrientation;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<File> files = [];
  Camera cam;

  @override
  void initState() {
    super.initState();
    cam = Camera(
      mode: CameraMode.fullscreen,
      orientationEnablePhoto: CameraOrientation.landscape,
      onPicture: (picture) => _onPicture(picture),
      enableChangeCamera: false,
    );
  }

  void _onPicture(File picture) {
    print(picture.path);
    setState(() {
      files.add(picture);
    });
  }

  void _onVideo(File video) async {
    print(video.path);
    final Directory extDir = await getApplicationDocumentsDirectory();
    String thumbPath = await Thumbnails.getThumbnail(
      thumbnailFolder: '${extDir.path}/Thumbs',
      videoFile: video.path,
      imageType: ThumbFormat.JPEG,
      quality: 90,
    );
    setState(() {
      files.add(File(thumbPath));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rully")),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.camera_alt,
                color: Colors.black,
              ),
              onPressed: () async {
                showDialog(context: context, builder: (context) => cam);
              }),
          Padding(
            padding: EdgeInsets.only(
              right: 5,
              left: 5,
            ),
          ),
          FloatingActionButton(
              backgroundColor: Colors.white,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(5),
                ),
                width: 10,
                height: 10,
              ),
              onPressed: () async {
                showDialog(
                    context: context,
                    builder: (context) => Video(
                          onVideo: (video) => _onVideo(video),
                        ));
              }),
        ],
      ),
      body: Center(
        child: files.length > 0
            ? Container(
                height: MediaQuery.of(context).size.height * 0.7,
                width: MediaQuery.of(context).size.width * 0.8,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                  ),
                  itemCount: files.length,
                  itemBuilder: (context, index) => Card(
                    child: Image.file(
                      files[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            : Center(child: Text("Tire a foto")),
      ),
    );
  }
}
