import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toto/SelectionBox.dart';
import 'package:toto/Util/MyUtil.dart';

import 'DataManager.dart';
import 'ExcelManager.dart';
import 'Object/DayPrizesObj.dart';
import 'Object/PrizeObj.dart';
import 'Object/RelevantDetail.dart';
import 'OuterBox.dart';
import 'Dialog/SettingDial.dart';
import 'Util/MyConst.dart';
import 'Util/Pair.dart';
import 'Widget/MyCheckBox.dart';
import 'main.dart';

class Window extends StatefulWidget{

  MainPageState mainPageState;
  double labelFontSize = 16;
  String windowName;
  int windowIndex; //Start from 0
  int? year; int? yearMin; int? yearMax;
  int? month; int? monthMin; int? monthMax;
  int? day; int? dayMin; int? dayMax;

  bool magnumActive;
  bool totoActive;
  bool damacaiActive;

  List<String> lockedStringList = [];
  List<String> filterStringFormulaList = [];
  List<bool> filterBoolFormulaList = [];

  int row = 7;
  int column = 5;
  int fontSize = 13;

  bool show6D;
  String drawDayTypeString;

  Stream<RelevantDetail?> relevant_stream;
  Stream<List<Pair<String, Color>>> filter_stream;
  Stream<List<DayPrizesObj>> onSelectionChanged_stream;
  Stream<Pair<GeneralGestureType, Map<String, dynamic>>> generalGesture_stream;

  Window(
    {
      super.key,
      required this.mainPageState,
      required this.windowName,
      required this.windowIndex,
      required this.year, required this.yearMin, required this.yearMax,
      required this.month, required this.monthMin, required this.monthMax,
      required this.day, required this.dayMin, required this.dayMax,
      required this.row,
      required this.column,
      required this.fontSize,
      required this.show6D,
      required this.drawDayTypeString,
      required this.magnumActive,
      required this.totoActive,
      required this.damacaiActive,
      required this.lockedStringList,
      required this.filterStringFormulaList,
      required this.filterBoolFormulaList,
      required this.relevant_stream,
      required this.filter_stream,
      required this.onSelectionChanged_stream,
      required this.generalGesture_stream,
    }
  );

  @override
  State<StatefulWidget> createState() {
    return WindowState();
  }

}

class WindowState extends State<Window> with AutomaticKeepAliveClientMixin{

  late double labelFontSize;
  late int? year; late int? yearMin; late int? yearMax;
  late int? month; late int? monthMin; late int? monthMax;
  late int? day; late int? dayMin; late int? dayMax;
  late DrawDayType drawDayType;

  late int row;
  late int column;
  late int fontSize;

  static const int saveIntervalInMilli = 60*1000*2;
  int lastSaveTimeInMilli = 0;

  bool keepAlive = true;
  bool showRelevant = true;
  late bool show6D;
  bool showRelevantFloatingPanel = true;

  Map<String, bool> typeBoolMap = {};

  TextEditingController rowTEC = TextEditingController();
  TextEditingController columnTEC = TextEditingController();
  TextEditingController fontSizeTEC = TextEditingController();
  TextEditingController dayTEC = TextEditingController();
  TextEditingController monthTEC = TextEditingController();
  TextEditingController yearTEC = TextEditingController();
  TextEditingController filterTEC = TextEditingController();

  FocusNode rowFN = FocusNode();
  FocusNode columnFN = FocusNode();
  FocusNode fontSizeFN = FocusNode();
  FocusNode dayFN = FocusNode();
  FocusNode monthFN = FocusNode();
  FocusNode yearFN = FocusNode();
  FocusNode filterFN = FocusNode();

  List<DayPrizesObj> dayPrizesObjList = [];
  //
  late List<String> lockedStringList;
  late List<String> filterStringFormulaList;
  late List<bool> filterBoolFormulaList;

  double extraBarHeight = 0;

  @override
  bool get wantKeepAlive => keepAlive;

