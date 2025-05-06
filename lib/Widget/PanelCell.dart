import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toto/Object/DayPrizesObj.dart';
import 'package:toto/Widget/FreePanel.dart';

import '../DayCard.dart';
import '../Object/RelevantDetail.dart';
import '../Util/Pair.dart';
import '../main.dart';

class PanelCell extends StatefulWidget{

  int index;
  double cellWidth;
  double cellHeight;
  double fontSize;
  DayPrizesObj? dayPrizesObj;
  bool selected = false;

  MainPageState mainPageState;
  FreePanelState freePanelState;
  Stream<RelevantDetail?> relevant_stream;
  Stream<List<Pair<String, Color>>> filter_stream;
  Stream<List<DayPrizesObj>> onSelectionChanged_stream;
  Stream<Pair<GeneralGestureType, Map<String, dynamic>>> generalGesture_stream;

  PanelCell(
    {
      super.key,
      required this.index,
      required this.cellWidth,
      required this.cellHeight,
      required this.fontSize,
      required this.dayPrizesObj,
      required this.selected,

      required this.mainPageState,
      required this.freePanelState,
      required this.relevant_stream,
      required this.filter_stream,
      required this.onSelectionChanged_stream,
      required this.generalGesture_stream,
    }
  );

  @override
  State<StatefulWidget> createState() {
      return PanelCellState();
  }

}

class PanelCellState extends State<PanelCell>{

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
      return GestureDetector(
        onTap: () {
          widget.freePanelState.fn.requestFocus();
          widget.freePanelState.setSelectedIndex(widget.dayPrizesObj);
        },
        child: Container(
          width: widget.cellWidth,
          height: widget.cellHeight,
          decoration: widget.selected ? BoxDecoration(
            border: Border.all(
              color: Colors.yellow,
              width: 2
            )
          ) : null,
          child: widget.dayPrizesObj == null ? const SizedBox.shrink() : IntrinsicHeight(
            child: Row(
              children: [
                IconButton(
                    onPressed: () async {
                      await widget.freePanelState.removeFrom(widget.index);
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                    )
                ),
                DayCard(
                    mainPageState: widget.mainPageState,
                    index: widget.index,
                    fontSize: widget.fontSize,
                    dayPrizesObj: widget.dayPrizesObj!,
                    showRelevant: true,
                    show6D: false,
                    relevant_stream: widget.relevant_stream,
                    onSelectionChanged_stream: widget.onSelectionChanged_stream,
                    selectionBox_stream: null,
                    filter_stream: widget.filter_stream,
                    generalGesture_stream: widget.generalGesture_stream
                ),
              ],
            ),
          ),
        ),
      );
  }



}