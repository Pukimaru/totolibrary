import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../DataManager.dart';
import '../Object/DayPrizesObj.dart';
import '../Scrapper.dart';
import '../Util/Pair.dart';
import 'ConfirmationDial.dart';
import 'LoadingDial.dart';
import 'NoticeDial.dart';

class UploadDial extends StatefulWidget{

  List<Pair<DayPrizesObj, UploadAttempt>> uploadAttemptList;
  ScrapResult? scrapResult;

  UploadDial(
    {
      super.key,
      required this.uploadAttemptList,
      this.scrapResult,
    }
  );



  @override
  State<StatefulWidget> createState() {
    return UploadDialState();
  }

}

class UploadDialState extends State<UploadDial> with TickerProviderStateMixin{

  double labelSize = 16;
  double entryHeight = 50;

  late TabController tabController;
  UploadAttempt? filterSelected;

  List<DayPrizesObj> allList = [];
  List<DayPrizesObj> cleanList = [];
  List<DayPrizesObj> dupeList = [];
  List<DayPrizesObj> conflictList = [];

  List<DayPrizesObj> checkedDayPrizesObjList = [];
  List<DayPrizesObj> extendedDayPrizesObjList = [];

  bool isAllSelected = false;

  @override
  void initState() {

    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() {
      setState(() {
        isAllSelected = getIsAllSelected();
      });
    });

