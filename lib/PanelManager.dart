import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toto/DataManager.dart';
import 'package:toto/Dialog/RNGLotteryDial.dart';
import 'package:toto/Object/PrizeObj.dart';
import 'package:toto/Widget/FreePanel.dart';

import 'Dialog/LoadingDial.dart';
import 'Dialog/NoDrawDial.dart';
import 'Dialog/NoticeDial.dart';
import 'Object/DayPrizesObj.dart';
import 'Object/RelevantDetail.dart';
import 'Scrapper.dart';
import 'Dialog/UploadDial.dart';
import 'Util/MyConst.dart';
import 'Util/Pair.dart';
import 'main.dart';

class PanelManager extends StatefulWidget{

  MainPageState mainPageState;
  Stream<RelevantDetail?> relevant_stream;
  Stream<List<Pair<String, Color>>> filter_stream;
  Stream<List<DayPrizesObj>> onSelectionChanged_stream;
  Stream<Pair<GeneralGestureType, Map<String, dynamic>>> generalGesture_stream;

  PanelManager(
    {
      super.key,
      required this.mainPageState,
      required this.relevant_stream,
      required this.filter_stream,
      required this.onSelectionChanged_stream,
      required this.generalGesture_stream,
    }
  );

  @override
  State<StatefulWidget> createState() {
      return PanelManagerState();
  }

}

class PanelManagerState extends State<PanelManager>{

  final double fieldLeftBorder = 0;
  final double fieldUpperBorder = 7;

  //Bubble
  double bubbleWidth = 50;
  double bubbleHeight = 50;
  double? bubblePositionTop;
  double? bubblePositionLeft;

  double bubbleOffSetX = 0;
  double bubbleOffSetY = 0;

