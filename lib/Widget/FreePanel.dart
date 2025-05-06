import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toto/DataManager.dart';
import 'package:toto/DayCard.dart';
import 'package:toto/Object/DayPrizesObj.dart';
import 'package:toto/PanelManager.dart';
import 'package:toto/Widget/GraphChartContainer.dart';

import '../Object/ChartDataObject.dart';
import '../Object/RelevantDetail.dart';
import '../OuterBox.dart';
import '../Scrapper.dart';
import '../SelectionBox.dart';
import '../Dialog/SettingDial.dart';
import '../Util/MyConst.dart';
import '../Util/Pair.dart';
import '../main.dart';
import 'TableChartContainer.dart';
import 'PanelCell.dart';

class FreePanel extends StatefulWidget{

  MainPageState mainPageState;
  PanelManagerState panelManagerState;
  Stream<RelevantDetail?> relevant_stream;
  Stream<List<Pair<String, Color>>> filter_stream;
  Stream<List<DayPrizesObj>> onSelectionChanged_stream;
  Stream<Pair<GeneralGestureType, Map<String, dynamic>>> generalGesture_stream;

  String panelName;
  double fontSize = 15;
  int column = 3;

  double panelWidth = 300;
  double panelHeight = 500;
  double panelPositionTop = 10;
  double panelPositionLeft = 10;

  List<String> cellListString = [];
  double scrollOffset;
  bool isMinimize;
  
  String? tableChartContainerJsonString;
  String? graphChartContainerJsonString;

  FreePanel(
    {
      super.key,
      required this.mainPageState,
      required this.panelManagerState,
      required this.relevant_stream,
      required this.filter_stream,
      required this.onSelectionChanged_stream,
      required this.generalGesture_stream,
      required this.panelName,
      required this.fontSize,
      required this.column,
      required this.panelWidth,
      required this.panelHeight,
      required this.panelPositionTop,
      required this.panelPositionLeft,
      required this.cellListString,
      required this.scrollOffset,
      required this.isMinimize,
      required this.tableChartContainerJsonString,
      required this.graphChartContainerJsonString,
    }
  );


  @override
  State<StatefulWidget> createState() {
    return FreePanelState();
  }

}

class FreePanelState extends State<FreePanel>{

  final double barHeight = 20;
  final double resizeWidthHeight = 10;
  final double minPanelWidth = 150;
  final double minPanelHeight = 100;
  final double fieldLeftBorder = 0;
  final double fieldUpperBorder = 7;
  final double labelFontSize = 16;

  final Color barColor = Colors.black54;
  final Color defaultColor = const Color.fromRGBO(225, 217, 209, 1);
  final Color onEnterColor = Colors.white;
  late Color contentColor;


  double fontSize = 15;
  int column = 3;

  double panelWidth = 300;
  double panelHeight = 500;
  double panelPositionTop = 10;
  double panelPositionLeft = 10;

  double panOffSetX = 0;
  double panOffSetY = 0;
  bool isMinimize = true;

  DayPrizesObj? selectedObj;
  List<DayPrizesObj?> cellList = [];

  double scrollOffset = 0;
  ScrollController scrollController = ScrollController();
  FocusNode fn = FocusNode();

  bool isEditingName = false;
  TextEditingController editNameTEC = TextEditingController();
  FocusNode editNameFN = FocusNode();

  bool isMoving = false;

  GlobalKey<TableChartContainerState> tableChartContainerKey = GlobalKey();

  PanelType? panelType;
  Map<String, dynamic> tableChartJson = {};
  Map<String, dynamic> graphChartJson = {};

