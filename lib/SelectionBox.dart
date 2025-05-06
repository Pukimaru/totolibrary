import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toto/Object/DayPrizesObj.dart';
import 'package:toto/main.dart';

import 'Shape/MyShape.dart';
import 'Util/Pair.dart';

class SelectionBox extends StatefulWidget{

  MainPageState mainPageState;
  Stream<List<DayPrizesObj>> onSelectionChanged_stream;
  StreamController<Pair<SelectionStage, Rect?>> selectionBox_StreamController;

  Widget? child;
  double width;
  double height;

  SelectionBox(
      {
        super.key,
        required this.mainPageState,
        required this.onSelectionChanged_stream,
        required this.selectionBox_StreamController,
        this.child,
        required this.width,
        required this.height,
      }
  );

  @override
  State<StatefulWidget> createState() {
    return SelectionBoxState();
  }

}

class SelectionBoxState extends State<SelectionBox>{

  bool selectedListIsEmpty = true;

  StreamSubscription<List<DayPrizesObj>>? onSelectionChanged_streamSubcription;

  Offset? startSelectionPointGlobal;  Offset? startSelectionPointLocal;
  Offset? endSelectionPointGlobal;    Offset? endSelectionPointLocal;

  @override
  void initState() {
    onSelectionChanged_streamSubcription = widget.onSelectionChanged_stream.listen((event) {
        if(selectedListIsEmpty && event.isNotEmpty){
          setState(() {
            selectedListIsEmpty = false;
          });
        }else if(!selectedListIsEmpty && event.isEmpty){
          setState(() {
            selectedListIsEmpty = true;
            widget.selectionBox_StreamController.sink.add(Pair(SelectionStage.tapOutSide, null));
          });
        }
    });
    super.initState();
  }

  @override
  void dispose() {
    onSelectionChanged_streamSubcription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child ?? const SizedBox.shrink(),
        Positioned(
          left: getRectLeftLocal(),
          top: getRectTopLocal(),
          child: CustomPaint(
            size: Size(getRectRightLocal()-getRectLeftLocal(), getRectBottomLocal()-getRectTopLocal()),
            painter: RectangularPainter(
              color: Colors.blue,
              paintingStyle: PaintingStyle.stroke,
              widthStroke: 2,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {

            if(selectedListIsEmpty){
              widget.mainPageState.setShowRelevant(false);

              setState(() {
                startSelectionPointGlobal = Offset(details.globalPosition.dx, details.globalPosition.dy);
                startSelectionPointLocal = Offset(details.localPosition.dx, details.localPosition.dy);
              });

              Rect rect = Rect.fromLTRB(getRectLeftGlobal(), getRectTopGlobal(), getRectRightGlobal(), getRectBottomGlobal());
              widget.selectionBox_StreamController.sink.add(Pair<SelectionStage, Rect?>(SelectionStage.panStart, rect));
            }

          },
          onPanUpdate: (details) {

            if(selectedListIsEmpty){
              setState(() {
                endSelectionPointGlobal = Offset(details.globalPosition.dx, details.globalPosition.dy);
                endSelectionPointLocal = Offset(details.localPosition.dx, details.localPosition.dy);
              });

              Rect rect = Rect.fromLTRB(getRectLeftGlobal(), getRectTopGlobal(), getRectRightGlobal(), getRectBottomGlobal());
              widget.selectionBox_StreamController.sink.add(Pair<SelectionStage, Rect?>(SelectionStage.panUpdate, rect));
            }

          },
          onPanEnd: (details) {

            if(selectedListIsEmpty){
              widget.mainPageState.setShowRelevant(true);

              setState(() {
                startSelectionPointGlobal = null; startSelectionPointLocal = null;
                endSelectionPointGlobal = null; endSelectionPointLocal = null;
              });

              Rect rect = Rect.fromLTRB(getRectLeftGlobal(), getRectTopGlobal(), getRectRightGlobal(), getRectBottomGlobal());
              widget.selectionBox_StreamController.sink.add(Pair<SelectionStage, Rect?>(SelectionStage.panEnd, rect));
            }

          },
          child: SizedBox(
            width: widget.width,
            height: widget.height,
          ),
        ),
      ],
    );
  }

  double getRectLeftLocal(){

    if(startSelectionPointLocal != null && endSelectionPointLocal != null){

      if(startSelectionPointLocal!.dx < endSelectionPointLocal!.dx){
          return startSelectionPointLocal!.dx;
      }else{
          return endSelectionPointLocal!.dx;
      }
    }

    return 0;
  }
  double getRectTopLocal(){
    if(startSelectionPointLocal != null && endSelectionPointLocal != null){

      if(startSelectionPointLocal!.dy < endSelectionPointLocal!.dy){
        return startSelectionPointLocal!.dy;
      }else{
        return endSelectionPointLocal!.dy;
      }
    }

    return 0;
  }
  double getRectRightLocal(){
    if(startSelectionPointLocal != null && endSelectionPointLocal != null){

      if(startSelectionPointLocal!.dx > endSelectionPointLocal!.dx){
        return startSelectionPointLocal!.dx;
      }else{
        return endSelectionPointLocal!.dx;
      }
    }

    return 0;
  }
  double getRectBottomLocal(){
    if(startSelectionPointLocal != null && endSelectionPointLocal != null){

      if(startSelectionPointLocal!.dy > endSelectionPointLocal!.dy){
        return startSelectionPointLocal!.dy;
      }else{
        return endSelectionPointLocal!.dy;
      }
    }

    return 0;
  }

  double getRectLeftGlobal(){

    if(startSelectionPointGlobal != null && endSelectionPointGlobal != null){

      if(startSelectionPointGlobal!.dx < endSelectionPointGlobal!.dx){
        return startSelectionPointGlobal!.dx;
      }else{
        return endSelectionPointGlobal!.dx;
      }
    }

    return 0;
  }
  double getRectTopGlobal(){
    if(startSelectionPointGlobal != null && endSelectionPointGlobal != null){

      if(startSelectionPointGlobal!.dy < endSelectionPointGlobal!.dy){
        return startSelectionPointGlobal!.dy;
      }else{
        return endSelectionPointGlobal!.dy;
      }
    }

    return 0;
  }
  double getRectRightGlobal(){
    if(startSelectionPointGlobal != null && endSelectionPointGlobal != null){

      if(startSelectionPointGlobal!.dx > endSelectionPointGlobal!.dx){
        return startSelectionPointGlobal!.dx;
      }else{
        return endSelectionPointGlobal!.dx;
      }
    }

    return 0;
  }
  double getRectBottomGlobal(){
    if(startSelectionPointGlobal != null && endSelectionPointGlobal != null){

      if(startSelectionPointGlobal!.dy > endSelectionPointGlobal!.dy){
        return startSelectionPointGlobal!.dy;
      }else{
        return endSelectionPointGlobal!.dy;
      }
    }

    return 0;
  }
}

enum SelectionStage{
  panStart, panUpdate, panEnd, tapOutSide
}