    //region setup List
    for(Pair<DayPrizesObj, UploadAttempt> pair in widget.uploadAttemptList){
        DayPrizesObj dayPrizesObj = pair.first!;
        UploadAttempt uploadAttempt = pair.second!;

        switch(uploadAttempt){
          case UploadAttempt.clean:
            cleanList.add(dayPrizesObj);
            checkedDayPrizesObjList.add(dayPrizesObj);
            break;

          case UploadAttempt.dupe:
            dupeList.add(dayPrizesObj);
            break;

          case UploadAttempt.conflict:
            conflictList.add(dayPrizesObj);
            break;
        }

        allList.add(dayPrizesObj);
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
            widget.scrapResult != null ? Container(
              height: 50,
              color: widget.scrapResult == ScrapResult.Success ? Colors.green : widget.scrapResult == ScrapResult.Error ? Colors.red : Colors.yellow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Scrap Result:  ",
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: labelSize
                    ),
                  ),
                  Text(
                    widget.scrapResult == ScrapResult.Success ? "Success" : widget.scrapResult == ScrapResult.Error ? "Error" : "Cancelled",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: labelSize+1
                    ),
                  ),
                ],
              ),
            ) : const SizedBox.shrink(),
            Text("Total Selected: ${checkedDayPrizesObjList.length}", style: TextStyle(fontSize: labelSize),),
            TabBar(
                controller: tabController,
                tabs: [
                  Text("NEW (${cleanList.length})", style: TextStyle(fontSize: labelSize+1),),
                  Text("DUPE (${dupeList.length})", style: TextStyle(fontSize: labelSize+1, color: Colors.orange),),
                  Text("CONFLICT (${conflictList.length})", style: TextStyle(fontSize: labelSize+1, color: Colors.red),),
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
                        List<DayPrizesObj> targetList = tabIndex == 0 ? cleanList : tabIndex == 1 ? dupeList : conflictList;
                        if(isAllSelected){
                          for (var dayPrizesObj in targetList) {
                            if(checkedDayPrizesObjList.contains(dayPrizesObj)){
                              checkedDayPrizesObjList.remove(dayPrizesObj);
                            }
                          }
                        }else{
                            for (var dayPrizesObj in targetList) {
                              if(!checkedDayPrizesObjList.contains(dayPrizesObj)){
                                checkedDayPrizesObjList.add(dayPrizesObj);
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
                    buildListView(cleanList, UploadAttempt.clean),
                    buildListView(dupeList, UploadAttempt.dupe),
                    buildListView(conflictList, UploadAttempt.conflict),
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
                          child: const Center(child: Text("Cancel", textAlign: TextAlign.center, style: TextStyle(fontSize: 20),), ),
                        ),
                      )
                  ),
                  Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: TextButton(
                          onPressed: checkedDayPrizesObjList.isEmpty ? null : (){ upload();},
                          child: const Center(child: Text("Upload", textAlign: TextAlign.center, style: TextStyle(fontSize: 20),), ),
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

  Widget buildListView(List<DayPrizesObj> dayPrizesObjList, UploadAttempt? uploadAttempt){
    return ListView.builder(
      itemCount: dayPrizesObjList.length,
      itemBuilder: (context, index) {

          DayPrizesObj dayPrizesObj = dayPrizesObjList[index];
          uploadAttempt ??= dupeList.contains(dayPrizesObj) ? UploadAttempt.dupe : conflictList.contains(dayPrizesObj) ? UploadAttempt.conflict : UploadAttempt.clean;

          return SizedBox(
            height: extendedDayPrizesObjList.contains(dayPrizesObj) ? entryHeight*1.75 : entryHeight,
            child: GestureDetector(
              onTap: uploadAttempt == UploadAttempt.conflict ? () {
                  setState(() {
                    if(extendedDayPrizesObjList.contains(dayPrizesObj)){
                      extendedDayPrizesObjList.remove(dayPrizesObj);
                    }else{
                      extendedDayPrizesObjList.add(dayPrizesObj);
                    }
                  });
              } : null,
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                          value: checkedDayPrizesObjList.contains(dayPrizesObj),
                          onChanged: (value) {
                            setState(() {
                              if(checkedDayPrizesObjList.contains(dayPrizesObj)){
                                checkedDayPrizesObjList.remove(dayPrizesObj);
                              }else{
                                checkedDayPrizesObjList.add(dayPrizesObj);
                              }
                            });
                          },
                      ),
                      const SizedBox(width: 5,),
                      Expanded(
                          child: Text(
                              "${dayPrizesObj.getDateString(false, false)} ${dayPrizesObj.type!} ${dayPrizesObj.getPrizeString().replaceAll(RegExp(r"[a-zA-Z]"), "")}",
                              style: TextStyle(
                                fontSize: labelSize,
                                color: uploadAttempt == UploadAttempt.dupe ? Colors.orange :
                                          uploadAttempt == UploadAttempt.conflict ? Colors.red : Colors.black
                              ),
                          )
                      ),
                    ],
                  ),
                  extendedDayPrizesObjList.contains(dayPrizesObj) ? Text(
                    "existing: ${DataManager.getInstance().getDayPrizesObj(dayPrizesObj.dateTime!, dayPrizesObj.type!)!.getPrizeString().replaceAll(RegExp(r"[a-zA-Z]"), "")}",
                    style: TextStyle(
                        fontSize: labelSize-1,
                        color: Colors.black,
                        fontStyle: FontStyle.italic
                    ),
                  ) : const SizedBox.shrink()
                ],
              ),
            ),
          );
      }
    ,);
  }

  bool getIsAllSelected(){

    int tabIndex = tabController.index;

    List<DayPrizesObj> toCheckList = tabIndex == 0 ? cleanList : tabIndex == 1 ? dupeList : conflictList;

    if(toCheckList.isEmpty){return false;}

    for(DayPrizesObj dayPrizesObj in toCheckList){
      if(!checkedDayPrizesObjList.contains(dayPrizesObj)){
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

  void upload() async {

    StreamController<double> progressStreamController = StreamController.broadcast();

    //region show LoadingDial
    final _loadingDialKey = GlobalKey<LoadingDialState>();

    AlertDialog loading_dialog = AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      content: LoadingDial(
        key: _loadingDialKey,
        width: 250,
        height: 140,
        fontSize: 16,
        title: "Saving data to local storage",
        message: "Please wait...",
        progressStream: progressStreamController.stream,
        progressor: null,
      ),
    );

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return loading_dialog;
      },
    );
    //endregion

    /*await Future.delayed(const Duration(seconds: 2));

    DataManager.getInstance().uploadAndSave(checkedDayPrizesObjList).then((value){

      if(_loadingDialKey.currentState != null){
        _loadingDialKey.currentState!.close();
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Saved $value entry in local storage."),
      ));
      Navigator.pop(context);
    });*/

    List<Map<String, dynamic>> jsonList = checkedDayPrizesObjList.map<Map<String, dynamic>>((e) => e.toJson()).toList();

    ReceivePort receivePort = ReceivePort();
    var rootToken = RootIsolateToken.instance!;
    await Isolate.spawn((List<Object> args) async {

      SendPort sendPort = args[0] as SendPort;
      List<Map<String, dynamic>> jsonList = args[1] as List<Map<String, dynamic>>;
      RootIsolateToken token = args[2] as RootIsolateToken;

      BackgroundIsolateBinaryMessenger.ensureInitialized(token);

      List<DayPrizesObj> dayPrizesObjList = jsonList.map<DayPrizesObj>((e) => DayPrizesObj.fromJson(e)).toList();

      DataManager.getInstance().uploadAndSave(dayPrizesObjList, sendPort: sendPort).then((value) => sendPort.send(value.length));

      /*
      SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.reload();

      List<DayPrizesObj> savedList = [];

      for(DayPrizesObj dayPrizesObj in dayPrizesObjList){

        List<String> oriSavedPrizeStringList = sp.getStringList(dayPrizesObj.getDefaultDateString()) ?? [];

        //Remove dupe type
        oriSavedPrizeStringList.removeWhere((element) => element.contains(dayPrizesObj.type!));

        //Add into list if not similar data already exist
        if(!oriSavedPrizeStringList.contains(dayPrizesObj.getPrizeString())){
          oriSavedPrizeStringList.add(dayPrizesObj.getPrizeString());
        }

        await sp.setStringList(dayPrizesObj.getDefaultDateString(), oriSavedPrizeStringList);

        savedList.add(dayPrizesObj);
        double progress = (savedList.length.toDouble() / dayPrizesObjList.length.toDouble());

        sendPort.send(progress);
      }

      await sp.reload();
      await sp.commit();

      sendPort.send(savedList.length);*/

    }, [receivePort.sendPort, jsonList, rootToken]);

    DataManager.getInstance().addToSortedMap(checkedDayPrizesObjList, overrideDupe: true);

    receivePort.listen((message) async {

      if(message is double){

        progressStreamController.sink.add(message);

      }else if(message is int){
        if(_loadingDialKey.currentState != null){
          _loadingDialKey.currentState!.close();
        }
        progressStreamController.close();


        SharedPreferences sp = await SharedPreferences.getInstance();
        await sp.reload();

        //region Exit Notice
        final _noticeDialKey = GlobalKey<NoticeDialState>();

        AlertDialog dialog = AlertDialog(
          contentPadding: const EdgeInsets.all(0),
          insetPadding: const EdgeInsets.all(0),
          content: NoticeDial(
            key: _noticeDialKey,
            notice: "$message entry saved to local storage",
            subNotice: "App will close now to prevent rollback.\r\nPlease restart the App manually.",
            fontSize: 20,
          ),
        );

        var result = await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return dialog;
          },
        );

        if(result){
          exit(0);
        }
        //endregion

        //Navigator.pop(context);
      }

    });
  }
}