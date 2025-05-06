import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:toto/Util/MyUtil.dart';
import 'package:toto/Widget/FreePanel.dart';
import 'package:zoom_widget/zoom_widget.dart';

import '../DataManager.dart';
import '../Dialog/GetTextDialog.dart';
import '../Object/ChartDataObject.dart';
import '../Object/DayPrizesObj.dart';
import '../Object/PrizeObj.dart';
import '../Util/MyConst.dart';
import '../Util/Pair.dart';
import 'MyCheckBox.dart';

class GraphChartContainer extends StatefulWidget{

  FreePanelState freePanelState;
  String panelName;
  double width;
  double height;
  int? year; int? yearMin; int? yearMax;

  List<ChartDataObject> chartDataObjectStorage;
  List<ChartDataObject> chartDataObjectList;
  GraphOrdinate graphOrdinate;
  bool crossHair;

  int pointSize;

  GraphChartContainer(
    {
      super.key,
      required this.freePanelState,
      required this.panelName,
      required this.width,
      required this.height,
      required this.year, required this.yearMin, required this.yearMax,
      required this.chartDataObjectStorage,
      required this.chartDataObjectList,
      required this.graphOrdinate,
      required this.crossHair,
      required this.pointSize,
    }
  );

  @override
  State<StatefulWidget> createState() {
    return GraphChartContainerState();
  }

}

class GraphChartContainerState extends State<GraphChartContainer>{

  final double labelFontSize = 15;
  late TrackballBehavior _trackballBehavior;

  late int? year; late int? yearMin; late int? yearMax;
  TextEditingController yearTEC = TextEditingController();
  FocusNode yearFN = FocusNode();

  late int pointSize;
  TextEditingController pointTEC = TextEditingController();
  FocusNode pointFN = FocusNode();


  List<ChartDataObject> chartDataObjectStorage = []; //has everything
  List<ChartDataObject> chartDataObjectList = []; //has only filtered

  int? selectedSeriesIndex; int? selectedPointIndex;

  GraphOrdinate graphOrdinate = GraphOrdinate.Cumulative;
  bool crossHair = true;

  static const Color defaultColor = Colors.white;
  static const Color onEnterColor = Colors.grey;

