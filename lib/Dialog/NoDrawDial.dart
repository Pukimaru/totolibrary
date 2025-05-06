import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toto/Object/PrizeObj.dart';

import '../DataManager.dart';
import '../Object/DayPrizesObj.dart';
import '../Util/Pair.dart';
import 'ConfirmationDial.dart';
import 'LoadingDial.dart';
import 'NoticeDial.dart';

class NoDrawDial extends StatefulWidget{

  Map<String, List<DateTime>> invalidDateMap;

  NoDrawDial(
    {
      super.key,
      required this.invalidDateMap,
    }
  );



  @override
  State<StatefulWidget> createState() {
    return NoDrawDialState();
  }

}

class NoDrawDialState extends State<NoDrawDial> with TickerProviderStateMixin{

  double labelSize = 16;
  double entryHeight = 50;

  late TabController tabController;
  UploadAttempt? filterSelected;

  List<Pair<String, DateTime>> magnumInvalidDateList = [];
  List<Pair<String, DateTime>> totoInvalidDateList = [];
  List<Pair<String, DateTime>> damacaiInvalidDateList = [];

  List<Pair<String, DateTime>> checkedInvalidDateList = [];

  bool isAllSelected = false;

  late StreamController<double> streamController;

  @override
  void initState() {

    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      setState(() {
        isAllSelected = getIsAllSelected();
      });
    });
    streamController = StreamController.broadcast();

    //region setup List
    for(String type in widget.invalidDateMap.keys){
      switch(type){
        case PrizeObj.TYPE_MAGNUM4D:
          magnumInvalidDateList = widget.invalidDateMap[type]!.map<Pair<String, DateTime>>((e) => Pair(PrizeObj.TYPE_MAGNUM4D, e)).toList();
          break;

        case PrizeObj.TYPE_TOTO:
          totoInvalidDateList = widget.invalidDateMap[type]!.map<Pair<String, DateTime>>((e) => Pair(PrizeObj.TYPE_TOTO, e)).toList();
          break;

        case PrizeObj.TYPE_DAMACAI:
          damacaiInvalidDateList = widget.invalidDateMap[type]!.map<Pair<String, DateTime>>((e) => Pair(PrizeObj.TYPE_DAMACAI, e)).toList();
          break;
      }
    }

    checkedInvalidDateList.addAll(magnumInvalidDateList);
    checkedInvalidDateList.addAll(totoInvalidDateList);
    checkedInvalidDateList.addAll(damacaiInvalidDateList);

    setState(() {
      isAllSelected = getIsAllSelected();
    });
    //endregion

    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      width: getThisWidth(),
      height: getThisHeight(),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const Text(
              "INVALID DATES",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500
              ),
            ),
            const Text(
              "Please select the dates that you wish to add into No Draw Dates.",
              style: TextStyle(
                fontSize: 18,
                color: Colors.red
              ),
            ),
            const SizedBox(height: 5,),
            Text("Total Selected: ${checkedInvalidDateList.length}", style: TextStyle(fontSize: labelSize),),
            TabBar(
                controller: tabController,
                tabs: [
                  Text("MAGNUM (${magnumInvalidDateList.length})", style: TextStyle(fontSize: labelSize+1),),
                  Text("TOTO (${totoInvalidDateList.length})", style: TextStyle(fontSize: labelSize+1),),
                  Text("DAMACAI (${damacaiInvalidDateList.length})", style: TextStyle(fontSize: labelSize+1),),
                ]
            ),
            SizedBox(
              height: entryHeight,
              child: Row(
                children: [
                  Checkbox(
                    value: isAllSelected,
                    onChanged: (value) {

                      setState(() {
                        int tabIndex = tabController.index;
                        List<Pair<String, DateTime>> targetList = tabIndex == 0 ? magnumInvalidDateList : tabIndex == 1 ? totoInvalidDateList : damacaiInvalidDateList;
                        if(isAllSelected){
                          for (Pair<String, DateTime> dateTimeTypePair in targetList) {
                            if(checkedInvalidDateList.contains(dateTimeTypePair)){
                              checkedInvalidDateList.remove(dateTimeTypePair);
                            }
                          }
                        }else{
                            for (Pair<String, DateTime> dateTimeTypePair in targetList) {
                              if(!checkedInvalidDateList.contains(dateTimeTypePair)){
                                checkedInvalidDateList.add(dateTimeTypePair);
                              }
                            }
                        }
                      });

                      isAllSelected = getIsAllSelected();
                    },
                  ),
                  const SizedBox(width: 5,),
                  Expanded(
                      child: Text(
                        "Selected ALL",
                        style: TextStyle(
                            fontSize: labelSize,
                            color: Colors.black
                        ),
                      )
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                  controller: tabController,
                  children: [
                    buildListView(magnumInvalidDateList),
                    buildListView(totoInvalidDateList),
                    buildListView(damacaiInvalidDateList),
                  ]
              ),
            ),
            SizedBox(
              height: 75,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: TextButton(
                          onPressed: () {close();},
                          child: const Center(child: Text("Ignore", textAlign: TextAlign.center, style: TextStyle(fontSize: 20),), ),
                        ),
                      )
                  ),
                  Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: TextButton(
                          onPressed: checkedInvalidDateList.isEmpty ? null : () async { await addToNoDrawDates();},
                          child: const Center(child: Text("Add To NoDrawDates", textAlign: TextAlign.center, style: TextStyle(fontSize: 20),), ),
                        ),
                      )
                  ),
                ],
              ),
            )
          ],
        )
      ),
    );
  }

  Widget buildListView(List<Pair<String, DateTime>> dateTypePairList){
    return ListView.builder(
      itemCount: dateTypePairList.length,
      itemBuilder: (context, index) {

        Pair<String, DateTime> dateTypePair = dateTypePairList[index];

          return SizedBox(
            height: entryHeight,
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                        value: checkedInvalidDateList.contains(dateTypePair),
                        onChanged: (value) {
                          setState(() {
                            if(checkedInvalidDateList.contains(dateTypePair)){
                              checkedInvalidDateList.remove(dateTypePair);
                            }else{
                              checkedInvalidDateList.add(dateTypePair);
                            }
                          });
                        },
                    ),
                    const SizedBox(width: 5,),
                    Expanded(
                        child: Row(
                          children: [
                            Image(
                              image: AssetImage(
                                dateTypePair.first == PrizeObj.TYPE_MAGNUM4D ? "assets/magnum.ico" :
                                dateTypePair.first == PrizeObj.TYPE_TOTO ? "assets/toto.ico" :
                                "assets/damacai.ico",
                              ),
                              width: 25,
                            ),
                            const SizedBox(width: 5,),
                            Text(
                              DateFormat("dd/MM/yyyy").format(dateTypePair.second!),
                              style: TextStyle(
                                  fontSize: labelSize,
                              ),
                            ),
                          ],
                        )
                    ),
                  ],
                ),
              ],
            ),
          );
      }
    ,);
  }

  bool getIsAllSelected(){

    int tabIndex = tabController.index;

    List<Pair<String, DateTime>> toCheckList = tabIndex == 0 ? magnumInvalidDateList : tabIndex == 1 ? totoInvalidDateList : damacaiInvalidDateList;

    if(toCheckList.isEmpty){return false;}

    for(Pair<String, DateTime> pair in toCheckList){
      if(!checkedInvalidDateList.contains(pair)){
        return false;
      }
    }

    return true;
  }

  double getThisWidth(){
    return MediaQuery.of(context).size.width*0.5;
  }

  double getThisHeight(){
    return MediaQuery.of(context).size.height*0.9;
  }

  void close(){
    Navigator.pop(context);
  }

  Future<void> addToNoDrawDates() async {

    Map<String, List<DateTime>> map = {};

    for(Pair<String, DateTime> pair in checkedInvalidDateList){
      String type = pair.first!;
      DateTime dateTime = pair.second!;

      if(!map.containsKey(type)){
        map[type] = [];
      }

      map[type]!.add(dateTime);
    }

    await DataManager.getInstance().updateAndSaveNoDrawDate(map);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("${checkedInvalidDateList.length} entry added to NoDrawDates."),
      duration: const Duration(seconds: 3),
    ));

    Navigator.pop(context);
  }
}