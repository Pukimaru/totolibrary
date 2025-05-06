import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:toto/DayCard.dart';
import 'package:toto/SelectionBox.dart';
import 'package:toto/Widget/RelevantFloatingPanel.dart';
import 'package:toto/Window.dart';

import 'Object/DayPrizesObj.dart';
import 'Object/RelevantDetail.dart';
import 'Util/Pair.dart';
import 'main.dart';

class OuterBox extends StatefulWidget{

  MainPageState mainPageState;
  WindowState windowState;
  double width;
  double height;
  double fontSize;

  bool showRelevant;
  bool show6D;
  bool showRelevantFloatingPanel;

  int row;
  int column;
  Order order;

  double rowSpacing;
  double columnSpacing;
  double containerSpacing;
  double prizePadding;

  List<DayPrizesObj> dayPrizesObjList;
  List<String> filterStringFormulaList;

  Stream<RelevantDetail?> relevant_stream;
  Stream<List<Pair<String, Color>>> filter_stream;
  Stream<List<DayPrizesObj>> onSelectionChanged_stream;
  Stream<Pair<GeneralGestureType, Map<String, dynamic>>> generalGesture_stream;

  OuterBox(
      {
        super.key,
        required this.mainPageState,
        required this.windowState,
        required this.width,
        required this.height,
        required this.fontSize,
        required this.showRelevant,
        required this.show6D,
        required this.showRelevantFloatingPanel,
        required this.row,
        required this.column,
        required this.order,
        this.rowSpacing = 10,
        this.columnSpacing = 30,
        this.containerSpacing = 10,
        this.prizePadding = 5,
        required this.dayPrizesObjList,
        required this.filterStringFormulaList,
        required this.relevant_stream,
        required this.filter_stream,
        required this.onSelectionChanged_stream,
        required this.generalGesture_stream,
      }
  );

  @override
  State<StatefulWidget> createState() {
    return OuterBoxState();
  }

}

class OuterBoxState extends State<OuterBox>{

  late StreamController<Pair<SelectionStage, Rect?>> selectionBox_StreamController;

  @override
  void initState() {
    selectionBox_StreamController = StreamController.broadcast();
    super.initState();
  }

  @override
  void dispose() {
    selectionBox_StreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> containerList = getContainerList();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        widget.mainPageState.clearSelectionList();
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child:  Stack(
          children: [
            SelectionBox(
              mainPageState: widget.mainPageState,
              width: widget.width,
              height: widget.height,
              onSelectionChanged_stream: widget.onSelectionChanged_stream,
              selectionBox_StreamController: selectionBox_StreamController,
              child: ListView.builder(
                itemCount: containerList.length,
                itemBuilder: (context, index) {
                  return containerList[index];
                },
              ),
            ),
            widget.showRelevantFloatingPanel ? RelevantFloatingPanel(
                fontSize: widget.fontSize,
                width: widget.width,
                height: widget.height,
                dayPrizesObjList: widget.dayPrizesObjList,
                mainPageState: widget.mainPageState,
                showRelevant: widget.showRelevant,
                show6D: widget.show6D,
                relevant_stream: widget.relevant_stream,
                filter_stream: widget.filter_stream,
                onSelectionChanged_stream: widget.onSelectionChanged_stream,
                generalGesture_stream: widget.generalGesture_stream
            ) : SizedBox.shrink(),
          ],
        )
          /*child: Column(
            children: getContainerList(),
          )
        )*/
      ),
    );
  }
  /*SingleChildScrollView(
        child: Column(
          children: getContainerList(),
        ),*/

  List<Widget> getContainerList(){


    List<Widget> containerList = [];
    List<Widget> columnList = [];
    List<Widget> columnChildren = [];

    if(widget.order == Order.N){
        for(int i = 0; i < widget.dayPrizesObjList.length; i++){

            columnChildren.add(
                DayCard(
                    index: i,
                    mainPageState: widget.mainPageState,
                    dayPrizesObj: widget.dayPrizesObjList[i],
                    fontSize: widget.fontSize,
                    prizePadding: widget.prizePadding,
                    showRelevant: widget.showRelevant,
                    show6D: widget.show6D,
                    relevant_stream: widget.relevant_stream,
                    onSelectionChanged_stream: widget.onSelectionChanged_stream,
                    selectionBox_stream: selectionBox_StreamController.stream,
                    filter_stream: widget.filter_stream,
                    generalGesture_stream: widget.generalGesture_stream,
                )
            );

            if(columnChildren.length >= widget.row){
                columnList.add(
                    getColumn(List<Widget>.from(columnChildren))
                );
                columnChildren.clear();

                if(columnList.length >= widget.column){
                    containerList.add(
                      getContainer(List<Widget>.from(columnList))
                    );
                    containerList.add(SizedBox(height: widget.containerSpacing,));
                    columnList.clear();
                }
            }
        }
    }

    if(columnChildren.isNotEmpty){
        columnList.add(getColumn(List<Widget>.from(columnChildren)));
        columnChildren.clear();
    }

    if(columnList.length > widget.column){
        throw Exception();
    }else if(columnList.isNotEmpty){
        int unfillColumnCount = widget.column - columnList.length;

        for(int i = 0; i < unfillColumnCount; i++){
            columnList.add(getColumn(List<Widget>.from(columnChildren)));
        }

        containerList.add(
            getContainer(List<Widget>.from(columnList))
        );
    }

    return containerList;
  }

  Widget getContainer(List<Widget> columnList){
      return Padding(
        padding: const EdgeInsets.all(1),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: CupertinoColors.inactiveGray.withAlpha(70),
              width: 2,
            )
          ),
          child: getRow(columnList),
        ),
      );
  }

  Row getRow(List<Widget> columnList){

      List<Widget> children = [];

      for(Widget child in columnList){
          children.add(Expanded(child: child));

          children.add(
              SizedBox(
                width: widget.columnSpacing,
              )
          );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
  }

  Column getColumn(List<Widget> columnChildren){
      List<Widget> children = [];

      for(Widget child in columnChildren){
        children.add(child);

        children.add(
            SizedBox(
              height: widget.rowSpacing,
            )
          );
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
  }

  Widget getRelevantFloatingPanel(double width, double height){



    return Container(
      color: Colors.black.withAlpha(150),
      child: Column(
        children: [

        ],
      ),
    );
  }

}

enum Order{
  N, Z
}