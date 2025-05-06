import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Progressor.dart';

class LoadingDial extends StatefulWidget{

  String title;
  String message;
  double width;
  double height;
  double fontSize;
  Stream<double>? progressStream;
  Progressor? progressor;

  LoadingDial(
      {
        super.key,
        this.title = "",
        this.message = "",
        required this.width,
        required this.height,
        required this.fontSize,
        required this.progressStream,
        required this.progressor,
      }
      );

  @override
  State<StatefulWidget> createState() {
    return LoadingDialState();
  }


}

class LoadingDialState extends State<LoadingDial>{

  StreamSubscription<double>? progressStreamSub;

  double? progress;
  bool isCanceling = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    if(widget.progressStream != null){
      progressStreamSub = widget.progressStream!.listen((event) {
        setState(() {
          progress = event;
        });
      });
    }
  }

  @override
  void dispose(){
    super.dispose();
    progressStreamSub?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
            children: [
              widget.title.isNotEmpty ? Text(widget.title, style: TextStyle(fontSize: widget.fontSize),) : const SizedBox.shrink(),
              widget.message.isNotEmpty ? Padding(
                padding: const EdgeInsets.all(7),
                child: Text(widget.message, style: TextStyle(fontSize: widget.fontSize),),
              ) : const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.all(5),
                child: LinearProgressIndicator(
                  value: progress,
                )
              ),
              progress != null ? Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  "${((progress!*10000).round()/100)} %",
                  style: TextStyle(
                    fontSize: widget.fontSize-2,
                  ),
                ),
              ) : const SizedBox.shrink(),
              const SizedBox(height: 10,),
              widget.progressor != null ? TextButton(
                  onPressed: isCanceling ? null : () {
                    widget.progressor?.cancelProgress();
                    setState(() {
                      isCanceling = true;
                    });
                  },
                  child: Text(
                    isCanceling ? "Canceling..." : "Cancel",
                    style: TextStyle(
                      fontSize: widget.fontSize,
                    ),
                  )
              ) : const SizedBox.shrink(),
            ]
        ),
      ),
    );
  }

  void close(){
    Navigator.pop(context);
  }

}
