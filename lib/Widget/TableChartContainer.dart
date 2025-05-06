import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


import '../DataManager.dart';
import '../Object/ChartDataObject.dart';
import '../Object/DayPrizesObj.dart';
import '../Object/PrizeObj.dart';
import '../Util/Pair.dart';
import 'FreePanel.dart';
import 'MyCheckBox.dart';

class TableChartContainer extends StatefulWidget{

  FreePanelState freePanelState;
  String panelName;
  double width;
  double height;

  int? year; int? yearMin; int? yearMax;
  int? month; int? monthMin; int? monthMax;
  int? day; int? dayMin; int? dayMax;

  bool magnumActive;
  bool totoActive;
  bool damacaiActive;

  DrawDayType drawDayType;

  List<ChartDataObject> chartDataObjectList;

  PrizePatternType prizePatternType;
  SortType sortType;

  double scrollOffset;
  String? selectedDataObjectLabel;

  TableChartContainer(
    {
      super.key,
      required this.freePanelState,
      required this.panelName,
      required this.width,
      required this.height,
      required this.year, required this.yearMin, required this.yearMax,
      required this.month, required this.monthMin, required this.monthMax,
      required this.day, required this.dayMin, required this.dayMax,
      required this.magnumActive,
      required this.totoActive,
      required this.damacaiActive,
      required this.drawDayType,
      required this.chartDataObjectList,
      required this.prizePatternType,
      required this.sortType,
      required this.scrollOffset,
      required this.selectedDataObjectLabel,
    }
  );

  @override
  State<StatefulWidget> createState() {
    return TableChartContainerState();
  }

}

class TableChartContainerState extends State<TableChartContainer>{

  double labelFontSize = 15;
  late int? year; late int? yearMin; late int? yearMax;
  late int? month; late int? monthMin; late int? monthMax;
  late int? day; late int? dayMin; late int? dayMax;
  late DrawDayType drawDayType;

  Map<String, bool> typeBoolMap = {};

  TextEditingController dayTEC = TextEditingController();
  TextEditingController monthTEC = TextEditingController();
  TextEditingController yearTEC = TextEditingController();
  FocusNode dayFN = FocusNode();
  FocusNode monthFN = FocusNode();
  FocusNode yearFN = FocusNode();

  ChartDataObject? selectedDataObject;

  late List<ChartDataObject> chartDataObjectList;

  late PrizePatternType prizePatternType;
  late SortType sortType;

  ScrollController scrollController = ScrollController();
  double scrollOffset = 0;

