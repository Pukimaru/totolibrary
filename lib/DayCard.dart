import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toto/Object/PrizeObj.dart';
import 'package:toto/PrizeCard.dart';
import 'package:toto/Util/MyUtil.dart';

import 'Object/DayPrizesObj.dart';
import 'Object/RelevantDetail.dart';
import 'OuterBox.dart';
import 'SelectionBox.dart';
import 'Util/Pair.dart';
import 'Window.dart';
import 'main.dart';

class DayCard extends StatefulWidget{

  MainPageState mainPageState;
  int index;
  double fontSize;
  Color? fontColor;
  double prizePadding;
  DayPrizesObj dayPrizesObj;
  bool showRelevant;
  bool show6D;

  Stream<RelevantDetail?> relevant_stream;
  Stream<List<Pair<String, Color>>> filter_stream;
  Stream<List<DayPrizesObj>> onSelectionChanged_stream;
  Stream<Pair<SelectionStage, Rect?>>? selectionBox_stream;
  Stream<Pair<GeneralGestureType, Map<String, dynamic>>> generalGesture_stream;

  String? presetPrizeHovered;

  DayCard(
    {
      super.key,
      required this.mainPageState,
      required this.index,
      required this.fontSize,
      this.fontColor,
      required this.dayPrizesObj,
      this.prizePadding = 3,
      required this.showRelevant,
      required this.show6D,
      required this.relevant_stream,
      required this.onSelectionChanged_stream,
      required this.selectionBox_stream,
      required this.filter_stream,
      required this.generalGesture_stream,
      this.presetPrizeHovered
    }
  );

  @override
  State<StatefulWidget> createState() {
      return DayCardState();
  }

}

class DayCardState extends State<DayCard>{

  StreamSubscription<List<DayPrizesObj>>? onSelectionChanged_StreamSubScription;
  StreamSubscription<Pair<SelectionStage, Rect?>>? selectionBox_StreamSubScription;

  List<DayPrizesObj> selectedList = [];

  Rect? selectionRec;

  @override
  void initState() {
    onSelectionChanged_StreamSubScription = widget.onSelectionChanged_stream.listen((event) {
        setState(() {
          selectedList = event;
        });
    });

    if(widget.selectionBox_stream != null){
      selectionBox_StreamSubScription = widget.selectionBox_stream!.listen((event) {

        SelectionStage selectionStage = event.first!;
        Rect? rect = event.second;

        switch(selectionStage){
          case SelectionStage.panStart:

            break;

          case SelectionStage.panUpdate:
            setState(() {
              selectionRec = rect;
            });

            break;

          case SelectionStage.panEnd:
            if(selectionRec != null && isInsideRectangle(selectionRec!)){
              widget.mainPageState.addToSelectionList(widget.dayPrizesObj);
            }
            break;

          case SelectionStage.tapOutSide:
            setState(() {
              selectionRec = rect;
            });
        }
      });
    }
    super.initState();
    super.initState();
  }