  Color contentColor = defaultColor;
  @override
  void initState() {

    year = widget.year; yearMin = widget.yearMin; yearMax = widget.yearMax;
    yearTEC.text = year != null ? year.toString() : yearMin != null && yearMax != null ? "$yearMin-$yearMax" : "";
    yearFN.addListener(
          () {
        if(!yearFN.hasFocus){
          verifyAndSetYearInput(yearTEC.text);
        }
      },
    );

    pointSize = widget.pointSize;
    pointTEC.text = "$pointSize";
    pointFN.addListener(
          () {
        if(!pointFN.hasFocus){
          setPointSize(pointTEC.text);
        }
      },
    );

    this.chartDataObjectStorage = widget.chartDataObjectStorage;
    this.chartDataObjectList = widget.chartDataObjectList;
    this.graphOrdinate = widget.graphOrdinate;
    this.crossHair = widget.crossHair;

    _trackballBehavior = TrackballBehavior(
      // Enables the trackball
        enable: true,
        activationMode: ActivationMode.longPress,
        tooltipAlignment: ChartAlignment.near,
        tooltipDisplayMode: TrackballDisplayMode.nearestPoint,
        tooltipSettings: const InteractiveTooltip(
          enable: true,
          color: Colors.red,
          canShowMarker: true,
        ),
        builder: (context, trackballDetails) {

            if(trackballDetails.series != null){
              int seriesIndex = int.parse( trackballDetails.series!.key!.value );

              String? label = getLabel(seriesIndex);
              DayPrizesObj? dayPrizesObj = getDayPrizesObj(seriesIndex, trackballDetails.pointIndex);

              if(label != null && dayPrizesObj != null){
                String dateString = dayPrizesObj.getDateString(false, true);//"${dayPrizesObj.dateTime!.day} ${MyUtil.getMonthStringFromInt(dayPrizesObj.dateTime!.month, subStringLength: 3)}";
                List<String> matchPrizeString = [];

                if(DataManager.getInstance().applyFilterSub(dayPrizesObj.firstPrize!, label)){
                  matchPrizeString.add(dayPrizesObj.firstPrize!);
                }
                if(DataManager.getInstance().applyFilterSub(dayPrizesObj.secondPrize!, label)){
                  matchPrizeString.add(dayPrizesObj.secondPrize!);
                }
                if(DataManager.getInstance().applyFilterSub(dayPrizesObj.thirdPrize!, label)){
                  matchPrizeString.add(dayPrizesObj.thirdPrize!);
                }

                return Container(
                  height: 25,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.grey
                  ),
                  child: IntrinsicWidth(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                color: trackballDetails.series!.color
                            ),
                          ),
                        ),
                        Text(
                          dateString,
                          style: TextStyle(
                              fontSize: labelFontSize-1
                          ),
                        ),
                        Image(image: dayPrizesObj.getAssetImage(), width: 20,),
                        ...List<Widget>.generate(matchPrizeString.length, (index){
                          return Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text(
                              matchPrizeString[index],
                              style: TextStyle(
                                fontSize: labelFontSize-1,
                              ),
                            ),
                          );
                        })
                      ],
                    ),
                  ),
                );
              }
            }



            return SizedBox.shrink();
        },
    );

    fetchChartDataObjList();
    super.initState();
  }

  @override
  void dispose(){
    yearTEC.dispose();
    yearFN.dispose();
    pointTEC.dispose();
    pointFN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.white,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                width: widget.width,
                height: getBarHeight(),
                child: SizedBox(
                  width: widget.width,
                  child: Row(
                    children: [
                      Text("Year: ", style: TextStyle(fontSize: labelFontSize),),
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
                            verifyAndSetYearInput(yearTEC.text);
                          },
                          onTapOutside: (event){
                            FocusScope.of(context).requestFocus(FocusNode());
                          },
                          autofocus: false,
                        ),
                      ),
                      SizedBox(width: 10,),
                      SizedBox(
                        width: 115,
                        child: DropdownButton<GraphOrdinate>(
                          value: graphOrdinate,
                          items: List.generate(GraphOrdinate.values.length, (index){
                            return DropdownMenuItem(
                                value: GraphOrdinate.values[index],
                                child: Text(
                                  GraphOrdinate.values[index].name,
                                  style: TextStyle(
                                    fontSize: labelFontSize,
                                  ),
                                )
                            );
                          }
                          ),
                          onChanged: (value){
                            if(value != null){
                              setGraphOrdinate(value);
                            }
                          },
                        ),
                      ),
                      MyCheckBox(
                        value: crossHair,
                        onChange: (value) {
                          setState(() {
                            crossHair = value!;
                          });
                        },
                        text: "Crosshair",
                        width: 120,
                      ),
                      SizedBox(width: 5,),
                      Text("BulletSize: ", style: TextStyle(fontSize: labelFontSize),),
                      SizedBox(
                        width: 30,
                        child: TextField(
                          controller: pointTEC,
                          focusNode: pointFN,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isCollapsed: true,
                          ),
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(fontSize: labelFontSize),
                          onSubmitted: (event) {
                            setPointSize(pointTEC.text);
                          },
                          onTapOutside: (event){
                            FocusScope.of(context).requestFocus(FocusNode());
                          },
                          autofocus: false,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DragTarget<Object>(
                builder: (context, candidateData, rejectedData) {

                    List<Pair<String, DayPrizesObj>> pairList = [];

                    for(MapEntry<String, List<DayPrizesObj>> entry in DataManager.getInstance().SortedByPrizeMap.entries){

                      String label = entry.key;

                      for(DayPrizesObj dayPrizesObj in entry.value){
                        pairList.add(Pair(label, dayPrizesObj));
                      }
                    }

                    return Container(
                      width: widget.width,
                      height: getBodyHeight(),
                      color: contentColor,
                      child: SfCartesianChart(
                          primaryXAxis: DateTimeAxis(labelStyle: const TextStyle(fontSize: 18), name: "Time"),
                          primaryYAxis: NumericAxis(labelStyle: const TextStyle(fontSize: 18), name: "Cumulative Count"),
                          crosshairBehavior: CrosshairBehavior(
                            activationMode: ActivationMode.singleTap,
                            enable: crossHair,
                            shouldAlwaysShow: true,
                            lineColor: Colors.grey,
                            lineWidth: 1,
                            lineType: CrosshairLineType.horizontal
                          ),
                          trackballBehavior: _trackballBehavior,
                          legend: Legend(isVisible: true, legendItemBuilder: (legendText, series, point, seriesIndex) {

                              return Container(
                                width: 105,
                                height: 50,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 25,
                                        height: 5,
                                        color: MyConst.HighlightList[seriesIndex],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 2,
                                    ),
                                    Text(
                                      chartDataObjectList[seriesIndex].label,
                                      style: TextStyle(
                                        fontSize: labelFontSize
                                      ),
                                    ),
                                    SizedBox(
                                      width: 2,
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        removeIndex(seriesIndex);
                                      },
                                      icon: Icon(
                                        Icons.close,
                                        size: 15,
                                      )
                                    )
                                  ],
                                ),
                              );
                          },),
                          title: ChartTitle(
                            text: "Timeline",
                            textStyle: const TextStyle(color: Colors.white, fontSize: 20),
                            backgroundColor: Colors.blue,
                          ),
                          series: getLineSeriesList()
                      ),
                    );
                },
                onAccept: (data) async {

                    contentColor = defaultColor;

                    if(chartDataObjectStorage.length >= MyConst.HighlightList.length){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Max line series reached: ${MyConst.HighlightList.length}"),
                      ));
                      return;
                    }

                    if(data is ChartDataObject){
                        chartDataObjectStorage.add(data);

                    }else if(data is List<DayPrizesObj>){
                      //region ConfirmationDial
                      final _getTextDialKey = GlobalKey<GetTextDialState>();

                      AlertDialog confirmation_dialog = AlertDialog(
                        contentPadding: const EdgeInsets.all(0),
                        insetPadding: const EdgeInsets.all(0),
                        content: GetTextDial(
                          key: _getTextDialKey,
                          fontSize: 18,
                          height: 250,
                          question: "Please provide the pattern you which to assign to this line:",
                          subQuestion: "E.g. ?678, xxyy, 123?, xx??",
                          filteringTextInputFormatter: FilteringTextInputFormatter.allow(RegExp(r"[0-9?xXyYzZ]")),
                        ),
                      );

                      var pattern = await showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) {
                          return confirmation_dialog;
                        },
                      );

                      if(pattern != null){
                        ChartDataObject chartDataObject = ChartDataObject(label: pattern, dayPrizesObjList: data);
                        chartDataObjectStorage.add(chartDataObject);
                      }
                    }

                    fetchChartDataObjList();
                    saveToPref();
                    setState(() {});

                },
                onLeave: (data) {
                  setState(() {
                    contentColor = defaultColor;
                  });
                },
                onMove: (details) {
                  contentColor = onEnterColor;
                },
              )
            ],
          ),
          getDayPrizesObj(selectedSeriesIndex, selectedPointIndex) != null ? Align(
            alignment: Alignment.topRight,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: Image(
                    image: getDayPrizesObj(selectedSeriesIndex, selectedPointIndex)!.getAssetImage(),
                    width: 40,
                  )
                ),
                Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Container(
                              width: 35,
                              height: 5,
                              color: MyConst.HighlightList[selectedSeriesIndex!],
                            ),
                          ),
                          SizedBox(width: 10,),
                          Text(
                            getLabel(selectedSeriesIndex)!,
                            style: TextStyle(
                              fontSize: labelFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        getDayPrizesObj(selectedSeriesIndex, selectedPointIndex)!.getDateString(false, false),
                        style: TextStyle(
                          fontSize: labelFontSize-1,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "1st:  ",
                            style: TextStyle(
                              fontSize: labelFontSize-2,
                            ),
                          ),
                          Container(
                            color: DataManager.getInstance().applyFilterSub(getDayPrizesObj(selectedSeriesIndex, selectedPointIndex)!.firstPrize!, getLabel(selectedSeriesIndex)!) ? MyConst.defaultHighlight : null,
                            child: Text(
                              getDayPrizesObj(selectedSeriesIndex, selectedPointIndex)!.firstPrize!,
                              style: TextStyle(
                                fontSize: labelFontSize-1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "2nd:  ",
                            style: TextStyle(
                              fontSize: labelFontSize-2,
                            ),
                          ),
                          Container(
                            color: DataManager.getInstance().applyFilterSub(getDayPrizesObj(selectedSeriesIndex, selectedPointIndex)!.secondPrize!, getLabel(selectedSeriesIndex)!) ? MyConst.defaultHighlight : null,
                            child: Text(
                              getDayPrizesObj(selectedSeriesIndex, selectedPointIndex)!.secondPrize!,
                              style: TextStyle(
                                fontSize: labelFontSize-1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "3rd:  ",
                            style: TextStyle(
                              fontSize: labelFontSize-2,
                            ),
                          ),
                          Container(
                            color: DataManager.getInstance().applyFilterSub(getDayPrizesObj(selectedSeriesIndex, selectedPointIndex)!.thirdPrize!, getLabel(selectedSeriesIndex)!) ? MyConst.defaultHighlight : null,
                            child: Text(
                              getDayPrizesObj(selectedSeriesIndex, selectedPointIndex)!.thirdPrize!,
                              style: TextStyle(
                                fontSize: labelFontSize-1,
                              ),
                            ),
                          ),

                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ) : const SizedBox.shrink()
        ],
      ),
    );
  }

  void removeIndex(int seriesIndex){
    if(seriesIndex >= chartDataObjectList.length){
      return;
    }

    setState(() {
      chartDataObjectStorage.removeAt(seriesIndex);
      chartDataObjectList.removeAt(seriesIndex);
      fetchChartDataObjList();
    });
    saveToPref();
  }

  String? getLabel(int? seriesIndex){
    if(seriesIndex != null && seriesIndex < chartDataObjectList.length){
      return chartDataObjectList[seriesIndex].label;
    }

    return null;
  }

  DayPrizesObj? getDayPrizesObj(int? seriesIndex, int? pointIndex){
    if(getLabel(seriesIndex) != null && pointIndex != null && (pointIndex < chartDataObjectList[seriesIndex!].filteredDayPrizesObjList.length)){
      return chartDataObjectList[seriesIndex].filteredDayPrizesObjList[pointIndex];
    }

    return null;
  }

  void fetchChartDataObjList(){
      chartDataObjectList = List.from(chartDataObjectStorage);

      for(ChartDataObject chartDataObject in chartDataObjectList){
        List<DayPrizesObj> filteredDayPrizesObjList = List.from(chartDataObject.dayPrizesObjList);
        filteredDayPrizesObjList.removeWhere((element){

          if(year != null){
            return element.dateTime!.year != year;
          }
          if(yearMin != null && yearMax != null){
            return element.dateTime!.year < yearMin! || element.dateTime!.year > yearMax!;
          }

          return false;

        });

        filteredDayPrizesObjList.sort(
              (a, b) {
            if(a.dateTime!.isBefore(b.dateTime!)){
              return -1;
            }else if(b.dateTime!.isBefore(a.dateTime!)){
              return 1;
            }

            return 0;
          },
        );

        chartDataObject.setFilteredDayPrizesObjList(filteredDayPrizesObjList);
      }
  }

  void setGraphOrdinate(GraphOrdinate graphOrdinate){
    setState(() {
      this.graphOrdinate = graphOrdinate;
    });
    saveToPref();
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
      fetchChartDataObjList();
      saveToPref();

      if(!success){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Invalid Year Input (Valid E.g. 1997 or 1997-2000)"),
        ));
        yearTEC.text = "";
      }
    }

  }

  void setPointSize(String pointSizeString){
    setState(() {
      pointSize = int.tryParse(pointSizeString) ?? pointSize;

      pointSize = min(max(pointSize, 5), 25);
    });
    saveToPref();
  }

  List<LineSeries> getLineSeriesList(){
    return List.generate(chartDataObjectList.length, (index){

      List<DayPrizesObj> filteredDayPrizesObjList = List.from(chartDataObjectList[index].filteredDayPrizesObjList);

      return LineSeries<DayPrizesObj, DateTime>(
        dataSource: filteredDayPrizesObjList,
        xValueMapper: (DayPrizesObj dayPrizesObj, _) => dayPrizesObj.dateTime,
        yValueMapper: (DayPrizesObj dayPrizesObj, _){

          int value;

          switch(graphOrdinate){
            case GraphOrdinate.Cumulative:
              value = filteredDayPrizesObjList.indexOf(dayPrizesObj)+1;
              break;

            case GraphOrdinate.Month:
              value = dayPrizesObj.dateTime!.month;
              break;

            case GraphOrdinate.Week:
              value = ((dayPrizesObj.dateTime!.day).toDouble() / 7).ceil();
              break;

            case GraphOrdinate.Day:
              value = dayPrizesObj.dateTime!.day;
              break;

            case GraphOrdinate.WeekDay:
              value = dayPrizesObj.dateTime!.weekday;
              break;

            default:
              value = filteredDayPrizesObjList.indexOf(dayPrizesObj)+1;
          }

          return value;//filteredDayPrizesObjList.indexOf(dayPrizesObj)+1;
        },
        key: ValueKey("$index"),
        xAxisName: "Time",
        yAxisName: "Cumulative Count",
        // Width of the bars
        width: 2,
        onPointTap: (pointInteractionDetails) {
          setState(() {
            if(selectedSeriesIndex == pointInteractionDetails.seriesIndex && selectedPointIndex == pointInteractionDetails.pointIndex){
              selectedSeriesIndex = null;
              selectedPointIndex = null;
            }else{
              selectedSeriesIndex = pointInteractionDetails.seriesIndex;
              selectedPointIndex = pointInteractionDetails.pointIndex;
            }
          });
        },
        selectionBehavior: SelectionBehavior(
        ),
        enableTooltip: true,
        animationDuration: 1000,
        name: chartDataObjectList[index].label,
        color: MyConst.HighlightList[index],
        dataLabelSettings: DataLabelSettings(
          isVisible:true,
          showCumulativeValues: true,
          builder: (data, point, series, pointIndex, seriesIndex) {
            return Container(
              width: pointSize.toDouble(),
              height: pointSize.toDouble(),
              decoration: BoxDecoration(
                shape: (selectedSeriesIndex == seriesIndex && selectedPointIndex == pointIndex) ? BoxShape.rectangle : BoxShape.circle,
                color: MyConst.HighlightList[index],
              ),
            );
          },
          alignment: ChartAlignment.center,
          labelAlignment: ChartDataLabelAlignment.middle,
          showZeroValue: false,
        ),
      );

    });
  }

  Future<void> saveToPref() async {
    if(widget.freePanelState.mounted){
      widget.freePanelState.setGraphChartJson(getEncodedJson());
      await widget.freePanelState.saveToPref();
    }
  }

  String getEncodedJson(){

    Map<String, dynamic> json = {
      "panelName" : widget.panelName,
      "year" : widget.year,
      "yearMin" : widget.yearMin,
      "yearMax" : widget.yearMax,
      "chartDataObjectStorage" : chartDataObjectStorage.map<String>((e) => e.getEncodedJson()).toList(),
      "chartDataObjectListString" : chartDataObjectList.map<String>((e) => e.getEncodedJson()).toList(),
      "graphOrdinate" : graphOrdinate.name.toString(),
      "crossHair" : crossHair,
      "pointSize" : pointSize,
    };

    return jsonEncode(json);
  }

  double getBarHeight(){
    return 70;
  }

  double getBodyHeight(){
    return widget.height - getBarHeight();
  }
}

enum GraphOrdinate{
  Cumulative, Month, Week, Day, WeekDay
}


