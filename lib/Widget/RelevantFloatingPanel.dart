import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toto/DayCard.dart';

import '../Object/DayPrizesObj.dart';
import '../Object/RelevantDetail.dart';
import '../Util/Pair.dart';
import '../main.dart';

class RelevantFloatingPanel extends StatefulWidget{

  double fontSize;
  double width;
  double height;

  List<DayPrizesObj> dayPrizesObjList;

  MainPageState mainPageState;
  bool showRelevant;
  bool show6D;
  Stream<RelevantDetail?> relevant_stream;
  Stream<List<Pair<String, Color>>> filter_stream;
  Stream<List<DayPrizesObj>> onSelectionChanged_stream;
  Stream<Pair<GeneralGestureType, Map<String, dynamic>>> generalGesture_stream;


  RelevantFloatingPanel(
    {
      required this.fontSize,
      required this.width,
      required this.height,
      required this.dayPrizesObjList,
      required this.mainPageState,
      required this.showRelevant,
      required this.show6D,
      required this.relevant_stream,
      required this.filter_stream,
      required this.onSelectionChanged_stream,
      required this.generalGesture_stream,
    }
  );

  @override
  State<StatefulWidget> createState() {
    return RelevantFloatingPanelState();
  }

}

class RelevantFloatingPanelState extends State<RelevantFloatingPanel>{
  StreamSubscription<RelevantDetail?>? relevant_StreamSubscription;
  String? prizeHovered;
  DayPrizesObj? dayPrizesObjHovered;
  bool displayAtRight = true;

  @override
  void initState() {
    relevant_StreamSubscription = widget.relevant_stream.listen(
      (detail){
        if(mounted){
          setState(() {
            if(detail != null){
              prizeHovered = detail.prizeHovered;
              dayPrizesObjHovered = detail.dayPrizesObjHovered;
              displayAtRight = detail.hoverPosition.dx < widget.width/2;
            }else{
              prizeHovered=null;
            }
          });
        }
      }
    );
    super.initState();
  }

  @override
  void dispose() {
    relevant_StreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      return Positioned(
        right: displayAtRight ? 0 : null,
        left: displayAtRight ? null : 0,
        child: Material(
          color: Colors.black,
          elevation: 5,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: EdgeInsets.all(3),
            child: SingleChildScrollView(
              child: IntrinsicWidth(
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List<Widget>.from(
                        widget.dayPrizesObjList.where(
                              (dayPrizesObj) => dayPrizesObj.hasRelevantPrizeObj(prizeHovered) && dayPrizesObj != dayPrizesObjHovered,
                        ).map((_dayPrizesObj){
                            return Container(
                              color: Colors.white,
                              child: DayCard(
                                  mainPageState: widget.mainPageState,
                                  index: 0,
                                  fontSize: widget.fontSize,
                                  dayPrizesObj: _dayPrizesObj,
                                  showRelevant: widget.showRelevant,
                                  show6D: widget.show6D,
                                  relevant_stream: widget.relevant_stream,
                                  onSelectionChanged_stream: widget.onSelectionChanged_stream,
                                  selectionBox_stream: null,
                                  filter_stream: widget.filter_stream,
                                  generalGesture_stream: widget.generalGesture_stream,
                                  presetPrizeHovered: prizeHovered,
                              ),
                            );
                          },
                        ).toList()
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    ;
  }

}