  @override
  void initState() {

    super.initState();

    //region setup variable
    labelFontSize = widget.labelFontSize;
    year = widget.year; yearMin = widget.yearMin; yearMax = widget.yearMax;
    month = widget.month; monthMin = widget.monthMin; monthMax = widget.monthMax;
    day = widget.day; dayMin = widget.dayMin; dayMax = widget.dayMax;

    row = widget.row;
    column = widget.column;
    fontSize = widget.fontSize;
    show6D = widget.show6D;
    drawDayType = DrawDayType.values.firstWhere((element) => element.name.toString() == widget.drawDayTypeString);
    typeBoolMap[PrizeObj.TYPE_MAGNUM4D] = widget.magnumActive;
    typeBoolMap[PrizeObj.TYPE_TOTO] = widget.totoActive;
    typeBoolMap[PrizeObj.TYPE_DAMACAI] = widget.damacaiActive;
    lockedStringList = widget.lockedStringList;
    filterStringFormulaList = widget.filterStringFormulaList;
    filterBoolFormulaList = widget.filterBoolFormulaList;
    //endregion

    //region setupTEC
    rowTEC.text = row.toString();
    columnTEC.text = column.toString();
    fontSizeTEC.text = fontSize.toString();
    dayTEC.text = day != null ? day.toString() : dayMin != null && dayMax != null ? "$dayMin-$dayMax" : "";
    monthTEC.text = month != null ? month.toString() : monthMin != null && monthMax != null ? "$monthMin-$monthMax" : "";
    yearTEC.text = year != null ? year.toString() : yearMin != null && yearMax != null ? "$yearMin-$yearMax" : "";
    //endregion

    //region setupFN
    yearFN.addListener(
        () {
          if(!yearFN.hasFocus){
            verifyAndSetYearInput(yearTEC.text);
          }
        },
    );
    monthFN.addListener(
      () {
        if(!monthFN.hasFocus){
          verifyAndSetMonthInput(monthTEC.text);
        }
      },
    );
    dayFN.addListener(
      () {
        if(!dayFN.hasFocus){
          verifyAndSetDayInput(dayTEC.text);
        }
      },
    );
    filterFN.addListener(
      () {
        if(!filterFN.hasFocus){
          verifyAndSetFilter(filterTEC.text);
        }
      },
    );    //endregion

    setState(() {
      fetchDayPrizesObjList(showSnackBar: false);
    });

    //Save window upon open
    Future.delayed(
      const Duration(seconds: 1),
        () async => await saveToPref(),
    );

    resume();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    //region dispose TEC
    rowTEC.dispose();
    columnTEC.dispose();
    fontSizeTEC.dispose();
    dayTEC.dispose();
    monthTEC.dispose();
    yearTEC.dispose();
    filterTEC.dispose();
    //endregion

    //region dispose FN
    rowFN.dispose();
    columnFN.dispose();
    fontSizeFN.dispose();
    dayFN.dispose();
    monthFN.dispose();
    yearFN.dispose();
    filterFN.dispose();
    //endregion
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return SizedBox(
          height: getBarHeight() + getBodyHeight(),
          child: Column(
            children: [
              Container(
                height: getBarHeight(),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 5,),
                        MyCheckBox(
                          width: 50,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          fontSize: labelFontSize.toDouble(),
                          value: typeBoolMap[PrizeObj.TYPE_MAGNUM4D]!,
                          onChange: (value) async {
                            setState(() {
                              typeBoolMap[PrizeObj.TYPE_MAGNUM4D] = value!;
                              fetchDayPrizesObjList();
                            });

                            await saveToPref();
                          },
                          child: const Image(
                              image: AssetImage("assets/magnum.ico"),

                          ),),
                        MyCheckBox(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          width: 50,
                          fontSize: labelFontSize,
                          value: typeBoolMap[PrizeObj.TYPE_TOTO]!,
                          onChange: (value) async {
                            setState(() {
                              typeBoolMap[PrizeObj.TYPE_TOTO] = value!;
                              fetchDayPrizesObjList();
                            });

                            await saveToPref();
                          },
                          child: const Image(
                            image: AssetImage("assets/toto.ico"),
                          ),
                        ),
                        MyCheckBox(
                          width: 50,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          fontSize: labelFontSize,
                          value: typeBoolMap[PrizeObj.TYPE_DAMACAI]!,
                          onChange: (value) async {
                            setState(() {
                              typeBoolMap[PrizeObj.TYPE_DAMACAI] = value!;
                              fetchDayPrizesObjList();
                            });

                            await saveToPref();
                          },
                          child: const Image(
                            image: AssetImage("assets/damacai.ico"),
                          ),),
                        Row(
                          children: [
                            Text("Year:", style: TextStyle(fontSize: labelFontSize),),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: yearTEC,
                                focusNode: yearFN,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isCollapsed: true,
                                ),
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(fontSize: labelFontSize),
                                onSubmitted: (event) {
                                  //verifyAndSetYearInput(yearTEC.text);
                                },
                                onTapOutside: (event){
                                  FocusScope.of(context).requestFocus(FocusNode());
                                },
                                autofocus: false,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(width: 5,),
                        Row(
                          children: [
                            Text("Month:", style: TextStyle(fontSize: labelFontSize),),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: monthTEC,
                                focusNode: monthFN,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isCollapsed: true,
                                ),
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(fontSize: labelFontSize),
                                onSubmitted: (event){
                                    //verifyAndSetMonthInput(monthTEC.text);
                                },
                                onTapOutside: (event){
                                  FocusScope.of(context).requestFocus(FocusNode());
                                },
                                autofocus: false,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(width: 5,),
                        Row(
                          children: [
                            Text("Day:", style: TextStyle(fontSize: labelFontSize),),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: dayTEC,
                                focusNode: dayFN,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isCollapsed: true,
                                ),
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(fontSize: labelFontSize),
                                onSubmitted: (event) async {
                                    //verifyAndSetDayInput(dayTEC.text);
                                },
                                onTapOutside: (event) async {
                                  FocusScope.of(context).requestFocus(FocusNode());
                                },
                                autofocus: false,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(width: 5,),
                        Row(
                          children: [
                            Text("Filter:", style: TextStyle(fontSize: labelFontSize),),
                            SizedBox(
                              width: 180,
                              child: TextField(
                                controller: filterTEC,
                                focusNode: filterFN,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isCollapsed: true,
                                ),
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(fontSize: labelFontSize),
                                onSubmitted: (event) async {
                                  //verifyAndSetFilter(filterTEC.text);
                                },
                                onTapOutside: (event) async {
                                  FocusScope.of(context).requestFocus(FocusNode());
                                },
                                autofocus: false,
                              ),
                            ),
                            SizedBox(
                              width: 400,
                              height: getBarHeight()-5,
                              child: AlignedGridView.count(
                                crossAxisCount: 6,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                                itemCount: filterStringFormulaList.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding:const EdgeInsets.symmetric(horizontal: 3),
                                    child: GestureDetector(
                                      onTap: () {
                                        toggleFilterBool(index);
                                      },
                                      child: Container(
                                        width: MyUtil.getWidthWithFontSize(labelFontSize)*4 +25,
                                        child: Row(
                                          children: [
                                            Text(
                                              filterStringFormulaList[index],
                                              style: TextStyle(
                                                backgroundColor: filterBoolFormulaList[index] ? MyConst.HighlightList[index] : MyConst.HighlightList[index].withAlpha(40),
                                                fontSize: labelFontSize,
                                              ),
                                            ),
                                            Flexible(
                                              child: SizedBox(
                                                height: 20,
                                                child: IconButton(
                                                  onPressed: () {
                                                    removeFilter(index);
                                                  },
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Colors.red,
                                                    size: 17,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )/*Row(
                                children: List<Widget>.generate(filterStringFormulaList.length, (index) => Padding(
                                  padding:const EdgeInsets.symmetric(horizontal: 3),
                                  child: GestureDetector(
                                    onTap: () {
                                      toggleFilterBool(index);
                                    },
                                    child: Container(
                                      width: MyUtil.getWidthWithFontSize(labelFontSize)*4 +25,
                                      child: Row(
                                        children: [
                                          Text(
                                              filterStringFormulaList[index],
                                              style: TextStyle(
                                                backgroundColor: filterBoolFormulaList[index] ? MyConst.HighlightList[index] : MyConst.HighlightList[index].withAlpha(40),
                                                fontSize: labelFontSize,
                                              ),
                                            ),
                                          Flexible(
                                            child: SizedBox(
                                              height: 20,
                                              child: IconButton(
                                                onPressed: () {
                                                  removeFilter(index);
                                                },
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: Colors.red,
                                                  size: 17,
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                )),
                              )*/,
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: SizedBox(
                            width: 50,
                            child: DropdownButton<String>(
                              value: show6D ? "6D" : "4D",
                              items: [
                                DropdownMenuItem(
                                    value: "4D",
                                    child: Text(
                                      "4D",
                                      style: TextStyle(
                                        fontSize: widget.fontSize.toDouble()+1,
                                      ),
                                    )
                                ),
                                DropdownMenuItem(
                                    value: "6D",
                                    child: Text(
                                      "6D",
                                      style: TextStyle(
                                        fontSize: widget.fontSize.toDouble()+1,
                                      ),
                                    )
                                )
                              ],
                              onChanged: (value) {
                                if(value != null){
                                  set4D6D(value);
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 108,
                          child: DropdownButton<DrawDayType>(
                            value: drawDayType,
                            items: List.generate(DrawDayType.values.length, (index){
                                  return DropdownMenuItem(
                                      value: DrawDayType.values[index],
                                      child: Text(
                                        DrawDayType.values[index].name,
                                        style: TextStyle(
                                          fontSize: widget.fontSize.toDouble()+1,
                                        ),
                                      )
                                  );
                                }
                              ),
                            onChanged: (value) {
                                if(value != null){
                                  setDrawDayType(value);
                                }
                              },
                          ),
                        ),
                        const Expanded(child: SizedBox.shrink()),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: IconButton(
                              onPressed: () async {
                                await openSettingDial();
                              },
                              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                              icon: const Icon(
                                Icons.settings,
                                size: 20,
                              )
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: showRelevant ? Colors.lightBlue.withAlpha(70) : Colors.grey.withAlpha(50),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: IconButton(
                              onPressed: () {
                                setState(() {
                                  showRelevant = !showRelevant;
                                });
                              },
                              color: showRelevant ? Colors.yellow : Colors.grey,
                              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                              icon: const Icon(
                                CupertinoIcons.wand_stars,
                                size: 20,
                              )
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: showRelevantFloatingPanel ? Colors.lightBlue.withAlpha(70) : Colors.grey.withAlpha(50),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: IconButton(
                              onPressed: () {
                                setState(() {
                                  showRelevantFloatingPanel = !showRelevantFloatingPanel;
                                });
                              },
                              color: showRelevantFloatingPanel ? Colors.yellow : Colors.grey,
                              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                              icon: const Icon(
                                Icons.sensor_window,
                                size: 20,
                              )
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onPanStart: (details) {
                        widget.mainPageState.setShowRelevant(false);
                      },
                      onPanUpdate: (details) {
                            RenderBox renderBox = context.findRenderObject() as RenderBox;

                            Offset bottomOfThisPosition = renderBox.localToGlobal(Offset(0, MediaQuery.of(context).size.height *0.07));
                            double _extraBarHeight = details.globalPosition.dy - bottomOfThisPosition.dy;

                            setState(() {
                              extraBarHeight = max(0, _extraBarHeight);
                            });
                      },
                      onPanEnd: (details) {
                        widget.mainPageState.setShowRelevant(true);
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeDown,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 5,
                        ),
                      ),
                    )
                    /*Row(
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Flexible(child: Row(
                                  children: [
                                    Text("Rows: ", style: TextStyle(fontSize: labelFontSize),),
                                    Center(
                                      child: SizedBox(
                                        width: 50,
                                        child: TextField(
                                          controller: rowTEC,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            isCollapsed: true,
                                          ),
                                          textAlign: TextAlign.center,
                                          textAlignVertical: TextAlignVertical.center,
                                          style: TextStyle(fontSize: labelFontSize),
                                          onSubmitted: (event) async {
                                            setState(() {
                                              row = int.tryParse(rowTEC.text) ?? row;
                                              if(row <= 2){
                                                row = 3;
                                              }
                                              rowTEC.text = row.toString();

                                            });
                                            await saveToPref();
                                          },
                                          onTapOutside: (event) async {
                                            setState(() {
                                              row = int.tryParse(rowTEC.text) ?? row;
                                              if(row <= 2){
                                                row = 3;
                                              }
                                              rowTEC.text = row.toString();

                                            });
                                            await saveToPref();
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                                const Expanded(child: SizedBox()),
                                Flexible(child: Row(
                                  children: [
                                    Text("Columns: ", style: TextStyle(fontSize: labelFontSize),),
                                    Center(
                                      child: SizedBox(
                                        width: 50,
                                        child: TextField(
                                          controller: columnTEC,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            isCollapsed: true,
                                          ),
                                          textAlign: TextAlign.center,
                                          textAlignVertical: TextAlignVertical.center,
                                          style: TextStyle(fontSize: labelFontSize),
                                          onSubmitted: (event) async {
                                            setState(() {
                                              column = int.tryParse(columnTEC.text) ?? column;

                                              if(column <= 0){
                                                column = 1;
                                              }
                                              columnTEC.text = column.toString();

                                            });
                                            await saveToPref();
                                          },
                                          onTapOutside: (event) async {
                                            setState(() {
                                              column = int.tryParse(columnTEC.text) ?? column;

                                              if(column <= 0){
                                                column = 1;
                                              }
                                              columnTEC.text = column.toString();

                                            });
                                            await saveToPref();
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                                const Expanded(child: SizedBox()),
                                Flexible(child: Row(
                                  children: [
                                    Text("FontSize: ", style: TextStyle(fontSize: labelFontSize),),
                                    Center(
                                      child: SizedBox(
                                        width: 50,
                                        child: TextField(
                                          controller: fontSizeTEC,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            isCollapsed: true,
                                          ),
                                          textAlign: TextAlign.center,
                                          textAlignVertical: TextAlignVertical.center,
                                          style: TextStyle(fontSize: labelFontSize),
                                          onSubmitted: (event) async {
                                            setState(() {
                                              fontSize = int.tryParse(fontSizeTEC.text) ?? fontSize;

                                              if(fontSize <= 5){
                                                fontSize = 6;
                                              }
                                              fontSizeTEC.text = fontSize.toString();

                                            });
                                            await saveToPref();
                                          },
                                          onTapOutside: (event) async {
                                            setState(() {
                                              fontSize = int.tryParse(fontSizeTEC.text) ?? fontSize;

                                              if(fontSize <= 5){
                                                fontSize = 6;
                                              }
                                              fontSizeTEC.text = fontSize.toString();

                                            });
                                            await saveToPref();
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                                const Expanded(child: SizedBox()),
                              ],
                            )
                          ),
                        ],
                    ),*/
                  ],
                ),
              ),
              OuterBox(
                mainPageState: widget.mainPageState,
                windowState: this,
                width: MediaQuery.sizeOf(context).width,
                height: getBodyHeight(),
                fontSize: fontSize.toDouble(),
                column: column,
                row: row,
                dayPrizesObjList: dayPrizesObjList,
                showRelevant: showRelevant,
                showRelevantFloatingPanel: showRelevantFloatingPanel,
                show6D: show6D,
                columnSpacing: 10,
                rowSpacing: 5,
                containerSpacing: 30,
                prizePadding: 1,
                order: Order.N,
                filterStringFormulaList: getActiveSortedFilterFormulaList(),
                relevant_stream: widget.relevant_stream,
                filter_stream: widget.filter_stream,
                onSelectionChanged_stream: widget.onSelectionChanged_stream,
                generalGesture_stream: widget.generalGesture_stream,
              )
            ],
          ),
      );
  }

  void fetchDayPrizesObjList({bool showSnackBar = true}){
    dayPrizesObjList = DataManager.getInstance().getSortedDateBasedDayPrizeObjList(
      typeBoolMap,
      year: year, yearMin: yearMin, yearMax: yearMax,
      month: month, monthMin:  monthMin, monthMax:  monthMax,
      day: day, dayMin: dayMin, dayMax: dayMax, filterList: getActiveSortedFilterFormulaList(),
      drawDayType: drawDayType
    );

    if(show6D){
      dayPrizesObjList.removeWhere((dayPrizeObj) => dayPrizeObj.firstPrize6D == null,);
    }

    if(showSnackBar){
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${dayPrizesObjList.length} result(s) found."),
        duration: const Duration(seconds: 2),
      ));
    }

    widget.mainPageState.clearSelectionList();
    widget.mainPageState.selection_streamController.sink.add(Pair(SelectionStage.panEnd, null));
  }

  void set4D6D(String type){
    setState(() {
      show6D = type == "6D";
    });
    fetchDayPrizesObjList();
    saveToPref();
  }

  void setDrawDayType(DrawDayType drawDayType){
    setState(() {
      this.drawDayType = drawDayType;
    });
    fetchDayPrizesObjList();
    saveToPref();


    Map<String, int> prizeCountMap = DataManager.getInstance().SortedByPrizeMap.map<String, int>((key, value) => MapEntry(MyUtil.padStringLeft(key, 4, "0"), value.length),);

    //print(prizeCountMap);

    Map<String, List<DayPrizesObj>> map = {};
    for(int i = 0; i < 1000; i++){
        print("doing $i");
        String chainString = MyUtil.padStringLeft("$i", 3, "0");
        String label = "?$chainString";
        map[label] = [];
        for(int j = 0; j < 10; j++){
          String headString = "$j";
          String targetString = "$headString$chainString";

          if(DataManager.getInstance().SortedByPrizeMap.containsKey(targetString)){
            for(DayPrizesObj dayPrizesObj in DataManager.getInstance().SortedByPrizeMap[targetString]!){
              if(!map[label]!.contains(dayPrizesObj)){
                map[label]!.add(dayPrizesObj);
              }
            }
          }
        }
    };


    List<Pair<String, List<DayPrizesObj>>> pairList = Pair.getPairListFromMap_BasedOnKey(map);

    pairList.sort(
      (a, b) {
        return a.second!.length - b.second!.length;
      },
    );

    pairList.forEach((element) {print("${element.first} - ${element.second!.length}");});
  }

  void verifyAndSetYearInput(String input){

    year = null;
    yearMin = null;
    yearMax = null;
    
    bool success = false;

    try{

      if(input.isEmpty){
        success = true; 
        return;
      }

      String compressed = input.replaceAll(RegExp(r"\s+"), "");

      if(compressed.contains("-")){
        List<String> subStrings = compressed.split("-");

        if(subStrings.length != 2){
          success = false; 
          return;
        }

        int head = int.tryParse(subStrings[0]) ?? -1;
        int tail = int.tryParse(subStrings[1]) ?? -1;

        if(head < 1000 || head > 9999 || tail < 1000 || tail > 9999 || tail < head){
          success = false; 
          return;
        }

        yearMin = head;
        yearMax = tail;
        success = true; 
        return;
      }

      int year = int.tryParse(compressed) ?? -1;

      if(year < 1000 || year > 9999){
        success = false; 
        return;
      }


      this.year = year;
      success = true; 
      return;

    }finally{
      setState(() {});
      fetchDayPrizesObjList();
      saveToPref();

      if(!success){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Invalid Year Input (Valid E.g. 1997 or 1997-2000)"),
        ));
        yearTEC.text = "";
      }
    }

  }

  void verifyAndSetMonthInput(String input){

    month = null;
    monthMin = null;
    monthMax = null;

    bool success = false;

    try{

      if(input.isEmpty){
        success = true;
        return;
      }

      String compressed = input.replaceAll(RegExp(r"\s+"), "");

      if(compressed.contains("-")){
        List<String> subStrings = compressed.split("-");

        if(subStrings.length != 2){
          success = false;
          return;
        }

        int head = int.tryParse(subStrings[0]) ?? -1;
        int tail = int.tryParse(subStrings[1]) ?? -1;

        if(head < 1 || head > 12 || tail < 1 || tail > 12 || tail < head){
          success = false;
          return;
        }

        monthMin = head;
        monthMax = tail;

        success = true;
        return;
      }

      int month = int.tryParse(compressed) ?? -1;

      if(month < 1 || month > 12){
        success = false;
        return;
      }


      this.month = month;
      success = true;
      return;

    }finally{
      setState(() {});
      fetchDayPrizesObjList();
      saveToPref();

      if(!success){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Invalid Month Input (Valid E.g. 5 or 5-9)"),
        ));
        monthTEC.text = "";
      }
    }

  }

  void verifyAndSetDayInput(String input){

    day = null;
    dayMin = null;
    dayMax = null;

    bool success = false;
    try{

      if(input.isEmpty){
        success = true;
        return;
      }

      String compressed = input.replaceAll(RegExp(r"\s+"), "");

      if(compressed.contains("-")){
        List<String> subStrings = compressed.split("-");

        if(subStrings.length != 2){
          success = false;
          return;
        }

        int head = int.tryParse(subStrings[0]) ?? -1;
        int tail = int.tryParse(subStrings[1]) ?? -1;

        if(head < 1 || head > 31 || tail < 1 || tail > 31 || tail < head){
          success = false;
          return;
        }

        dayMin = head;
        dayMax = tail;

        success = true;
        return;
      }

      int day = int.tryParse(compressed) ?? -1;

      if(day < 1 || day > 31){

        success = false;
        return;
      }


      this.day = day;

      success = true;
      return;

    }finally{
      setState(() {});
      fetchDayPrizesObjList();
      saveToPref();

      if(!success){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Invalid Day Input (Valid E.g. 9 or 9-20)"),
        ));
        dayTEC.text = "";
      }
    }

  }

  void verifyAndSetFilter(String input){

    bool success = false;

    try{
      List<String> filterList = [];

      String cleanString = input.replaceAll(RegExp(r"\s+"), "").replaceAll(RegExp(r'[^xyz?,\d]'), "").toLowerCase();
      List<String> subStringList = cleanString.split(",");

      bool invalidFormula = false;

      for(String filterString in subStringList){
        if(filterString.isEmpty || filterStringFormulaList.contains(filterString)){
          continue;
        }

        if((show6D && filterString.length != 6) || (!show6D && filterString.length != 4)){
          invalidFormula = true;
          continue;
        }

        /*
        if(filterString.contains("x")){
          String s = filterString.replaceAll("x", "");
          if(s.length > 2){
            invalidFormula = true;
            continue;
          }
        }
        if(filterString.contains("y")){
          String s = filterString.replaceAll("y", "");
          if(s.length > 2){
            invalidFormula = true;
            continue;
          }
        }
        if(filterString.contains("z")){
          if(!show6D){
            invalidFormula = true;
            continue;
          }

          String s = filterString.replaceAll("z", "");
          if(s.length > 2){
            invalidFormula = true;
            continue;
          }
        }
        */
        filterList.add(filterString);
      }

      //String organizedString = filterList.toString().replaceAll("[", "").replaceAll("]", "");

      filterTEC.text = "";

      int maxCount = MyConst.HighlightList.length;
      int count = 0;
      for(String filterString in filterList){
        filterStringFormulaList.add(filterString);
        filterBoolFormulaList.add(true);

        count++;
        if(count > maxCount){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Max Filter limit to ${MyConst.HighlightList.length}"),
          ));
          break;
        }
      }

      if(invalidFormula){
        success = false;
        return;
      }

      success = true;
      return;

    }finally{
        setState(() {});
        fetchDayPrizesObjList();
        saveToPref();

        if(!success){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Invalid Day Filter Formula Detected! E.g. of valid: ${show6D ? "xxyyzz xyzxyz ??12?? ?x?xyy" : "xxyy xxx? yy?? 12?? x12x"}"),
          ));
        }

        widget.mainPageState.updateFilterString(getFilterStringColorPair());
    }
  }

  void removeFilter(int index){
    setState(() {
      filterStringFormulaList.removeAt(index);
      filterBoolFormulaList.removeAt(index);
    });
    fetchDayPrizesObjList();
    saveToPref();
    widget.mainPageState.updateFilterString(getFilterStringColorPair());
  }

  void toggleFilterBool(int index){
    setState(() {
      filterBoolFormulaList[index] = !filterBoolFormulaList[index];
    });
    fetchDayPrizesObjList();
    saveToPref();
    widget.mainPageState.updateFilterString(getFilterStringColorPair());
  }

  List<Pair<String, Color>> getFilterStringColorPair(){
      List<Pair<String, Color>> pairList = [];

      List<String> activeSortedFilterFormulaList = getActiveSortedFilterFormulaList();

      for(int i = 0; i < activeSortedFilterFormulaList.length; i++){

          String filterString = activeSortedFilterFormulaList[i];

          int colorIndex = filterStringFormulaList.indexOf(filterString);
          Color color = MyConst.HighlightList[colorIndex];

          pairList.add(Pair(filterString, color));
      }

      return pairList;
  }

  List<String> getActiveSortedFilterFormulaList(){

    List<String> sortedFilterStringFormulaList_Active = [];

    for(int i = 0; i < filterStringFormulaList.length; i++){
      if(filterBoolFormulaList[i]){
        sortedFilterStringFormulaList_Active.add(filterStringFormulaList[i]);
      }
    }

    sortedFilterStringFormulaList_Active.sort(
      (a, b) {
        int numCount_a = a.length - a.replaceAll(RegExp(r'\d'), "").length;
        int numCount_b = b.length - b.replaceAll(RegExp(r'\d'), "").length;

        int xCount_a = a.length - a.replaceAll("x","").length;
        int xCount_b = b.length - b.replaceAll("x","").length;

        int yCount_a = a.length - a.replaceAll("y","").length;
        int yCount_b = b.length - b.replaceAll("y","").length;

        int jCount_a = a.length - a.replaceAll("?","").length;
        int jCount_b = b.length - b.replaceAll("?","").length;

        if(numCount_a != numCount_b){
            return numCount_b - numCount_a;
        }
        if(xCount_a != xCount_b){
          return xCount_b - xCount_a;
        }
        if(yCount_a != yCount_b){
          return yCount_b - yCount_a;
        }

        return jCount_b - jCount_a;
      },
    );

    return sortedFilterStringFormulaList_Active;
  }

  int getFilterStringIndex(String filterString){
      return filterStringFormulaList.indexOf(filterString);
  }

  Future<void> saveToPref() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    String windowKey = "${MyConst.Key_WindowHeader}${widget.windowName}";

    await sp.setString(windowKey, getEncodedJson());

    List<String> windowKeyList = sp.getStringList(MyConst.Key_WindowKeyList) ?? [];

    if(!windowKeyList.contains(windowKey)){
      windowKeyList.add(windowKey);
      await sp.setStringList(MyConst.Key_WindowKeyList, windowKeyList);
    }
  }