  @override
  void initState() {

    //region setup variable
    year = widget.year; yearMin = widget.yearMin; yearMax = widget.yearMax;
    month = widget.month; monthMin = widget.monthMin; monthMax = widget.monthMax;
    day = widget.day; dayMin = widget.dayMin; dayMax = widget.dayMax;
    drawDayType = widget.drawDayType;
    typeBoolMap[PrizeObj.TYPE_MAGNUM4D] = widget.magnumActive;
    typeBoolMap[PrizeObj.TYPE_TOTO] = widget.totoActive;
    typeBoolMap[PrizeObj.TYPE_DAMACAI] = widget.damacaiActive;
    //chartDataObjectList = widget.chartDataObjectList;
    prizePatternType = widget.prizePatternType;
    sortType = widget.sortType;
    scrollOffset = widget.scrollOffset;
    //endregion

    //region setupTEC
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
    //endregion

    setState(() {
      fetchChartDataObjList(showSnackBar: false);
      for(ChartDataObject chartDataObject in chartDataObjectList){
        if(chartDataObject.label == widget.selectedDataObjectLabel){
          selectedDataObject = chartDataObject;
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback(
          (timeStamp) {
        scrollController.addListener(() {
          scrollOffset = scrollController.offset;
          /*if(!scrollController.position.isScrollingNotifier.value) {

            print("scroll end");
            //saveToPref();
          }else{
            print("scroll started");
          }*/
        });

        try{
          scrollController.jumpTo(scrollOffset);

        }catch(e,ex){
          print("Fail to jump to scrollOffset, $ex");
        }
      },
    );

    super.initState();
  }

  @override
  void dispose(){

    dayTEC.dispose();
    monthTEC.dispose();
    yearTEC.dispose();

    dayFN.dispose();
    monthFN.dispose();
    yearFN.dispose();

    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: widget.width,
            height: getBarHeight(),
            child: SizedBox(
              width: widget.width,
              child: Row(
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
                        fetchChartDataObjList();
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
                        fetchChartDataObjList();
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
                        fetchChartDataObjList();
                      });

                      await saveToPref();
                    },
                    child: const Image(
                      image: AssetImage("assets/damacai.ico"),
                    ),),
                  Row(
                    children: [
                      Text("Year: ", style: TextStyle(fontSize: labelFontSize),),
                      SizedBox(
                        width: 80,
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
                          },
                          onTapOutside: (event){
                            FocusScope.of(context).requestFocus(FocusNode());
                          },
                          autofocus: false,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 10,),
                  Row(
                    children: [
                      Text("Month: ", style: TextStyle(fontSize: labelFontSize),),
                      SizedBox(
                        width: 50,
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
                  const SizedBox(width: 10,),
                  Row(
                    children: [
                      Text("Day: ", style: TextStyle(fontSize: labelFontSize),),
                      SizedBox(
                        width: 50,
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
                  const SizedBox(width: 10,),
                  SizedBox(
                    width: 115,
                    child: DropdownButton<DrawDayType>(
                      value: drawDayType,
                      items: List.generate(DrawDayType.values.length, (index){
                        return DropdownMenuItem(
                            value: DrawDayType.values[index],
                            child: Text(
                              DrawDayType.values[index].name,
                              style: TextStyle(
                                fontSize: labelFontSize,
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
                  SizedBox(width: 5,),
                  SizedBox(
                    width: 80,
                    child: DropdownButton<PrizePatternType>(
                      value: prizePatternType,
                      items: List.generate(PrizePatternType.values.length, (index){
                        return DropdownMenuItem(
                            value: PrizePatternType.values[index],
                            child: Text(
                              PrizePatternType.values[index].name.replaceAll("Pattern", ""),
                              style: TextStyle(
                                fontSize: labelFontSize,
                              ),
                            )
                        );
                      }
                      ),
                      onChanged: (value) {
                        if(value != null){
                          setPrizePatternType(value);
                        }
                      },
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        setState(() {
                          sortType = sortType == SortType.Pattern ? SortType.Ascending : sortType == SortType.Ascending ? SortType.Descending : SortType.Pattern;
                          sortDataObjectList();
                        });
                      },
                      icon: Icon(
                          sortType == SortType.Pattern ? Icons.menu_rounded : sortType == SortType.Ascending ? CupertinoIcons.sort_up : CupertinoIcons.sort_down
                      )
                  ),
                ],
              ),
            )
          ),
          Container(
            width: widget.width,
            height: getBodyHeight(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text("Pattern", style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w500),),),
                      Expanded(child: Text("Count", style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w500),)),
                      Expanded(flex: 5, child: Center(child: Text("Detail", style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w500),),))
                    ],
                  ),
                  SizedBox(
                    height: getBodyHeight()-23,
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: chartDataObjectList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            setState(() {
                              if(selectedDataObject == chartDataObjectList[index]){
                                selectedDataObject = null;
                              }else{
                                selectedDataObject = chartDataObjectList[index];
                              }
                            });
                            await saveToPref();
                          },
                          child: Container(
                            color: selectedDataObject == chartDataObjectList[index] ? Colors.yellow : null,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Draggable<ChartDataObject>(
                                    data: chartDataObjectList[index],
                                    feedback: Container(
                                      width: 100,
                                      height: 25,
                                      color: Colors.yellow,
                                      child: Center(
                                        child: Text(
                                          chartDataObjectList[index].label,
                                          style: TextStyle(
                                            fontSize: labelFontSize,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      chartDataObjectList[index].label,
                                      style: TextStyle(
                                        fontSize: labelFontSize,
                                      ),
                                    ),
                                  )
                                ),
                                Expanded(
                                  child: Text(
                                    chartDataObjectList[index].dayPrizesObjList.length.toString(),
                                    style: TextStyle(
                                      fontSize: labelFontSize,
                                    ),
                                  )
                                ),
                                Expanded(
                                    flex: 5,
                                    child: Text(
                                      getPrizeDetailString(chartDataObjectList[index].label, chartDataObjectList[index].dayPrizesObjList),
                                      style: TextStyle(
                                        fontSize: labelFontSize-1,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                )
                              ],
                            ),
                          ),
                        );
                      },),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  String getPrizeDetailString(String pattern, List<DayPrizesObj> dayPrizesObjList){
      Map<String, int> mapCount = {};

      for(DayPrizesObj dayPrizesObj in dayPrizesObjList){
        String firstPrize = dayPrizesObj.firstPrize!;
        String secondPrize = dayPrizesObj.secondPrize!;
        String thirdPrize = dayPrizesObj.thirdPrize!;

        if(firstPrize.contains(pattern.replaceAll(RegExp(r"[^0-9]"), ""))){
          if(!mapCount.containsKey(firstPrize)){
            mapCount[firstPrize] = 0;
          }
          mapCount[firstPrize] = mapCount[firstPrize]! + 1;
        }
        if(secondPrize.contains(pattern.replaceAll(RegExp(r"[^0-9]"), ""))){
          if(!mapCount.containsKey(secondPrize)){
            mapCount[secondPrize] = 0;
          }
          mapCount[secondPrize] = mapCount[secondPrize]! + 1;
        }
        if(thirdPrize.contains(pattern.replaceAll(RegExp(r"[^0-9]"), ""))){
          if(!mapCount.containsKey(thirdPrize)){
            mapCount[thirdPrize] = 0;
          }
          mapCount[thirdPrize] = mapCount[thirdPrize]! + 1;
        }
      }

      List<String> sortedKey = mapCount.keys.toList();

      sortedKey.sort(
        (a, b) {
          int int_a = int.parse(a);
          int int_b = int.parse(b);

          return int_a-int_b;
        },
      );

      String prizeDetailString = "";
      for(String key in sortedKey){
        int count = mapCount[key]!;

        prizeDetailString += " $key(x$count)";
      }

      return prizeDetailString;
  }

  void sortDataObjectList(){
    chartDataObjectList.sort((a, b) {
        if(sortType == SortType.Pattern){

          int chainInt_a = 0;
          int chainInt_b = 0;

          if(prizePatternType == PrizePatternType.Pattern_XYZ){
            chainInt_a = int.parse(a.label.substring(1,4));
            chainInt_b = int.parse(b.label.substring(1,4));
          }else if(prizePatternType == PrizePatternType.PatternWXY_){
            chainInt_a = int.parse(a.label.substring(0,3));
            chainInt_b = int.parse(b.label.substring(0,3));
          }


          return chainInt_a - chainInt_b;
        }

        if(sortType == SortType.Ascending){
          return a.dayPrizesObjList.length - b.dayPrizesObjList.length;
        }else{
          return b.dayPrizesObjList.length - a.dayPrizesObjList.length;
        }
        //return a.second!.length - b.second!.length;
      },
    );
    chartDataObjectList.removeWhere((element) => element.dayPrizesObjList.length < 2);
  }

  void fetchChartDataObjList({showSnackBar = true}){

    print("fetch called");

    Map<String, List<DayPrizesObj>> map = DataManager.getInstance().getPrizeBasedDayPrizeObjMap(
        typeBoolMap,
        year: year, yearMin: yearMin, yearMax: yearMax,
        month: month, monthMin:  monthMin, monthMax:  monthMax,
        day: day, dayMin: dayMin, dayMax: dayMax,
        drawDayType: drawDayType, prizePatternType: prizePatternType,
    );

    chartDataObjectList = ChartDataObject.getDataObjectList(Pair.getPairListFromMap_BasedOnKey(map));
    sortDataObjectList();
  }

  void setDrawDayType(DrawDayType drawDayType){
    setState(() {
      this.drawDayType = drawDayType;
    });
    fetchChartDataObjList();
    saveToPref();
  }

  void setPrizePatternType(PrizePatternType prizePatternType){
    setState(() {
      this.prizePatternType = prizePatternType;
    });
    fetchChartDataObjList();
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
      fetchChartDataObjList();
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
      fetchChartDataObjList();
      saveToPref();

      if(!success){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Invalid Day Input (Valid E.g. 9 or 9-20)"),
        ));
        dayTEC.text = "";
      }
    }

  }

  double getBarHeight(){
    return 70;
  }

  double getBodyHeight(){
    return widget.height - getBarHeight();
  }

  Future<void> saveToPref() async {
    if(widget.freePanelState.mounted){
      widget.freePanelState.setTableChartJson(getEncodedJson());
      await widget.freePanelState.saveToPref();
    }
  }

  String getEncodedJson(){

    Map<String, dynamic> json = {
      "year" : year, "yearMin" : yearMin,"yearMax" : yearMax,
      "month" : month, "monthMin" : monthMin, "monthMax" : monthMax,
      "day" : day, "dayMin" : dayMin, "dayMax" : dayMax,
      "magnumActive": typeBoolMap[PrizeObj.TYPE_MAGNUM4D],
      "totoActive": typeBoolMap[PrizeObj.TYPE_TOTO],
      "damacaiActive": typeBoolMap[PrizeObj.TYPE_DAMACAI],
      "drawDayTypeString" : drawDayType.name.toString(),
      "chartDataObjectListString" : chartDataObjectList.map<String>((e) => e.getEncodedJson()).toList(),
      "prizePatternType" : prizePatternType.name.toString(),
      "sortType" : sortType.name.toString(),
      "scrollOffset" : scrollOffset,
      "selectedDataObjectLabel" : selectedDataObject?.label,
    };

    return jsonEncode(json);
  }
}

enum PrizePatternType{
  Pattern_XYZ, PatternWXY_
}

enum SortType{
  Pattern, Ascending, Descending
}
