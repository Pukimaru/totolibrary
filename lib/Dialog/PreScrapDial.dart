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

class PreScrapDial extends StatefulWidget{

  Map<String, List<DateTime>> missingEntryMap;

  PreScrapDial(
      {
        super.key,
        required this.missingEntryMap,
      }
      );



  @override
  State<StatefulWidget> createState() {
    return PreScrapDialState();
  }

}

class PreScrapDialState extends State<PreScrapDial> with TickerProviderStateMixin{

  double labelSize = 16;
  double entryHeight = 50;

  late TabController tabController;
  UploadAttempt? filterSelected;

  List<Pair<String, DateTime>> magnumMissingDateList = [];
  List<Pair<String, DateTime>> totoMissingDateList = [];
  List<Pair<String, DateTime>> damacaiMissingDateList = [];

  List<Pair<String, DateTime>> checkedMissingDateList = [];

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
    for(String type in widget.missingEntryMap.keys){
      switch(type){
        case PrizeObj.TYPE_MAGNUM4D:
          magnumMissingDateList = widget.missingEntryMap[type]!.map<Pair<String, DateTime>>(
            (e){
              Pair<String, DateTime> pair = Pair(PrizeObj.TYPE_MAGNUM4D, e);

              if(!isInNoDrawDate(pair)){
                checkedMissingDateList.add(pair);
              }

              return pair;
            }
          ).toList();
          break;

        case PrizeObj.TYPE_TOTO:
          totoMissingDateList = widget.missingEntryMap[type]!.map<Pair<String, DateTime>>(
              (e){
                Pair<String, DateTime> pair = Pair(PrizeObj.TYPE_TOTO, e);

                if(!isInNoDrawDate(pair)){
                  checkedMissingDateList.add(pair);
                }

                return pair;
              }
          ).toList();
          break;

        case PrizeObj.TYPE_DAMACAI:
          damacaiMissingDateList = widget.missingEntryMap[type]!.map<Pair<String, DateTime>>(
            (e){
              Pair<String, DateTime> pair = Pair(PrizeObj.TYPE_DAMACAI, e);

              if(!isInNoDrawDate(pair)){
                checkedMissingDateList.add(pair);
              }

              return pair;
            }
          ).toList();
          break;
      }
    }

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
                "Scrapping For Missing Entries",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500
                ),
              ),
              const Text(
                "Please select the dates that you wish to scrap from the internet.\r\nBelow are the list of missing entries:",
                maxLines: 2,
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.deepPurple
                ),
              ),
              const Text(
                "Red lines are entries marked as NoDrawDates.",
                maxLines: 1,
                style: TextStyle(
                    fontSize: 17,
                    color: Colors.redAccent
                ),
              ),
              const SizedBox(height: 5,),
              Text("Total Selected: ${checkedMissingDateList.length}", style: TextStyle(fontSize: labelSize),),
              TabBar(
                  controller: tabController,
                  tabs: [
                    Text("MAGNUM (${magnumMissingDateList.length})", style: TextStyle(fontSize: labelSize+1),),
                    Text("TOTO (${totoMissingDateList.length})", style: TextStyle(fontSize: labelSize+1),),
                    Text("DAMACAI (${damacaiMissingDateList.length})", style: TextStyle(fontSize: labelSize+1),),
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
                          List<Pair<String, DateTime>> targetList = tabIndex == 0 ? magnumMissingDateList : tabIndex == 1 ? totoMissingDateList : damacaiMissingDateList;
                          if(isAllSelected){
                            for (Pair<String, DateTime> dateTimeTypePair in targetList) {
                              if(checkedMissingDateList.contains(dateTimeTypePair)){
                                checkedMissingDateList.remove(dateTimeTypePair);
                              }
                            }
                          }else{
                            for (Pair<String, DateTime> dateTimeTypePair in targetList) {
                              if(!checkedMissingDateList.contains(dateTimeTypePair)){
                                checkedMissingDateList.add(dateTimeTypePair);
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
                      buildListView(magnumMissingDateList),
                      buildListView(totoMissingDateList),
                      buildListView(damacaiMissingDateList),
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
                            onPressed: checkedMissingDateList.isEmpty ? null : () async { await submitToScrapMap();},
                            child: const Center(child: Text("Scrap", textAlign: TextAlign.center, style: TextStyle(fontSize: 20),), ),
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
                    value: checkedMissingDateList.contains(dateTypePair),
                    onChanged: (value) {
                      setState(() {
                        if(checkedMissingDateList.contains(dateTypePair)){
                          checkedMissingDateList.remove(dateTypePair);
                        }else{
                          checkedMissingDateList.add(dateTypePair);
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
                              color: isInNoDrawDate(dateTypePair) ? Colors.red : Colors.black,
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

    List<Pair<String, DateTime>> toCheckList = tabIndex == 0 ? magnumMissingDateList : tabIndex == 1 ? totoMissingDateList : damacaiMissingDateList;

    if(toCheckList.isEmpty){return false;}

    for(Pair<String, DateTime> pair in toCheckList){
      if(!checkedMissingDateList.contains(pair)){
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

  bool isInNoDrawDate(Pair<String, DateTime> pair){
    String type = pair.first!;
    DateTime dateTime = pair.second!;

    return DataManager.getInstance().NoDrawDateMap.containsKey(type) && DataManager.getInstance().NoDrawDateMap[type]!.contains(dateTime);

  }

  void close(){
    Navigator.pop(context);
  }

  Future<void> submitToScrapMap() async {

    Map<String, List<DateTime>> toScrapMap = {};

    for(Pair<String, DateTime> pair in checkedMissingDateList){
      String type = pair.first!;
      DateTime dateTime = pair.second!;

      if(!toScrapMap.containsKey(type)){
        toScrapMap[type] = [];
      }

      if(!toScrapMap[type]!.contains(dateTime)){
        toScrapMap[type]!.add(dateTime);
      }
    }

    if(toScrapMap.isNotEmpty){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Start Scrapping (Total Entry: ${checkedMissingDateList.length}), Please keep the browser on top at all times to ensure smooth scrapping"),
        duration: const Duration(seconds: 10),
      ));

      Navigator.pop(context, toScrapMap);
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please select the dates you wish to scrap. Currently Dates selected: 0"),
        duration: Duration(seconds: 3),
      ));
    }



  }
}