  double getBarHeight(){
      return MediaQuery.of(context).size.height *0.07 + extraBarHeight;
  }

  double getBodyHeight(){
      return MediaQuery.of(context).size.height *0.88 - extraBarHeight;
  }

  String getEncodedJson(){

    Map<String, dynamic> json = {
      "windowIndex": widget.windowIndex,
      "windowName": widget.windowName,
      "year" : year, "yearMin" : yearMin,"yearMax" : yearMax,
      "month" : month, "monthMin" : monthMin, "monthMax" : monthMax,
      "day" : day, "dayMin" : dayMin, "dayMax" : dayMax,
      "row":row,
      "column":column,
      "fontSize":fontSize,
      "show6D" : show6D,
      "drawDayTypeString": drawDayType.name.toString(),
      "magnumActive": typeBoolMap[PrizeObj.TYPE_MAGNUM4D],
      "totoActive": typeBoolMap[PrizeObj.TYPE_TOTO],
      "damacaiActive": typeBoolMap[PrizeObj.TYPE_DAMACAI],
      "lockedStringList":lockedStringList,
      "filterStringFormulaList":filterStringFormulaList,
      "filterBoolFormulaList":filterBoolFormulaList,
    };
    return jsonEncode(json);
  }

  Future<void> openSettingDial() async{
    final _settingDialKey = GlobalKey<SettingDialState>();

    AlertDialog dialog = AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      content: SettingDial(
        key: _settingDialKey,
        windowState: this,
        freePanelState: null,
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

  void close(){
    Navigator.pop(context);
  }

  void resume(){
      widget.mainPageState.updateFilterString(getFilterStringColorPair());
      widget.mainPageState.clearSelectionList();
  }

}