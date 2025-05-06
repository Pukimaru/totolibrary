import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toto/DataManager.dart';
import 'package:toto/Dialog/PreScrapDial.dart';
import 'package:toto/ExcelManager.dart';
import 'package:toto/Object/DayPrizesObj.dart';
import 'package:toto/Object/RelevantDetail.dart';
import 'package:toto/PanelManager.dart';
import 'package:toto/SelectionBox.dart';
import 'package:toto/Util/MyConst.dart';
import 'package:toto/Util/MyUtil.dart';
import 'package:toto/Widget/FreePanel.dart';
import 'package:toto/Widget/GlowContainer.dart';
import 'package:toto/Window.dart';

import 'Dialog/ConfirmationDial.dart';
import 'Dialog/LoadingDial.dart';
import 'Dialog/NoDrawDial.dart';
import 'Dialog/NoticeDial.dart';
import 'Dialog/ScrapInfoDial.dart';
import 'Dialog/UploadDial.dart';
import 'Dialog/VerifyRangeDial.dart';
import 'Scrapper.dart';
import 'Util/CheckPatch.dart';
import 'Util/Pair.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> with TickerProviderStateMixin {

  double labelFontSize = 16;
  double tabTitleWidth = 150;
  Map<String, GlobalKey<WindowState>> windowStateKeyMap = {};
  Map<String, Window> windowMap = {};

  Window? editNameWindow;
  TextEditingController editNameTEC = TextEditingController();
  FocusNode editNameFN = FocusNode();

  List<Pair<String, Color>> filterStringColorPairList = [];
  List<DayPrizesObj> selectedDayPrizesObj = []; //Selected by means of drag box

  late StreamController<RelevantDetail?> relevant_streamController;
  late StreamController<List<Pair<String, Color>>> filter_streamController;
  late StreamController<List<DayPrizesObj>> onSelectionChanged_streamController;
  late StreamController<Pair<SelectionStage, Rect?>> selection_streamController;
  late StreamController<Pair<GeneralGestureType, Map<String, dynamic>>> generalGesture_streamController;

  late TabController tabController;

  bool _showRelevant = true;

  GlobalKey<GlowContainerState> glowContainerKey = GlobalKey();

  @override
  void initState() {

    super.initState();

    () async {await DataManager.getInstance().load().then(
            (value) => setState(() {
            })
    );}.call();

    //loadFromPref
      loadWindow().then((value) =>
        setState(() {
          if(hasNoActiveWindow()){

            () async {
              print("open window");
              await openWindow(false);
            }.call();

          }
        })
      );
    //endRegion

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        await handleVersionUpdate();
        await handleScrap();

        if(getAbsoMissingEntryCount() > 0){
          setGlowContainer(true);
        }
        Timer.periodic(const Duration(minutes: 60), (timer) {
          if(getAbsoMissingEntryCount() > 0){
              setGlowContainer(true);
          }
        });
    },);

    relevant_streamController = StreamController.broadcast();
    filter_streamController = StreamController.broadcast();
    onSelectionChanged_streamController = StreamController.broadcast();
    selection_streamController = StreamController.broadcast();
    generalGesture_streamController = StreamController.broadcast();
  }

  @override
  void dispose() {
    relevant_streamController.close();
    filter_streamController.close();
    onSelectionChanged_streamController.close();
    selection_streamController.close();
    generalGesture_streamController.close();

    tabController.dispose();
    // TODO: implement dispose

    Scrapper.getInstance().stopScrapProgressStreamController();
    Scrapper.getInstance().stopScrapDetailStreamController();
    DataManager.getInstance().closeSaveProgressStreamController();

    super.dispose();
  }

  Offset? startSelectionPoint;
  Offset? endSelectionPoint;

  @override
  Widget build(BuildContext context) {

    tabController = TabController(
        length: getWindowCount(),
        vsync: this
    );
    tabController.addListener(() {
      String windowName = getSortedWindowList()[tabController.index].windowName;
      WindowState? windowState = windowStateKeyMap[windowName]?.currentState;

      if(windowState != null){
        windowState.resume();
      }
    });

    return Scaffold(
      body: DropTarget(
        onDragDone: (details) async {
            await handleUpload(details);
        },
        onDragEntered: (details) {
        },
        enable: true,

        child: Stack(
          children: [
            Center(
              child: DefaultTabController(
                length: getWindowCount(),
                child: Column(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height *0.05,
                      child: Row(
                        children: [
                          hasNoActiveWindow() ? const SizedBox.shrink() : SizedBox(
                            width: min((tabTitleWidth+25)*getWindowCount().toDouble(), MediaQuery.of(context).size.width - (50*3)),
                            child: TabBar(
                              controller: tabController,
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              tabs: getSortedWindowList().map(
                                    (e) => SizedBox(
                                      width: tabTitleWidth,
                                      child: Row(
                                        children: [
                                          SizedBox(
                                              width: 100,
                                              child: editNameWindow == e ? TextField(
                                                controller: editNameTEC,
                                                focusNode: editNameFN,
                                                decoration: const InputDecoration(
                                                  border: InputBorder.none,
                                                ),
                                                style: TextStyle(
                                                  fontSize: labelFontSize-2,
                                                ),
                                                onTap: () {
                                                    editNameFN.requestFocus();
                                                },
                                                autofocus: true,
                                                onEditingComplete: () async {
                                                    bool success = await renameWindow(e.windowName, editNameTEC.text);

                                                    if(!success){
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                        content: Text("Invalid Window Name!"),
                                                      ));
                                                    }

                                                    setState(() {
                                                      editNameWindow = null;
                                                    });
                                                },
                                                onTapOutside: (event) async {
                                                  bool success = await renameWindow(e.windowName, editNameTEC.text);

                                                  if(!success){
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                      content: Text("Invalid Window Name!"),
                                                    ));
                                                  }

                                                  setState(() {
                                                    editNameWindow = null;
                                                  });
                                                },
                                              ) : GestureDetector(
                                                onDoubleTap: () {
                                                  setState(() {
                                                    editNameWindow = e;
                                                    editNameTEC.text = e.windowName;
                                                  });
                                                },
                                                child: Text(
                                                    e.windowName,
                                                    overflow: TextOverflow.ellipsis,
                                                ),
                                              )
                                          ),
                                          SizedBox(
                                            height: 35,
                                            width: 30,
                                            child: IconButton(
                                              constraints: BoxConstraints.tight(const Size.fromWidth(30)),
                                              onPressed: () async {
                                                await closeWindow(e.windowName);
                                              },
                                              icon: const Center(
                                                child: Icon(
                                                  Icons.close,
                                                  size: 15,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                              ).toList(),
                            )
                          ),
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: IconButton(
                              onPressed: () async {
                                await openWindow(false);
                              },
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                CupertinoIcons.plus,
                                color: Colors.grey,
                                size: 25,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 45,
                            height: 45,
                            child: IconButton(
                              onPressed: () async {
                                await handleCloseAllWindow();
                              },
                              icon: Icon(
                                CupertinoIcons.xmark_square_fill,
                                color: Colors.red,
                              )),
                          ),
                          const Expanded(child: SizedBox.shrink()),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child:  IconButton(
                              onPressed: () async {
                                await handleVerifyEntries();
                              },
                              icon: const Icon(
                                Icons.verified_sharp,
                                color: Colors.grey,
                                size: 25,
                              ),
                            )
                          ),
                          GlowContainer(
                            key: glowContainerKey,
                            width: 40,
                            height: 40,
                            boxShape: BoxShape.circle,
                            glow: false,
                            child: IconButton(
                              onPressed: () async {
                                await handleScrap();
                              },
                              icon: const Icon(
                                Icons.system_update_alt,
                                size: 25,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    hasNoActiveWindow() ? Container(
                      height: MediaQuery.of(context).size.height*0.95,
                      color: Colors.grey,
                      child: const Center(
                        child: Text(
                          "Empty\r\n\r\nOpen a new window to begin.",
                          style: TextStyle(
                            fontSize: 35
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ) : SizedBox(
                      height: MediaQuery.of(context).size.height*0.95,
                      child: TabBarView(
                          controller: tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: getSortedWindowList(),
                      ),
                    )
                  ],
                ),
              )
            ),
            /*FreePanel(
              mainPageState: this,
              relevant_stream: relevant_streamController.stream,
              onSelectionChanged_stream: onSelectionChanged_streamController.stream,
              filter_stream: filter_streamController.stream,
              generalGesture_stream: generalGesture_streamController.stream,
            ),*/
            PanelManager(
              mainPageState: this,
              relevant_stream: relevant_streamController.stream,
              onSelectionChanged_stream: onSelectionChanged_streamController.stream,
              filter_stream: filter_streamController.stream,
              generalGesture_stream: generalGesture_streamController.stream,
            ),
          ],
        ),
      ),
    );
  }

  bool verifyAndSetFilter(String input){
      return false;
  }

  int getWindowCount(){
    return windowMap.length;
  }

  bool isValidWindowName(String windowName){
      bool validFormat = RegExp(r'^[a-zA-Z\d]+$').hasMatch(windowName);
      bool available = !windowMap.containsKey(windowName);

      return validFormat && available;
  }

  List<Window> getSortedWindowList(){
      List<Window> sortedWindowList = List<Window>.from( windowMap.values );

      sortedWindowList.sort(
          (a, b) {
            return a.windowIndex - b.windowIndex;
          },
      );

      for(int i = 0; i < sortedWindowList.length; i++){
        sortedWindowList[i].windowIndex = i;
      }

      return sortedWindowList;
  }

  bool hasNoActiveWindow(){
      return windowMap.isEmpty;
  }

  Future<void> loadWindow() async{
      SharedPreferences sp = await SharedPreferences.getInstance();

      List<String> windowKeysList = sp.getStringList(MyConst.Key_WindowKeyList) ?? [];

      for(String windowKey in windowKeysList){
          String? jsonString = sp.getString(windowKey);

          if(jsonString != null){
              await openWindow(true, jsonString: jsonString);
          }
      }
  }

  Future<void> openWindow(bool firstLoad, {String? jsonString}) async {

      SharedPreferences sp = await SharedPreferences.getInstance();
      final GlobalKey<WindowState> key;
      Window toOpenWindow;

      if(jsonString == null){
        List<String> windowKeyList = firstLoad ? sp.getStringList(MyConst.Key_WindowKeyList) ?? [] : windowMap.keys.toList();

        String newWindowName = "New Window";

        if(windowKeyList.contains(newWindowName)){
          newWindowName = "New Window (1)";
        }

        int count = 2;
        while(windowKeyList.contains(newWindowName)){
          newWindowName = newWindowName.replaceAll(RegExp(r"\d"), "").replaceAll(")", "$count)");
          count++;
        }

        key = GlobalKey(debugLabel: newWindowName);
        toOpenWindow = getDefaultWindow(newWindowName, key, windowMap.length-1);

      }else{

        Map<String, dynamic> json = jsonDecode(jsonString);

        key = GlobalKey(debugLabel: json["windowName"]);
        toOpenWindow = getWindowFromJsonString(windowMap.length-1, jsonString, key);
      }

      setState(() {
          windowStateKeyMap[toOpenWindow.windowName] = key;
          windowMap[toOpenWindow.windowName] = toOpenWindow;
      });

      if(!firstLoad){
        Future.delayed(
            const Duration(milliseconds: 200),
            () {
              try{
                int toGoIndex = windowMap.length-1;
                tabController.animateTo(toGoIndex);

              }catch(e){
                  print("fail to animate to new tab");
              }
            },
        );
      }
  }

  Future<void> closeWindow(String windowName) async {

      SharedPreferences sp = await SharedPreferences.getInstance();

      Window toCloseWindow = windowMap[windowName]!;

      //region remove from SharedPref
      String windowKey = "${MyConst.Key_WindowHeader}${toCloseWindow.windowName}";
      await sp.remove(windowKey);

      List<String> windowKeyList = sp.getStringList(MyConst.Key_WindowKeyList) ?? [];
      windowKeyList.remove(windowKey);

      await sp.setStringList(MyConst.Key_WindowKeyList, windowKeyList);
      //endregion

      GlobalKey<WindowState>? windowStateKey = windowStateKeyMap[windowName];

      setState(() {
        windowMap.remove(windowName);
        if(windowStateKey != null) {
          windowStateKey.currentState?.keepAlive = false;
        }}
      );
  }

  Future<bool> renameWindow(String oldWindowName, String newWindowName) async {
      if(windowMap.containsKey(oldWindowName) && isValidWindowName(newWindowName)){

        //Change windowName in memory
        Window toRenameWindow = windowMap[oldWindowName]!;

        GlobalKey<WindowState> keyState = windowStateKeyMap[oldWindowName]!;

        windowMap[newWindowName] = toRenameWindow;
        windowMap.remove(oldWindowName);

        windowStateKeyMap[newWindowName] = keyState;
        windowStateKeyMap.remove(oldWindowName);

        //Remove oldWindowKey from SP
        SharedPreferences sp = await SharedPreferences.getInstance();

        String oldWindowKey = "${MyConst.Key_WindowHeader}$oldWindowName";

        List<String> windowKeyList = sp.getStringList(MyConst.Key_WindowKeyList) ?? [];

        windowKeyList.remove(oldWindowKey);

        await sp.setStringList(MyConst.Key_WindowKeyList, windowKeyList);
        await sp.remove(oldWindowKey);

        //Update newWindowKey
        //if(keyState != null){
            toRenameWindow.windowName = newWindowName;
            await keyState.currentState?.saveToPref();
        //}

        return true;
      }

      return false;
  }

  Future<void> handleUpload(DropDoneDetails details) async {

    List<DayPrizesObj> dayPrizesObjList = [];

    try{
      for(var file in details.files){
        String path = file.path;
        String extension = path.split(".").last;
        if(extension != "xlsx"){
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Non-compatible File detected! Only xlsx files are allowed."),
            ));
            return;
        }

        dayPrizesObjList.addAll(await ExcelManager.extract(path));
      }

      List<Pair<DayPrizesObj, UploadAttempt>> uploadAttemptList = DataManager.getInstance().getUploadAttemptList(dayPrizesObjList);

      final _uploadDialKey = GlobalKey<UploadDialState>();

      AlertDialog dialog = AlertDialog(
        contentPadding: const EdgeInsets.all(0),
        insetPadding: const EdgeInsets.all(0),
        content: UploadDial(
          key: _uploadDialKey,
          uploadAttemptList: uploadAttemptList,
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
          //DataManager.addToSortedMap(toUploadDayPrizesObjList, overrideDupe: true);
          //DataManager.save();
      }

    }catch(e, stacktrace){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("There is an error upload files.\r\n$stacktrace"),
          duration: const Duration(seconds: 20),
        ));
    }

  }

  Future<void> handleScrap() async {

    //region check if internet connection [return if no internet]
    if(await CheckPatch.getInstance().getLatestVersion() == -1){
      setGlowContainer(false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to verify Data due to no network connection"),
        duration: Duration(seconds: 3),
      ));
      return;
    }
    //endregion

    int absoMissingEntryCount = getAbsoMissingEntryCount();

    if(absoMissingEntryCount == 0){
      setGlowContainer(false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Data are already up-to-date"),
        duration: Duration(seconds: 3),
      ));
      return;
    }

    //region ConfirmationDial
    final _confirmationDialKey = GlobalKey<ConfirmationDialState>();

    AlertDialog confirmation_dialog = AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      content: ConfirmationDial(
        key: _confirmationDialKey,
        fontSize: 20,
        question: "Data Not Up-To-Date",
        subQuestion: "$absoMissingEntryCount missing entries detected.\r\nDo you want to scrap them from the internet?",
      ),
    );

    var accept = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return confirmation_dialog;
      },
    );
    //endregion

    if(!accept){
      return;
    }

    //region PreScrapDial
    final _preScrapDialKey = GlobalKey<PreScrapDialState>();

    AlertDialog prescrap_dialog = AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      content: PreScrapDial(
        key: _preScrapDialKey,
        missingEntryMap: DataManager.getInstance().getMissingEntry(),
      ),
    );

    Map<String, List<DateTime>>? toScrapMap = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return prescrap_dialog;
      },
    );
    //endregion

    if(toScrapMap != null){
      //region ScrapInfoDial
      final _scrapInfoDialKey = GlobalKey<ScrapInfoDialState>();

      AlertDialog scrapInfo_dialog = AlertDialog(
        contentPadding: const EdgeInsets.all(0),
        insetPadding: const EdgeInsets.all(0),
        content: ScrapInfoDial(
          key: _scrapInfoDialKey,
          fontSize: 16,
          progressStream: Scrapper.getInstance().getScrapProgressStream(),
          scrapStream: Scrapper.getInstance().getScrapDetailStream(),
          progressor: Scrapper.getInstance(),
        ),
      );

      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return scrapInfo_dialog;
        },
      );
      //endregion

      //region Start Scrapping
      Scrapper.getInstance().scrapAll(toScrapMap).then((scrapDetail) async {

        if(_scrapInfoDialKey.currentState != null){
          _scrapInfoDialKey.currentState!.close();
        }

        ScrapResult scrapResult = scrapDetail.scrapResult;
        List<DayPrizesObj> dayPrizesObjList = scrapDetail.dayPrizesObjList;

        String message = scrapResult == ScrapResult.Success ? "Scrap Completed Successfully" :
        scrapResult == ScrapResult.Error ? "An error has occur during scraping progress" :
        "Scrap Progress Canceled Prematurely";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ));

        //region handle invalidDates
        if(DataManager.getInstance().InvalidDateStringMap.isNotEmpty){
          final _noDrawDialKey = GlobalKey<NoDrawDialState>();

          AlertDialog dialog = AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            insetPadding: const EdgeInsets.all(0),
            content: NoDrawDial(
              key: _noDrawDialKey,
              invalidDateMap: DataManager.getInstance().InvalidDateStringMap,
            ),
          );

          var result = await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return dialog;
            },
          );

          DataManager.getInstance().clearInvalidDate();
        }
        //endregion

        if(dayPrizesObjList.isNotEmpty){
          List<Pair<DayPrizesObj, UploadAttempt>> uploadAttemptList = DataManager.getInstance().getUploadAttemptList(dayPrizesObjList);

          final _uploadDialKey = GlobalKey<UploadDialState>();

          AlertDialog dialog = AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            insetPadding: const EdgeInsets.all(0),
            content: UploadDial(
              key: _uploadDialKey,
              uploadAttemptList: uploadAttemptList,
              scrapResult: scrapDetail.scrapResult,
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
            //DataManager.addToSortedMap(toUploadDayPrizesObjList, overrideDupe: true);
            //DataManager.save();
          }
        }else{
          //region show notice no entry found
          final _noticeDialKey = GlobalKey<NoticeDialState>();

          AlertDialog dialog = AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            insetPadding: const EdgeInsets.all(0),
            content: NoticeDial(
              key: _noticeDialKey,
              notice: "Scrapping completed.",
              subNotice: "No new entry found.",
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
          //endregion
        }
      }
      );
      //List<DayPrizesObj> dayPrizesObjList = await Scrapper.scrapDAMACAI(DataManager.getMissingEntry()[PrizeObj.TYPE_DAMACAI]!);

      //endregion
    }

  }

  Future<void> handleVerifyEntries() async {
    //region check if internet connection [return if no internet]
    if(await CheckPatch.getInstance().getLatestVersion() == -1){
      setGlowContainer(false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to verify Data due to no network connection"),
        duration: Duration(seconds: 3),
      ));
      return;
    }
    //endregion

    //region ConfirmationDial
    final _confirmationDialKey = GlobalKey<ConfirmationDialState>();

    AlertDialog confirmation_dialog = AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      content: ConfirmationDial(
        key: _confirmationDialKey,
        fontSize: 20,
        question: "Verify Entries Request",
        subQuestion: "Are you sure you want to verify your entries with the web?\r\nThis process will take around 45 minutes to complete\r\nGood Internet Connection required, you are advised to run this process in foreground",
      ),
    );

    var accept = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return confirmation_dialog;
      },
    );
    //endregion

    if(!accept){
      return;
    }

    //region VerifyRangeDial
    final _verifyRangeDialKey = GlobalKey<VerifyRangeDialState>();

    AlertDialog verifyRange_dialog = AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      content: VerifyRangeDial(
        key: _verifyRangeDialKey,
        fontSize: 20,
      ),
    );

    var startEndPair = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return verifyRange_dialog;
      },
    );
    //endregion

    if(startEndPair == null){
      return;
    }

    //region ScrapInfoDial
    final _scrapInfoDialKey = GlobalKey<ScrapInfoDialState>();

    AlertDialog scrapInfo_dialog = AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      content: ScrapInfoDial(
        key: _scrapInfoDialKey,
        fontSize: 16,
        progressStream: Scrapper.getInstance().getScrapProgressStream(),
        scrapStream: Scrapper.getInstance().getScrapDetailStream(),
        progressor: Scrapper.getInstance(),
      ),
    );

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return scrapInfo_dialog;
      },
    );
    //endregion

    //region Start Scrapping
    Scrapper.getInstance().scrapAll(
        DataManager.getInstance().getMissingEntry(getAllDateRegardless: true, startYear: startEndPair.first, terminalYear: startEndPair.second)
    ).then((scrapDetail) async {

        if(_scrapInfoDialKey.currentState != null){
          _scrapInfoDialKey.currentState!.close();
        }

        ScrapResult scrapResult = scrapDetail.scrapResult;
        List<DayPrizesObj> dayPrizesObjList = scrapDetail.dayPrizesObjList;

        String message = scrapResult == ScrapResult.Success ? "Scrap Completed Successfully" :
        scrapResult == ScrapResult.Error ? "An error has occur during scraping progress" :
        "Scrap Progress Canceled Prematurely";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ));

        //region handle invalidDates
        if(DataManager.getInstance().InvalidDateStringMap.isNotEmpty){
          final _noDrawDialKey = GlobalKey<NoDrawDialState>();

          AlertDialog dialog = AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            insetPadding: const EdgeInsets.all(0),
            content: NoDrawDial(
              key: _noDrawDialKey,
              invalidDateMap: DataManager.getInstance().InvalidDateStringMap,
            ),
          );

          var result = await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return dialog;
            },
          );

          DataManager.getInstance().clearInvalidDate();
        }
        //endregion

        if(dayPrizesObjList.isNotEmpty){
          List<Pair<DayPrizesObj, UploadAttempt>> uploadAttemptList = DataManager.getInstance().getUploadAttemptList(dayPrizesObjList);

          final _uploadDialKey = GlobalKey<UploadDialState>();

          AlertDialog dialog = AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            insetPadding: const EdgeInsets.all(0),
            content: UploadDial(
              key: _uploadDialKey,
              uploadAttemptList: uploadAttemptList,
              scrapResult: scrapDetail.scrapResult,
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
            //DataManager.addToSortedMap(toUploadDayPrizesObjList, overrideDupe: true);
            //DataManager.save();
          }
        }else{
          //region show notice no entry found
          final _noticeDialKey = GlobalKey<NoticeDialState>();

          AlertDialog dialog = AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            insetPadding: const EdgeInsets.all(0),
            content: NoticeDial(
              key: _noticeDialKey,
              notice: "Scrapping completed.",
              subNotice: "No new entry found.",
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
          //endregion
        }

    });
    //List<DayPrizesObj> dayPrizesObjList = await Scrapper.scrapDAMACAI(DataManager.getMissingEntry()[PrizeObj.TYPE_DAMACAI]!);

    //endregion

  }

  Future<void> handleVersionUpdate() async {

    bool? requireUpdate = await CheckPatch.getInstance().requireUpdate();

    if(requireUpdate == null){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to check for latest version due to no network connection."),
      ));
      return;
    }

    if(requireUpdate){
        String latestVersion = (await CheckPatch.getInstance().getLatestVersion()).toString();
        String currentVersion = CheckPatch.getInstance().getCurrentVersion().toString();

        //region ConfirmationDial
        final _confirmationDialKey = GlobalKey<ConfirmationDialState>();

        AlertDialog confirmation_dialog = AlertDialog(
          contentPadding: const EdgeInsets.all(0),
          insetPadding: const EdgeInsets.all(0),
          content: ConfirmationDial(
            key: _confirmationDialKey,
            fontSize: 20,
            question: "Outdated Version",
            subQuestion: "A higher version available, do you wish to update to the latest version?\r\nApplication will be restart automatically after the update.\r\n\r\nYour version: ${currentVersion}v, Latest version: ${latestVersion}v",
          ),
        );

        var accept = await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return confirmation_dialog;
          },
        );

        if(accept){

          try{
            final patcherPath = "${Directory.current.parent.path}\\TotoPatcher.exe";

            Directory.current = Directory.current.parent;
            final process = await Process.start(patcherPath, []);

            // Wait for the process to complete
            await process.exitCode;

            // Terminate the app
            exit(0);

          }catch(e, ex){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Failed to launch the TotoPatcher.exe.\r\nPlease run the app as administration and try again or Run TotoPatcher.exe manually."), duration: const Duration(seconds: 10),
            ));
          }

        }
      //endregion
    }
  }

  Future<void> handleCloseAllWindow() async {

    //region ConfirmationDial
    final _confirmationDialKey = GlobalKey<ConfirmationDialState>();

    AlertDialog confirmation_dialog = AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      content: ConfirmationDial(
        key: _confirmationDialKey,
        fontSize: 20,
        question: "Close all active tabs?",
        subQuestion: "Are you sure you want to close all active tab(s)?\r\nClosed tab(s) cannot be restore.",
      ),
    );

    var accept = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return confirmation_dialog;
      },
    );
    //endregion

    if(!accept){
      return;
    }

    List<String> windowNameList = windowMap.keys.toList();
    for(String windowName in windowNameList){
      await closeWindow(windowName);
    }
  }

  int getAbsoMissingEntryCount(){
    /*Map<String, List<DateTime>> missingEntryMap = DataManager.getInstance().getMissingEntry();
    int missingEntryCount = 0;
    for(List<DateTime> dateTimeList in missingEntryMap.values){
      missingEntryCount += dateTimeList.length;
    }

    Map<String, List<DateTime>> noDrawDateMap = Map<String, List<DateTime>>.from(DataManager.getInstance().NoDrawDateMap);
    int noDrawDateCount = 0;
    for(List<DateTime> dateTimeList in noDrawDateMap.values){
      noDrawDateCount += dateTimeList.length;
    }

    print(
      "$missingEntryCount vs $noDrawDateCount"
    );*/
    Map<String, List<DateTime>> missingEntryMap = DataManager.getInstance().getMissingEntry(ignoreNoDrawDates: true);
    int missingEntryCount = 0;
    for(List<DateTime> dateTimeList in missingEntryMap.values){
      missingEntryCount += dateTimeList.length;
    }
    print("missingEntry: $missingEntryCount");

    return missingEntryCount;//max(0, missingEntryCount-noDrawDateCount);
  }

  Window getDefaultWindow(String windowName, GlobalKey<WindowState> key, int index){

      return Window(
        key: key,
        mainPageState: this,
        windowName: windowName,
        windowIndex: index, //Start from 0
        year: null, yearMin: 2000, yearMax: 2024,
        month: null, monthMin: null, monthMax: null,
        day: null, dayMin: null, dayMax: null,
        row: 7,
        column: 5,
        fontSize: 13,
        show6D: false,
        drawDayTypeString: DrawDayType.AllDraw.name.toString(),
        magnumActive: true,
        totoActive: false,
        damacaiActive: false,
        lockedStringList: [], filterStringFormulaList: [], filterBoolFormulaList: [],
        relevant_stream: relevant_streamController.stream,
        onSelectionChanged_stream: onSelectionChanged_streamController.stream,
        filter_stream: filter_streamController.stream,
        generalGesture_stream: generalGesture_streamController.stream,
    );
  }

  Window getWindowFromJsonString(int windowIndex, String jsonString, GlobalKey<WindowState> key){

      Map<String, dynamic> json = jsonDecode(jsonString);

      return Window(
          key: key,
          mainPageState: this,
          windowIndex: json["windowIndex"], //Start from 0
          windowName: json["windowName"],
          year: json["year"], yearMin: json["yearMin"], yearMax: json["yearMax"],
          month: json["month"], monthMin: json["monthMin"], monthMax: json["monthMax"],
          day: json["day"], dayMin: json["dayMin"], dayMax: json["dayMax"], row: json["row"], column: json["column"],
          fontSize: json["fontSize"],
          show6D: json["show6D"] ?? false,
          drawDayTypeString: json["drawDayTypeString"] ?? DrawDayType.AllDraw.name.toString(),
          magnumActive: json["magnumActive"],
          totoActive: json["totoActive"],
          damacaiActive: json["damacaiActive"],
          lockedStringList: List<String>.from(json["lockedStringList"]),
          filterStringFormulaList: List<String>.from(json["filterStringFormulaList"]),
          filterBoolFormulaList: List<bool>.from(json["filterBoolFormulaList"]),
          relevant_stream: relevant_streamController.stream,
          filter_stream: filter_streamController.stream,
          onSelectionChanged_stream: onSelectionChanged_streamController.stream,
          generalGesture_stream: generalGesture_streamController.stream,
      );
  }

  void setShowRelevant(bool on){
    _showRelevant = on;
  }

  void updateRelevantDetail({String? prizeHovered, DayPrizesObj? dayPrizesObjHovered, Offset? hoverPosition, bool? turnOn}){
    if(_showRelevant){
      relevant_streamController.sink.add(
        prizeHovered == null ? null :
        RelevantDetail(
            prizeHovered: prizeHovered,
            dayPrizesObjHovered: dayPrizesObjHovered!,
            hoverPosition: hoverPosition!
        )
      );
    }
  }

  void updateFilterString(List<Pair<String, Color>> _filterStringColorPairList){
    filterStringColorPairList = _filterStringColorPairList;
    filter_streamController.sink.add(_filterStringColorPairList);
  }

  List<Pair<String, Color>> getFilterStringColorPairList(){
      return filterStringColorPairList;
  }

  void clearSelectionList(){
    selectedDayPrizesObj.clear();
    onSelectionChanged_streamController.sink.add(selectedDayPrizesObj);
  }

  void addToSelectionList(DayPrizesObj dayPrizesObj){
      selectedDayPrizesObj.add(dayPrizesObj);
      onSelectionChanged_streamController.sink.add(selectedDayPrizesObj);

      String clipboardText = selectedDayPrizesObj.map((dayPrizesObj) {
        String dateText = DateFormat("d/M/yyyy").format(dayPrizesObj.dateTime!);
        String prizesText = "${dayPrizesObj.firstPrize} - ${dayPrizesObj.secondPrize} - ${dayPrizesObj.thirdPrize}";

        return "$dateText\t$prizesText";
      },).join("\r\n");

      Clipboard.setData(
        ClipboardData(text: clipboardText)
      );
  }

  void setGlowContainer(bool glow){
    if(glowContainerKey.currentState != null){
      glowContainerKey.currentState!.setGlow(glow);
    }
  }
}

enum GeneralGestureType{
  tap, doubleTap, panStart, panUpdate, panEnd
}
