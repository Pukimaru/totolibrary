import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:toto/Object/DayPrizesObj.dart';
import 'package:toto/Object/PrizeObj.dart';

import 'Object/RelevantDetail.dart';
import 'OuterBox.dart';
import 'SelectionBox.dart';
import 'Util/MyUtil.dart';
import 'Util/Pair.dart';
import 'Window.dart';
import 'main.dart';

class PrizeCard extends StatefulWidget{

  MainPageState mainPageState;
  PrizeObj prizeObj;
  double fontSize;
  Color? fontColor;
  bool showRelevant;

  Stream<RelevantDetail?> relevant_stream;
  Stream<List<Pair<String, Color>>> filter_stream;
  Stream<List<DayPrizesObj>> onSelectionChanged_stream;
  Stream<Pair<SelectionStage, Rect?>>? selectionBox_stream;
  Stream<Pair<GeneralGestureType, Map<String, dynamic>>> generalGesture_stream;

  String? presetPrizeHovered;

  PrizeCard(
    {
      super.key,
      required this.mainPageState,
      required this.fontSize,
      this.fontColor,
      required this.prizeObj,
      required this.showRelevant,
      required this.relevant_stream,
      required this.filter_stream,
      required this.onSelectionChanged_stream,
      required this.selectionBox_stream,
      required this.generalGesture_stream,
      this.presetPrizeHovered
    }
  );

  @override
  State<StatefulWidget> createState() {
    return PrizeCardState();
  }

}

class PrizeCardState extends State<PrizeCard>{

  List<Pair<String, Color>> sortedFilterStringColorPairList = [];
  String? prizeHovered = "";

  StreamSubscription<List<Pair<String, Color>>>? filter_StreamSubscription;
  StreamSubscription<RelevantDetail?>? relevant_StreamSubscription;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    filter_StreamSubscription = widget.filter_stream.listen((event) {
      setState(() {
          sortedFilterStringColorPairList = event;
      });
    });
    relevant_StreamSubscription = widget.relevant_stream.listen((detail) {
      setState(() {
        if(detail != null){
          prizeHovered = detail.prizeHovered;
        }else{
          prizeHovered = null;
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if(mounted){
        setState(() {
          sortedFilterStringColorPairList = widget.mainPageState.getFilterStringColorPairList();
        });
      }
    },);

    if(widget.presetPrizeHovered != null){
      prizeHovered = widget.presetPrizeHovered;
    }

  }

  @override
  void dispose() {
    filter_StreamSubscription?.cancel();
    relevant_StreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MyUtil.getWidthWithFontSize(widget.fontSize) * (widget.prizeObj.digit5.isEmpty ? 4 : 6),
      height: MyUtil.getHeightWithFontSize(widget.fontSize),
      child: MouseRegion(
        cursor: widget.showRelevant ? SystemMouseCursors.none : SystemMouseCursors.basic,
        onEnter: widget.showRelevant ? onEnter : null,
        onExit: widget.showRelevant ? onExit : null,
        child: Row(
          children: [
            Flexible(
                child: Container(
                  color: widget.prizeObj.getColorForPosition(prizeHovered, sortedFilterStringColorPairList, 1),
                  child: Text(
                    widget.prizeObj.digit1,
                    style: TextStyle(
                        fontSize: widget.fontSize,
                        color: widget.fontColor
                    ),
                  ),
                )
            ),
            Flexible(
                child: Container(
                  color: widget.prizeObj.getColorForPosition(prizeHovered, sortedFilterStringColorPairList, 2),
                  child: Text(
                    widget.prizeObj.digit2,
                    style: TextStyle(
                        fontSize: widget.fontSize,
                        color: widget.fontColor
                    ),
                  ),
                )
            ),
            Flexible(
                child: Container(
                  color: widget.prizeObj.getColorForPosition(prizeHovered, sortedFilterStringColorPairList, 3),
                  child: Text(
                    widget.prizeObj.digit3,
                    style: TextStyle(
                        fontSize: widget.fontSize,
                        color: widget.fontColor
                    ),
                  ),
                )
            ),
            Flexible(
                child: Container(
                  color: widget.prizeObj.getColorForPosition(prizeHovered, sortedFilterStringColorPairList, 4),
                  child: Text(
                    widget.prizeObj.digit4,
                    style: TextStyle(
                        fontSize: widget.fontSize,
                        color: widget.fontColor
                    ),
                  ),
                )
            ),
            ...[
              widget.prizeObj.digit5.isNotEmpty ? Flexible(
                  child: Container(
                    color: widget.prizeObj.getColorForPosition(prizeHovered, sortedFilterStringColorPairList, 5),
                    child: Text(
                      widget.prizeObj.digit5,
                      style: TextStyle(
                          fontSize: widget.fontSize,
                          color: widget.fontColor
                      ),
                    ),
                  )
              ) : SizedBox.shrink(),
              widget.prizeObj.digit6.isNotEmpty ? Flexible(
                  child: Container(
                    color: widget.prizeObj.getColorForPosition(prizeHovered, sortedFilterStringColorPairList, 6),
                    child: Text(
                      widget.prizeObj.digit6,
                      style: TextStyle(
                          fontSize: widget.fontSize,
                          color: widget.fontColor
                      ),
                    ),
                  )
              ) : SizedBox.shrink(),
            ]
          ],
        ),
      ),
    );
  }

  void onEnter(PointerEnterEvent? pointerEnterEvent){

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset globalPositionOfThisWidget = renderBox.localToGlobal(Offset.zero);

    widget.mainPageState.updateRelevantDetail(
      prizeHovered: widget.prizeObj.getFullString(),
      dayPrizesObjHovered: widget.prizeObj.dayPrizesObj,
      hoverPosition: globalPositionOfThisWidget
    );
      //widget.outerBoxState.enter(widget.prizeObj.getFullString());
  }

  void onExit(PointerExitEvent? pointerEnterEvent){
    widget.mainPageState.updateRelevantDetail(
        prizeHovered: null,
        dayPrizesObjHovered: null,
        hoverPosition: null
    );
    //widget.outerBoxState.exit();
  }

}