import 'dart:io';
import 'package:camera_camera/page/bloc/bloc_video.dart';
import 'package:camera_camera/shared/widgets/orientation_icon.dart';
// import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';

class Video extends StatefulWidget {
  final Function(File video) onVideo;

  Video({Key key, this.onVideo}) : super(key: key);

  @override
  _VideoState createState() => _VideoState();
}

class _VideoState extends State<Video> {
  var bloc = BlocVideo();

  @override
  void initState() {
    Screen.keepOn(true);
    super.initState();
    bloc.getCameras();
    bloc.cameras.listen((data) {
      bloc.controllCamera = CameraController(data[0], ResolutionPreset.medium);
      bloc.cameraOn.sink.add(0);
      bloc.controllCamera.initialize().then((_) {
        bloc.selectCamera.sink.add(true);
      });
    });
    SystemChrome.setEnabledSystemUIOverlays([]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
    bloc.dispose();
    Screen.keepOn(false);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    Size sizeImage = size;
    double width = size.width;
    double height = size.height;

    return NativeDeviceOrientationReader(
        useSensor: true,
        builder: (context) {
          NativeDeviceOrientation orientation = NativeDeviceOrientationReader.orientation(context);
          if (orientation == NativeDeviceOrientation.portraitDown || orientation == NativeDeviceOrientation.portraitUp) {
            sizeImage = Size(width, height);
          } else {
            sizeImage = Size(height, width);
          }
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: PreferredSize(
                child: Transform.translate(
                    offset: Offset(0.0, 0.0),
                    child: Container(
                      color: Colors.black54,
                    )),
                preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.12)),
            body: Stack(
              children: <Widget>[
                Center(
                  child: StreamBuilder<bool>(
                      stream: bloc.selectCamera.stream,
                      builder: (context, snapshot) {
                        return snapshot.hasData
                            ? StreamBuilder<bool>(
                                stream: bloc.videoOn.stream,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    if (snapshot.data) {
                                      return OrientationWidget(
                                        orientation: bloc.orientation,
                                        child: AspectRatio(
                                          aspectRatio: bloc.controllCamera.value.aspectRatio,
                                          child: VideoPlayer(
                                            bloc.controllVideo,
                                          ),
                                        ),
                                      );
                                    } else {
                                      return OverflowBox(
                                        maxHeight: size.height,
                                        maxWidth: size.height * bloc.controllCamera.value.aspectRatio,
                                        child: AspectRatio(
                                          aspectRatio: 9 / 16,
                                          child: CameraPreview(bloc.controllCamera),
                                        ),
                                      );
                                    }
                                  } else {
                                    return OverflowBox(
                                      maxHeight: size.height,
                                      maxWidth: size.height * bloc.controllCamera.value.aspectRatio,
                                      child: AspectRatio(
                                        aspectRatio:
                                            orientation == NativeDeviceOrientation.portraitUp || orientation == NativeDeviceOrientation.portraitDown
                                                ? 9 / 16
                                                : 9 / 16,
                                        child: CameraPreview(bloc.controllCamera),
                                      ),
                                    );
                                  }
                                })
                            : Container();
                      }),
                ),
              ],
            ),
            floatingActionButton: StreamBuilder<Object>(
                stream: bloc.videoOn.stream,
                builder: (context, snapshot) {
                  return snapshot.hasData
                      ? snapshot.data
                          ? StreamBuilder(
                              stream: bloc.playPause.stream,
                              builder: (context, snapshot) {
                                return snapshot.hasData
                                    ? snapshot.data
                                        ? FloatingActionButton(
                                            onPressed: () {
                                              bloc.controllVideo.pause();
                                              bloc.playPause.sink.add(false);
                                            },
                                            child: OrientationWidget(
                                              orientation: orientation,
                                              child: Stack(
                                                children: <Widget>[
                                                  Center(
                                                    child: CircleAvatar(
                                                      radius: 35.0,
                                                      backgroundColor: Colors.white,
                                                      child: Icon(
                                                        Icons.pause,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            backgroundColor: Colors.grey.shade800,
                                          )
                                        : OrientationWidget(
                                            orientation: orientation,
                                            child: FloatingActionButton(
                                              onPressed: () {
                                                bloc.controllVideo.play();
                                                bloc.playPause.sink.add(true);
                                              },
                                              child: Stack(
                                                children: <Widget>[
                                                  Center(
                                                    child: CircleAvatar(
                                                      radius: 35.0,
                                                      backgroundColor: Colors.white,
                                                      child: Icon(
                                                        Icons.play_arrow,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.grey.shade800,
                                            ),
                                          )
                                    : Container();
                              },
                            )
                          : FloatingActionButton(
                              onPressed: () {
                                bloc.stopVideoRecording();
                              },
                              child: Stack(
                                children: <Widget>[
                                  Center(
                                    child: CircleAvatar(
                                      radius: 35.0,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.stop,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      height: 60.0,
                                      width: 60.0,
                                      child: StreamBuilder<bool>(
                                          stream: bloc.videoOn.stream,
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              return StreamBuilder<double>(
                                                  stream: bloc.timeVideo.stream,
                                                  builder: (context, snapshot) {
                                                    return CircularProgressIndicator(
                                                      value: snapshot.data,
                                                      strokeWidth: 6.0,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                                    );
                                                  });
                                            } else {
                                              return CircularProgressIndicator(
                                                value: 1.0,
                                                strokeWidth: 6.0,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade800),
                                              );
                                            }
                                          }))
                                ],
                              ),
                              backgroundColor: Colors.grey.shade800,
                            )
                      : FloatingActionButton(
                          onPressed: () {
                            bloc.onVideoRecordButtonPressed(orientation);
                          },
                          child: Center(
                            child: CircleAvatar(
                              radius: 35.0,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.fiber_manual_record,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          backgroundColor: Colors.grey.shade800,
                        );
                }),
            floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
            floatingActionButtonLocation: bloc.fabLocation,
            bottomNavigationBar: BottomAppBar(
              color: Colors.transparent,
              elevation: 0.0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: StreamBuilder<Object>(
                    stream: bloc.videoOn.stream,
                    builder: (context, snapshot) {
                      return snapshot.hasData
                          ? snapshot.data
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    CircleAvatar(
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          bloc.deleteVideo();
                                          bloc.videoOn.sink.add(null);
                                        },
                                      ),
                                      backgroundColor: Colors.red,
                                      radius: 25.0,
                                    ),
                                    CircleAvatar(
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.save,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          if (Navigator.canPop(context) && widget.onVideo == null) {
                                            Navigator.pop(
                                              context,
                                              bloc.videoPath.value,
                                            );
                                          } else {
                                            widget.onVideo(bloc.videoPath.value);
                                            bloc.videoOn.sink.add(null);
                                          }
                                        },
                                      ),
                                      backgroundColor: Colors.grey.shade900,
                                      radius: 25.0,
                                    )
                                  ],
                                )
                              : Container(
                                  width: 0.0,
                                  height: 0.0,
                                )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                CircleAvatar(
                                  child: IconButton(
                                    icon: Icon(Icons.arrow_back, color: Colors.white),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  backgroundColor: Colors.grey.shade900,
                                  radius: 25.0,
                                ),
                                CircleAvatar(
                                  child: IconButton(
                                    icon: StreamBuilder<int>(
                                        stream: bloc.cameraOn,
                                        builder: (context, snapshot) {
                                          return snapshot.hasData
                                              ? snapshot.data == 0
                                                  ? Icon(
                                                      Icons.camera_front,
                                                      color: Colors.white,
                                                    )
                                                  : Icon(
                                                      Icons.camera_rear,
                                                      color: Colors.white,
                                                    )
                                              : Container();
                                        }),
                                    onPressed: () {
                                      bloc.changeCamera();
                                    },
                                  ),
                                  backgroundColor: Colors.grey.shade900,
                                  radius: 25.0,
                                )
                              ],
                            );
                    }),
              ),
            ),
          );
        });
  }
}