  @override
  void initState() {
    super.initState();

    setState(() {
      fontSize = widget.fontSize;
      column = widget.column;

      panelWidth = widget.panelWidth;
      panelHeight = widget.panelHeight;
      panelPositionTop = widget.panelPositionTop;
      panelPositionLeft = widget.panelPositionLeft;

      isMinimize = widget.isMinimize;

      cellList = widget.cellListString.map<DayPrizesObj?>((cellString){
        if(cellString == "null"){
          return null;
        }else{
          return DayPrizesObj.getDayPrizesObjWithUniqueKey(cellString);
        }
      }).toList();
      if(widget.tableChartContainerJsonString != null){
        tableChartJson = jsonDecode(widget.tableChartContainerJsonString!);
      }
      if(widget.graphChartContainerJsonString != null){
        graphChartJson = jsonDecode(widget.graphChartContainerJsonString!);
      }

      scrollOffset = widget.scrollOffset;
      contentColor = defaultColor;
    });

    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        scrollController.addListener(() {
          scrollOffset = scrollController.offset;
        });

        try{
          scrollController.jumpTo(scrollOffset);

        }catch(e,ex){
          print("Fail to jump to scrollOffset, $ex");
        }
      },
    );

  }

  @override
  void dispose() {
    scrollController.dispose();
    fn.dispose();
    editNameTEC.dispose();
    editNameFN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      return Positioned(
          left: panelPositionLeft,
          top: panelPositionTop,
          width: panelWidth,
          height: panelHeight,
          child: isMinimize ? const SizedBox() : GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) {
              widget.panelManagerState.bringUpPanel(widget.panelName);
            },
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: () {
                    setState(() {
                      maximize();
                    });
                  },
                  onPanStart: (details) {

                    widget.mainPageState.setShowRelevant(false);

                    panOffSetX = panelPositionLeft-details.globalPosition.dx;
                    panOffSetY = panelPositionTop-details.globalPosition.dy;
                  },
                  onPanUpdate: (details) {
                    setState(() {

                      isMoving = true;

                      double newPositionX = min(details.globalPosition.dx+panOffSetX, MediaQuery.of(context).size.width - panelWidth);
                      double newPositionY = min(details.globalPosition.dy+panOffSetY, MediaQuery.of(context).size.height - panelHeight);

                      if(newPositionY < fieldUpperBorder){
                          newPositionY = panelPositionTop;
                      }

                      if(newPositionX < fieldLeftBorder){
                        newPositionX = panelPositionLeft;
                      }

                      panelPositionLeft = newPositionX;
                      panelPositionTop = newPositionY;
                    });
                  },
                  onPanEnd: (details) async {
                    setState(() {
                      isMoving = false;
                    });
                    widget.mainPageState.setShowRelevant(true);
                    await saveToPref();
                  },
                  child: Container(
                    width: panelWidth,
                    height: barHeight,
                    color: barColor,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            width: 100,
                            height: barHeight,
                            child: isEditingName ? TextField(
                              controller: editNameTEC,
                              focusNode: editNameFN,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: labelFontSize-2,
                                color: Colors.cyanAccent
                              ),
                              decoration: InputDecoration(
                                isDense: true, // Reduces vertical space
                              ),
                              onTap: () {
                                editNameFN.requestFocus();
                              },
                              autofocus: true,
                              onEditingComplete: () async {
                                bool success = await widget.panelManagerState.renamePanel(widget.panelName, editNameTEC.text);

                                if(!success){
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text("Invalid Panel Name!"),
                                  ));
                                }

                                setState(() {
                                  isEditingName = false;
                                });
                              },
                              onTapOutside: (event) async {
                                bool success = await widget.panelManagerState.renamePanel(widget.panelName, editNameTEC.text);

                                if(!success){
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text("Invalid Panel Name!"),
                                  ));
                                }

                                setState(() {
                                  isEditingName = false;
                                });
                              },
                            ) : GestureDetector(
                              onDoubleTap: () {
                                setState(() {
                                  isEditingName = true;
                                  editNameTEC.text = widget.panelName;
                                });
                              },
                              child: Text(
                                widget.panelName,
                                style: TextStyle(
                                  fontSize: labelFontSize - 2,
                                  color: Colors.white
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                        ),
                        const Expanded(child: SizedBox.shrink()),
                        panelType == PanelType.Normal ? IconButton(
                            onPressed: () async {
                              await openSettingDial();
                            },
                            icon: Icon(
                              Icons.settings,
                              size: barHeight/2,
                              color: Colors.white,
                            )
                        ) : SizedBox.shrink(),
                        IconButton(
                            onPressed: () {
                              minimize();
                            },
                            icon: Icon(
                              CupertinoIcons.minus,
                              size: barHeight/2,
                              color: Colors.white,
                            )
                        ),
                        IconButton(
                            onPressed: () {
                              maximize();
                            },
                            icon: Icon(
                              Icons.square_outlined,
                              size: barHeight/2,
                              color: Colors.white,
                            )
                        ),
                        IconButton(
                            onPressed: () {
                              close();
                            },
                            icon: Icon(
                              Icons.close,
                              size: barHeight/2,
                              color: Colors.white,
                            )
                        ),
                      ],
                    ),
                  ),
                ),
                IntrinsicWidth(
                  child: Row(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeLeft,
                        child: GestureDetector(
                          onPanStart: (details) {
                            widget.mainPageState.setShowRelevant(false);
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              isMoving = true;

                              double toIncreaseWidth = panelPositionLeft - details.globalPosition.dx;

                              double newPanelWidth = panelWidth + toIncreaseWidth;

                              if(newPanelWidth < minPanelHeight){
                                  return;
                              }

                              panelPositionLeft = details.globalPosition.dx;
                              panelWidth = newPanelWidth;

                            });
                          },
                          onPanEnd: (details) async {
                            widget.mainPageState.setShowRelevant(true);
                            setState(() {
                              isMoving = false;
                            });
                            await saveToPref();
                          },
                          child: Container(
                            width: resizeWidthHeight,
                            height: getContentHeight(),
                            color: contentColor,
                          ),
                        ),
                      ),
                      getContentWidget(),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeRight,
                        child: GestureDetector(
                          onPanStart: (details) {
                            widget.mainPageState.setShowRelevant(false);
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              isMoving = true;

                              double toIncreaseWidth = details.globalPosition.dx - (panelPositionLeft + panelWidth);

                              double newPanelWidth = panelWidth + toIncreaseWidth;

                              if(newPanelWidth < minPanelHeight || newPanelWidth + panelPositionLeft > MediaQuery.of(context).size.width){
                                return;
                              }

                              panelWidth = newPanelWidth;

                            });
                          },
                          onPanEnd: (details) async {
                            widget.mainPageState.setShowRelevant(true);
                            setState(() {
                              isMoving = false;
                            });
                            await saveToPref();
                          },
                          child: Container(
                            width: resizeWidthHeight,
                            height: getContentHeight(),
                            color: contentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeDownLeft,
                      child: GestureDetector(
                        onPanStart: (details) {
                          widget.mainPageState.setShowRelevant(false);
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            isMoving = true;

                            double toInreaseWidth = panelPositionLeft - details.globalPosition.dx;
                            double toIncreaseHeight = details.globalPosition.dy - (panelPositionTop+panelHeight);

                            double newPanelWidth = panelWidth + toInreaseWidth;
                            double newPanelHeight = panelHeight + toIncreaseHeight;


                            if( !(newPanelWidth < minPanelWidth || details.globalPosition.dx < 0)){
                              panelPositionLeft = details.globalPosition.dx;
                              panelWidth = newPanelWidth;
                            }

                            if(!(newPanelHeight < minPanelHeight || newPanelHeight + panelPositionTop > MediaQuery.of(context).size.height)){
                              panelHeight = newPanelHeight;
                            }

                          });
                        },
                        onPanEnd: (details) async {
                          widget.mainPageState.setShowRelevant(true);
                          setState(() {
                            isMoving = false;
                          });
                          await saveToPref();
                        },
                        child: Container(
                          color: contentColor,
                          height: resizeWidthHeight,
                          width: resizeWidthHeight,
                        ),
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeDown,
                      child: GestureDetector(
                        onPanStart: (details) {
                          widget.mainPageState.setShowRelevant(false);
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            isMoving = true;

                            double toIncreaseHeight = details.globalPosition.dy - (panelPositionTop+panelHeight);

                            double newPanelHeight = panelHeight + toIncreaseHeight;

                            if(newPanelHeight < minPanelHeight || newPanelHeight + panelPositionTop > MediaQuery.of(context).size.height){
                              return;
                            }

                            panelHeight = newPanelHeight;

                          });
                        },
                        onPanEnd: (details) async {
                          widget.mainPageState.setShowRelevant(true);
                          setState(() {
                            isMoving = false;
                          });
                          await saveToPref();
                        },
                        child: Container(
                          color: contentColor,
                          height: resizeWidthHeight,
                          width: getContentWidth(),
                        ),
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeDownRight,
                      child: GestureDetector(
                        onPanStart: (details) {
                          widget.mainPageState.setShowRelevant(false);
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            isMoving = true;

                            double toInreaseWidth = details.globalPosition.dx - (panelPositionLeft+panelWidth);
                            double toIncreaseHeight = details.globalPosition.dy - (panelPositionTop+panelHeight);

                            double newPanelWidth = panelWidth + toInreaseWidth;
                            double newPanelHeight = panelHeight + toIncreaseHeight;


                            if(!(newPanelWidth < minPanelWidth || newPanelWidth + panelPositionLeft > MediaQuery.of(context).size.width)){
                              panelWidth = newPanelWidth;
                            }

                            if(!(newPanelHeight < minPanelHeight || newPanelHeight + panelPositionTop > MediaQuery.of(context).size.height)){
                              panelHeight = newPanelHeight;
                            }
                          });
                        },
                        onPanEnd: (details) async {
                          widget.mainPageState.setShowRelevant(true);
                          setState(() {
                            isMoving = false;
                          });
                          await saveToPref();
                        },
                        child: Container(
                          color: contentColor,
                          height: resizeWidthHeight,
                          width: resizeWidthHeight,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
      );
  }

  void setSelectedIndex(DayPrizesObj? dayPrizesObj){
      setState(() {
        if(selectedObj != dayPrizesObj){
          selectedObj = dayPrizesObj;
        }else{
          selectedObj = null;
        }

      });
  }

  Future<void> addToList(List<DayPrizesObj> toAddDayPrizesObjList) async {

      setState(() {
        int newRowCellIndex= getNewRowCellIndex();

        for(int i = 0; i < toAddDayPrizesObjList.length; i++){

          DayPrizesObj toAddDayPrizesObj = toAddDayPrizesObjList[i];

          if(!(DayPrizesObj.hasDuplicateUniqueKey(cellList, toAddDayPrizesObj))){

            int cellIndex = newRowCellIndex+i;

            if(cellIndex >= cellList.length){
              cellList.add(toAddDayPrizesObj);
            }else{
              cellList[newRowCellIndex+i] = toAddDayPrizesObj;
            }

            addOrRemoveCellOnLastRow();
          }

        }
      });

      addOrRemoveCellOnLastRow();

      await saveToPref();
  }

  Future<void> removeFrom(int toRemoveIndex) async {
      setState(() {
        cellList[toRemoveIndex] = null;
      });
      addOrRemoveCellOnLastRow();

      await saveToPref();
  }

  Future<bool> moveTo(int indexFrom, int indexTo, KeyboardKeys key) async {

     switch(key){
        case KeyboardKeys.UP:

          if(indexTo < 0){
            return false;
          }

          DayPrizesObj? cache = cellList[indexTo];
          cellList[indexTo] = cellList[indexFrom];
          cellList[indexFrom] = cache;

          break;

        case KeyboardKeys.DOWN:

          if(indexTo >= cellList.length){
            return false;
          }

          DayPrizesObj? cache = cellList[indexTo];

          cellList[indexTo] = cellList[indexFrom];
          cellList[indexFrom] = cache;
          break;

        case KeyboardKeys.LEFT:
          if(indexTo % column == column-1){
            return false;
          }

          DayPrizesObj? prev;
          DayPrizesObj? cache = cellList[indexFrom];

          for(int i = indexTo; i < cellList.length; i += column){

            if(cellList[i] == null){
              cellList[i] = cache;
              break;
            }

            prev = cellList[i];
            cellList[i] = cache;
            cache = prev;
          }

          cellList[indexFrom] = null;
          break;

        case KeyboardKeys.RIGHT:
          if(indexTo % column == 0){
            return false;
          }

          DayPrizesObj? prev;
          DayPrizesObj? cache = cellList[indexFrom];

          for(int i = indexTo; i < cellList.length; i += column){

            if(cellList[i] == null){
              cellList[i] = cache;
              break;
            }

            prev = cellList[i];
            cellList[i] = cache;
            cache = prev;
          }

          cellList[indexFrom] = null;
          break;
      }

      setState(() {
        addOrRemoveCellOnLastRow();
      });

     await saveToPref();

      return true;
  }

  void snapCells(){

    setState(() {
      for(int i = 0; i < cellList.length; i++){
        if(cellList[i] == null){
          int snapFromIndex = -1;

          for(int j = i; j < cellList.length;j+=column){
            if(cellList[j] != null){
              snapFromIndex = j;
            }
          }

          if(snapFromIndex != -1){
            cellList[i] = cellList[snapFromIndex];
            cellList[snapFromIndex] = null;
          }
        }
      }
    });
  }

  void addOrRemoveCellOnLastRow(){

      int newRowCellIndex = getNewRowCellIndex();
      int lastCellIndex = newRowCellIndex + (column-1);

      if(newRowCellIndex == 0){
          cellList.clear();
          return;
      }


      if(lastCellIndex >= cellList.length){
          for(int i = cellList.length-1; i <= lastCellIndex; i++){
            cellList.add(null);
          }
      }

      for(int i = 0; i < cellList.length; i++){
        if(i > lastCellIndex){
          cellList.removeAt(i);
        }
      }
  }

  int getNewRowCellIndex(){

      int lastOccupiedCellIndex = getLastOccupiedCellIndex();

      if(lastOccupiedCellIndex != -1){
        return lastOccupiedCellIndex + (column - (lastOccupiedCellIndex % column));
      }else{
        return 0;
      }
  }

  int getLastOccupiedCellIndex(){

    for(int i = cellList.length-1; i >= 0; i--){
        if(cellList[i] != null){
          return i;
        }
    }

    return -1;
  }

  double getContentWidth(){
    return panelWidth - resizeWidthHeight*2;
  }

  double getContentHeight(){
    return panelHeight - barHeight - resizeWidthHeight;
  }

  Widget getContentWidget(){

    if(tableChartJson.isNotEmpty){
      panelType = PanelType.Table;
    }else if(graphChartJson.isNotEmpty){
      panelType = PanelType.Graph;
    }else if(cellList.isNotEmpty){
      panelType = PanelType.Normal;
    }

    switch(panelType){
      case PanelType.Table:
        return getTableChartContainer();

      case PanelType.Graph:
        return getGraphChartContainer();

      case PanelType.Normal:
        return getNormalContainer();

      default:
        return Container(
          height: getContentHeight(),
          width: getContentWidth(),
          color: contentColor,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      panelType = PanelType.Normal;
                    });
                  },
                  icon: Icon(
                      Icons.book
                  ),
                  iconSize: min(getContentWidth()/4, getContentHeight()/4),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      panelType = PanelType.Table;
                    });
                  },
                  icon: Icon(
                      Icons.table_rows_outlined
                  ),
                  iconSize: min(getContentWidth()/4, getContentHeight()/4),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      panelType = PanelType.Graph;
                    });
                  },
                  icon: Icon(
                      Icons.auto_graph_sharp
                  ),
                  iconSize: min(getContentWidth()/4, getContentHeight()/4),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget getTableChartContainer(){

      if(isMoving){
        return Container(
          width: getContentWidth(),
          height: getContentHeight(),
        );
      }

      return TableChartContainer(
          key: tableChartContainerKey,
          freePanelState: this,
          panelName: widget.panelName,
          width: getContentWidth(),
          height: getContentHeight(),
          year: tableChartJson["year"] ?? null, yearMin: tableChartJson["yearMin"] ?? null, yearMax: tableChartJson["yearMax"] ?? null,
          month: tableChartJson["month"] ?? null, monthMin: tableChartJson["monthMin"] ?? null, monthMax: tableChartJson["monthMax"] ?? null,
          day: tableChartJson["day"] ?? null, dayMin: tableChartJson["dayMin"] ?? null, dayMax: tableChartJson["dayMax"] ?? null,
          magnumActive: tableChartJson["magnumActive"] ?? true,
          totoActive: tableChartJson["totoActive"] ?? true,
          damacaiActive: tableChartJson["damacaiActive"] ?? true,
          drawDayType: tableChartJson["drawDayType"] == null ? DrawDayType.AllDraw : DrawDayType.values.firstWhere((element) => element.name.toString() == tableChartJson["drawDayType"]),
          chartDataObjectList: tableChartJson["chartDataObjectListString"] == null ? [] : List<String>.from(tableChartJson["chartDataObjectListString"]).map<ChartDataObject>((e) => ChartDataObject.fromJson(e)).toList(),
          prizePatternType: tableChartJson["prizePatternType"] == null ? PrizePatternType.Pattern_XYZ : PrizePatternType.values.firstWhere((element) => element.name.toString() == tableChartJson["prizePatternType"]),
          sortType: tableChartJson["sortType"] == null ? SortType.Pattern : SortType.values.firstWhere((element) => element.name.toString() == tableChartJson["sortType"]),
          scrollOffset: tableChartJson["scrollOffset"] == null ? 0 : tableChartJson["scrollOffset"],
          selectedDataObjectLabel:  tableChartJson["selectedDataObjectLabel"] ?? null,
      );
  }

  Widget getGraphChartContainer(){

    if(isMoving){
      return SizedBox.shrink();
    }

    return GraphChartContainer(
      freePanelState: this,
      width: getContentWidth(),
      height: getContentHeight(),
      panelName : widget.panelName,
      year: graphChartJson["year"] ?? null,
      yearMin: graphChartJson["yearMin"] ?? null,
      yearMax: graphChartJson["yearMax"] ?? null,
      chartDataObjectStorage: graphChartJson["chartDataObjectStorage"] == null ? [] : List<String>.from(graphChartJson["chartDataObjectStorage"]).map<ChartDataObject>((e) => ChartDataObject.fromJson(e)).toList(),
      chartDataObjectList: graphChartJson["chartDataObjectListString"] == null ? [] : List<String>.from(graphChartJson["chartDataObjectListString"]).map<ChartDataObject>((e) => ChartDataObject.fromJson(e)).toList(),
      graphOrdinate : graphChartJson["graphOrdinate"] == null ? GraphOrdinate.Cumulative : GraphOrdinate.values.firstWhere((element) => element.name.toString() == graphChartJson["graphOrdinate"]),
      crossHair: graphChartJson["crossHair"] ?? true,
      pointSize: graphChartJson["pointSize"] ?? 8,
    );
  }

  Widget getNormalContainer(){
    return Container(
      height: getContentHeight(),
      width: getContentWidth(),
      color: contentColor,
      child: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.arrowUp) : UpKeyIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowDown) : DownKeyIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowLeft) : LeftKeyIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowRight) : RightKeyIntent(),
        },
        child: Actions(
          actions: {
            UpKeyIntent : CallbackAction(
              onInvoke: (intent) async {
                int selectedIndex = cellList.indexOf(selectedObj);
                if(selectedIndex != -1){
                  await moveTo(selectedIndex, selectedIndex-column, KeyboardKeys.UP);
                }
                return null;
              },
            ),
            DownKeyIntent : CallbackAction(
              onInvoke: (intent) async {
                int selectedIndex = cellList.indexOf(selectedObj);
                if(selectedIndex != -1){
                  await moveTo(selectedIndex, selectedIndex+column, KeyboardKeys.DOWN);
                }
                return null;
              },
            ),
            LeftKeyIntent : CallbackAction(
              onInvoke: (intent) async {
                int selectedIndex = cellList.indexOf(selectedObj);
                if(selectedIndex != -1){
                  await moveTo(selectedIndex, selectedIndex-1, KeyboardKeys.LEFT);
                }
                return null;
              },
            ),
            RightKeyIntent : CallbackAction(
              onInvoke: (intent) async {
                int selectedIndex = cellList.indexOf(selectedObj);
                if(selectedIndex != -1){
                  await moveTo(selectedIndex, selectedIndex+1, KeyboardKeys.RIGHT);
                }
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            focusNode: fn,
            child: DragTarget<List<DayPrizesObj>>(
              hitTestBehavior: HitTestBehavior.translucent,
              builder: (context, candidateData, rejectedData) {
                return AlignedGridView.count(
                  controller: scrollController,
                  crossAxisCount: column,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                  itemCount: cellList.length,
                  itemBuilder: (context, index) {
                    return PanelCell(
                        index: index,
                        cellWidth: (getContentWidth()-column*3)/column,
                        cellHeight: 50,
                        fontSize: fontSize,
                        dayPrizesObj: cellList[index],
                        selected: selectedObj != null && cellList[index] == selectedObj,
                        mainPageState: widget.mainPageState,
                        freePanelState: this,
                        relevant_stream: widget.relevant_stream,
                        filter_stream: widget.filter_stream,
                        onSelectionChanged_stream: widget.onSelectionChanged_stream,
                        generalGesture_stream: widget.generalGesture_stream
                    );
                  },
                );
              },
              onMove: (details) {
                setState(() {
                  contentColor = onEnterColor;
                });
              },
              onLeave: (data) {
                setState(() {
                  contentColor = defaultColor;
                });
              },
              onAccept: (data) async {
                await addToList(data);
                setState(() {
                  contentColor = defaultColor;
                });
              },
              onWillAccept: (data){
                return data != null;
              },
            ),
          ),
        ),
      ),
    );
  }

  double getMaxPanelWidth(){
    return MediaQuery.of(context).size.width;
  }

  double getMaxPanelHeight(){
    return MediaQuery.of(context).size.height - fieldUpperBorder;
  }

  void minimize(){

    if(isMinimize){
      setState(() {
        isMinimize = false;
      });
      saveToPref();
    }else{
      setState(() {
        isMinimize = true;
      });
      saveToPref();
      widget.panelManagerState.minimize(widget.panelName, keep: true);
    }
  }

  void maximize(){
    if(panelWidth != getMaxPanelWidth() || panelHeight != getMaxPanelHeight()){
      setState(() {
        panelPositionLeft = 0;
        panelPositionTop = 0;

        panelWidth = getMaxPanelWidth();
        panelHeight = getMaxPanelHeight();
      });
    }else{
      setState(() {
        panelWidth = (getMaxPanelWidth()+minPanelWidth)/2;
        panelHeight = (getMaxPanelHeight()+minPanelHeight)/2;
      });
    }
  }

  void close(){
    widget.panelManagerState.closePanel(widget.panelName);
  }

  Future<void> openSettingDial() async{
    final _settingDialKey = GlobalKey<SettingDialState>();

    AlertDialog dialog = AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      content: SettingDial(
        key: _settingDialKey,
        windowState: null,
        freePanelState: this,
      ),
    );

    var result = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return dialog;
      },
    );

    if(result != null){
      setState(() {});
    }
  }

  void setTableChartJson(String jsonString){
    this.tableChartJson = jsonDecode(jsonString);
  }

  void setGraphChartJson(String jsonString){
    this.graphChartJson = jsonDecode(jsonString);
  }

  Future<void> saveToPref() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    String panelKey = "${MyConst.Key_PanelHeader}${widget.panelName}";

    await sp.setString(panelKey, getEncodedJson());

    List<String> panelKeyList = sp.getStringList(MyConst.Key_PanelKeyList) ?? [];

    if(!panelKeyList.contains(panelKey)){
      panelKeyList.add(panelKey);
      await sp.setStringList(MyConst.Key_PanelKeyList, panelKeyList);
    }
  }

  String getEncodedJson(){

    Map<String, dynamic> json = {
      "panelName" : widget.panelName,
      "fontSize" : fontSize,
      "column" : column,
      "panelWidth" : panelWidth,
      "panelHeight" : panelHeight,
      "panelPositionTop" : panelPositionTop,
      "panelPositionLeft" : panelPositionLeft,
      "cellListString" : cellList.map<String>((e){
        if(e == null){
          return "null";
        }else{
          return e.getUniqueKey();
        }
      }).toList(),
      "scrollOffset" : scrollOffset,
      "isMinimize" : isMinimize,
      "tableChartContainerJsonString" : jsonEncode(tableChartJson),
      "graphChartContainerJsonString" : jsonEncode(graphChartJson),
    };

    return jsonEncode(json);
  }
}

enum PanelType{
  Normal, Table, Graph
}

class UpKeyIntent extends Intent{
  static const KeyboardKeys key = KeyboardKeys.UP;
  const UpKeyIntent();
}

class DownKeyIntent extends Intent{
  static const KeyboardKeys key = KeyboardKeys.DOWN;
  const DownKeyIntent();
}

class LeftKeyIntent extends Intent{
  static const KeyboardKeys key = KeyboardKeys.LEFT;
  const LeftKeyIntent();
}

class RightKeyIntent extends Intent{
  static const KeyboardKeys key = KeyboardKeys.RIGHT;
  const RightKeyIntent();
}

enum KeyboardKeys{
  UP, DOWN, LEFT, RIGHT
}