  @override
  void dispose(){
    onSelectionChanged_StreamSubScription?.cancel();
    selectionBox_StreamSubScription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      return Draggable<List<DayPrizesObj>>(
        hitTestBehavior: HitTestBehavior.translucent,
        data: widget.mainPageState.selectedDayPrizesObj,
        onDragStarted: () {
          widget.mainPageState.setShowRelevant(false);
        },
        onDragEnd: (details) {
          widget.mainPageState.setShowRelevant(true);
        },
        feedbackOffset: Offset(getThisWidth()/2, 0),
        feedback: selectedList.contains(widget.dayPrizesObj) ? Material(
          child: Container(
              width: getThisWidth(),
              height: 50,
              color: Colors.blue,
              child: Center(
                child: Text(
                  "x${widget.mainPageState.selectedDayPrizesObj.length}",
                  style: TextStyle(
                    fontSize: widget.fontSize+5
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ),
        ) : const SizedBox.shrink(),
        child: Container(
          width: getThisWidth(),
          color:  selectionRec != null && isInsideRectangle(selectionRec!) ? Colors.yellowAccent.withAlpha(50) : widget.index % 2 == 0 ? Colors.blue.withAlpha(50) : null,
          child: Row(
            children: [
              SizedBox(
                child: Text(
                  widget.dayPrizesObj.type == PrizeObj.TYPE_MAGNUM4D ? "M" :
                    widget.dayPrizesObj.type == PrizeObj.TYPE_TOTO ? "T" : "D",
                  style: TextStyle(
                    color: widget.dayPrizesObj.type == PrizeObj.TYPE_MAGNUM4D ? Colors.yellow :
                            widget.dayPrizesObj.type == PrizeObj.TYPE_TOTO ? Colors.red : Colors.blue,
                    fontSize: widget.fontSize
                  ),
                ),
                //child: Image.asset("assets/magnum.ico", width: 20, fit: BoxFit.fitWidth,),
              ),
              SizedBox(
                width: getDateTextWidth(),
                height: MyUtil.getHeightWithFontSize(widget.fontSize),
                child: Text(
                  widget.dayPrizesObj.getDateString(false, true),
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    color: widget.fontColor
                  ),
                ),
              ),
              SizedBox(
                width: getSeperatorTextWidth(),
                child: Text(
                  " - ",
                  style: TextStyle(
                      fontSize: widget.fontSize,
                      color: widget.fontColor
                  ),
                ),
              ),
              ...buildPrizeObjList()
            ],
          ),
        ),
      );
  }

  List<Widget> buildPrizeObjList(){

    List<PrizeObj> prizeObjList = [];

    if(widget.show6D){

      if(widget.dayPrizesObj.getFirstPrizeObj6D() != null){
        prizeObjList.add(widget.dayPrizesObj.getFirstPrizeObj6D()!);
      }
      if(widget.dayPrizesObj.getSecondPrizeObj6D() != null){
        prizeObjList.add(widget.dayPrizesObj.getSecondPrizeObj6D()!);
      }
      if(widget.dayPrizesObj.getThirdPrizeObj6D() != null){
        prizeObjList.add(widget.dayPrizesObj.getThirdPrizeObj6D()!);
      }

    }else{
      prizeObjList.add(widget.dayPrizesObj.getFirstPrizeObj());
      prizeObjList.add(widget.dayPrizesObj.getSecondPrizeObj());
      prizeObjList.add(widget.dayPrizesObj.getThirdPrizeObj());
    }

    return prizeObjList.map((prizeObj) {
      return Flexible(
        child: SizedBox(
          width: getPrizeTextWidth(),
          child: Padding(
            padding: EdgeInsets.only(right: widget.prizePadding),
            child: PrizeCard(
              mainPageState: widget.mainPageState,
              prizeObj: prizeObj,
              fontSize: widget.fontSize,
              fontColor: widget.fontColor,
              showRelevant: widget.showRelevant,
              relevant_stream: widget.relevant_stream,
              onSelectionChanged_stream: widget.onSelectionChanged_stream,
              selectionBox_stream: widget.selectionBox_stream,
              filter_stream: widget.filter_stream,
              generalGesture_stream: widget.generalGesture_stream,
              presetPrizeHovered: widget.presetPrizeHovered,
            ),
          ),
        ),
      );
    },).toList();
  }

  double getThisWidth(){
      return getDateTextWidth() + getSeperatorTextWidth() + getPrizeTextWidth() * 3;
  }

  double getDateTextWidth(){
      return MyUtil.getWidthWithFontSize(widget.fontSize) * 10;
  }

  double getSeperatorTextWidth(){
      return MyUtil.getWidthWithFontSize(widget.fontSize) * 3;
  }

  double getPrizeTextWidth(){
      return widget.prizePadding + widget.fontSize * 4;
  }

  bool isInsideRectangle(Rect rect){
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);

      double left = position.dx;
      double top = position.dy;
      double right = renderBox.size.width + left;
      double bottom = renderBox.size.height + top;


        List<Offset> renderCornerPointOffsets = [
          Offset(left, top),
          Offset(right, top),
          Offset(left, bottom),
          Offset(right, bottom),
        ];
        

        for(Offset cornerPoint in renderCornerPointOffsets){
            if(rect.contains(cornerPoint)){
              return true;
            }
        }

      return false;
  }
}