  List<String> panelNameRankList = [];
  Map<String, GlobalKey<FreePanelState>> panelKeyMap = {};
  Map<String, FreePanel> panelMap = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if(bubblePositionLeft == null || bubblePositionTop == null){
          setState(() {
            bubblePositionLeft = MediaQuery.of(context).size.width-100;
            bubblePositionTop = MediaQuery.of(context).size.height-100;
          });
        }
      },);
    },);

    loadPanel().then((value){
      setState(() {

      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
            left: bubblePositionLeft,
            top: bubblePositionTop,
            width: bubbleWidth,
            height: bubbleHeight,
            child: GestureDetector(
              onTap: () {

              },
              onPanStart: (details) {

                widget.mainPageState.setShowRelevant(false);

                bubbleOffSetX = bubblePositionLeft!-details.globalPosition.dx;
                bubbleOffSetY = bubblePositionTop!-details.globalPosition.dy;
              },
              onPanUpdate: (details) {
                setState(() {

                  double newPositionX = min(details.globalPosition.dx+bubbleOffSetX, MediaQuery.of(context).size.width - bubbleWidth);
                  double newPositionY = min(details.globalPosition.dy+bubbleOffSetY, MediaQuery.of(context).size.height - bubbleHeight);

                  if(newPositionY < fieldUpperBorder){
                    return;
                  }

                  bubblePositionLeft = newPositionX;
                  bubblePositionTop = newPositionY;
                });
              },
              onPanEnd: (details) {
                widget.mainPageState.setShowRelevant(true);
              },
              child: Container(
                width: bubbleWidth,
                height: bubbleHeight,
                decoration: const BoxDecoration(
                  image: DecorationImage(image: AssetImage("assets/yuanbao.jpg")),
                  shape: BoxShape.circle,
                ),
                child: PopupMenuButton(
                  iconSize: 0,
                  itemBuilder: (context) {
                    return getMenuItemList();
                  },
                ),
              ),
            ),
        ),
        ...getSortedPanelList()
      ],
    );
  }

  List<PopupMenuItem> getMenuItemList(){
    List<PopupMenuItem> menuList = [
      PopupMenuItem(
        child: const Text("Open New Panel"),
        onTap: () {
            openPanel();
        },
      ),
    ];

    for( MapEntry<String, GlobalKey<FreePanelState>> entry in panelKeyMap.entries){

      String panelName = entry.key;
      FreePanelState? panelState = entry.value.currentState;

      if(panelState != null && panelState.isMinimize){

        menuList.add(
            PopupMenuItem(
              child: Text(panelName),
              onTap: () {
                setState(() {
                  panelState.minimize();
                });
              },
            )
        );
      }
    }

    menuList.add(
      PopupMenuItem(
        child: const Text("Play Lottery Simulator"),
        onTap: () async {
          //region open RNGLotteryDial
          final _dialKey = GlobalKey<RNGLotteryDialState>();

          AlertDialog dialog = AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            insetPadding: const EdgeInsets.all(0),
            content: RNGLotteryDial(),
          );

          await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return dialog;
            },
          );
          //endregion
        },
      )
    );

    return menuList;
  }

  bool isValidPanelName(String panelName){
    bool validFormat = RegExp(r'^[a-zA-Z\d ]+$').hasMatch(panelName);
    bool available = !panelMap.containsKey(panelName);

    return validFormat && available;
  }

  FreePanel getDefaultPanel(String panelName, GlobalKey<FreePanelState> key){

    return FreePanel(
      key: key,
      mainPageState: widget.mainPageState,
      panelManagerState: this,
      relevant_stream: widget.relevant_stream,
      filter_stream: widget.filter_stream,
      onSelectionChanged_stream: widget.onSelectionChanged_stream,
      generalGesture_stream: widget.generalGesture_stream,
      panelName: panelName,
      fontSize: 14,
      column: 3,
      panelWidth: 500,
      panelHeight: 500,
      panelPositionTop: 10,
      panelPositionLeft: 10,
      cellListString: const [],
      scrollOffset: 0,
      isMinimize: false,
      tableChartContainerJsonString: null,
      graphChartContainerJsonString: null,
    );
  }

  Future<void> minimize(String panelName, {required bool keep}) async {

    if(!panelMap.containsKey(panelName)){
      return;
    }

    FreePanelState? panelState = panelKeyMap[panelName]!.currentState;

    if(panelState != null){
        if(keep){

        }else{
          panelState.minimize();
        }
    }

    setState(() {

    });
  }

  void openPanel({String? jsonString}){

    final GlobalKey<FreePanelState> key;
    FreePanel toOpenPanel;

    if(jsonString == null){
      List<String> panelKeyList = panelMap.keys.toList();

      String newPanelName = "Panel";

      if(panelKeyList.contains(newPanelName)){
        newPanelName = "Panel(1)";
      }

      int count = 2;
      while(panelKeyList.contains(newPanelName)){
        newPanelName = newPanelName.replaceAll(RegExp(r"\d"), "").replaceAll(")", "$count)");
        count++;
      }

      key = GlobalKey(debugLabel: newPanelName);
      toOpenPanel = getDefaultPanel(newPanelName, key);

    }else{

      Map<String, dynamic> json = jsonDecode(jsonString);

      key = GlobalKey(debugLabel: json["panelName"]);
      toOpenPanel = getPanelFromJsonString(jsonString, key);
    }

    setState(() {
      panelKeyMap[toOpenPanel.panelName] = key;
      panelMap[toOpenPanel.panelName] = toOpenPanel;

      panelNameRankList.remove(toOpenPanel.panelName);
      panelNameRankList.add(toOpenPanel.panelName);

    });
  }

  Future<void> closePanel(String panelName) async {

    SharedPreferences sp = await SharedPreferences.getInstance();

    FreePanel toClosePanel = panelMap[panelName]!;

    //region remove from SharedPref
    String panelKey = "${MyConst.Key_PanelHeader}${toClosePanel.panelName}";
    await sp.remove(panelKey);

    List<String> panelKeyList = sp.getStringList(MyConst.Key_PanelKeyList) ?? [];
    panelKeyList.remove(panelKey);

    await sp.setStringList(MyConst.Key_PanelKeyList, panelKeyList);
    //endregion

    GlobalKey<FreePanelState>? panelStateKey = panelKeyMap[panelName];

    setState(() {
      panelMap.remove(panelName);
      panelKeyMap.remove(panelName);
      panelNameRankList.remove(panelName);

      if(panelStateKey != null) {
        //panelStateKey.currentState?.keepAlive = false;
      }}
    );
  }

  Future<bool> renamePanel(String oldPanelName, String newPanelName) async {
    if(panelMap.containsKey(oldPanelName) && isValidPanelName(newPanelName)){

      //Change panelName in memory
     FreePanel toRenamePanel = panelMap[oldPanelName]!;
      GlobalKey<FreePanelState> keyState = panelKeyMap[oldPanelName]!;
      int index = panelNameRankList.indexOf(oldPanelName);

      panelMap[newPanelName] = toRenamePanel;
      panelMap.remove(oldPanelName);

      panelKeyMap[newPanelName] = keyState!;
      panelKeyMap.remove(oldPanelName);

      panelNameRankList.remove(oldPanelName);
      panelNameRankList.insert(index, newPanelName);

      //Remove oldPanelKey from SP
      SharedPreferences sp = await SharedPreferences.getInstance();

      String oldPanelKey = "${MyConst.Key_PanelHeader}$oldPanelName";

      List<String> panelKeyList = sp.getStringList(MyConst.Key_PanelKeyList) ?? [];

      panelKeyList.remove(oldPanelKey);

      await sp.setStringList(MyConst.Key_PanelKeyList, panelKeyList);
      await sp.remove(oldPanelKey);

      //Update newPanelKey
      toRenamePanel.panelName = newPanelName;
      await keyState.currentState?.saveToPref();

      return true;
    }

    return false;
  }

  getPanelFromJsonString(String jsonString, GlobalKey<FreePanelState> key){

    Map<String, dynamic> json = jsonDecode(jsonString);

    return FreePanel(
      key: key,
      mainPageState: widget.mainPageState,
      panelManagerState: this,
      relevant_stream: widget.relevant_stream,
      filter_stream: widget.filter_stream,
      onSelectionChanged_stream: widget.onSelectionChanged_stream,
      generalGesture_stream: widget.generalGesture_stream,
      panelName: json["panelName"],
      fontSize: json["fontSize"],
      column: json["column"],
      panelWidth: json["panelWidth"],
      panelHeight: json["panelHeight"],
      panelPositionTop: json["panelPositionTop"],
      panelPositionLeft: json["panelPositionLeft"],
      cellListString: List<String>.from(json["cellListString"]),
      scrollOffset: json["scrollOffset"],
      isMinimize: json["isMinimize"],
      tableChartContainerJsonString: json["tableChartContainerJsonString"] ?? null,
      graphChartContainerJsonString: json["graphChartContainerJsonString"] ?? null,
    );
  }

  Future<void> loadPanel() async{
    SharedPreferences sp = await SharedPreferences.getInstance();

    List<String> panelKeysList = sp.getStringList(MyConst.Key_PanelKeyList) ?? [];

    for(String panelKey in panelKeysList){
      String? jsonString = sp.getString(panelKey);

      if(jsonString != null){
        openPanel(jsonString: jsonString);
      }
    }
  }

  List<FreePanel> getSortedPanelList(){
    List<FreePanel> sortedPanelList = panelNameRankList.map<FreePanel>(
        (panelName){
          return panelMap[panelName]!;
        }
    ).toList();

    return sortedPanelList;
  }

  bool bringUpPanel(String panelName){
    if(panelNameRankList.indexOf(panelName) != panelNameRankList.length-1){
      setState(() {
        panelNameRankList.remove(panelName);
        panelNameRankList.add(panelName);
      });

      return true;
    }

    return false;
  }

}