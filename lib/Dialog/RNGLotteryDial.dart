import 'dart:math';

import 'package:excel/excel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toto/Util/MyConst.dart';

import 'GetTextDialog.dart';

class RNGLotteryDial extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return RNGLotteryDialState();
  }

}

class RNGLotteryDialState extends State<RNGLotteryDial>{
  static const MAX_DRAW_COUNT_LIMIT = 1000;

  //Param
  int lotteryNumberCount = 6;
  int lotteryNumberRange = 58;
  int drawCount = 5;

  List<int> toExcludeNumber = [];
  List<int> toExcludeDigit = [];
  List<int> toIncludeNumber = [];
  List<int> toFavorDigit = [];

  List<List<int>> rngResultList = [];

  List<int> hoveringSet = [];

  Random random = Random();
  TextEditingController toExcludeNumberTEC = TextEditingController();
  TextEditingController toIncludeNumberTEC = TextEditingController();
  FocusNode toExcludeNumberFN = FocusNode();
  FocusNode toIncludeNumberFN = FocusNode();
  

  @override
  void initState() {
    toExcludeNumberFN.addListener(
        (){
          if(toExcludeNumberFN.hasFocus){
            //hasFocus
          }else{
            //lostFocus
            verifyAndSetToExcludeNumber(toExcludeNumberTEC.text);
          }
        }
    );
    toIncludeNumberFN.addListener(
            (){
          if(toIncludeNumberFN.hasFocus){
            //hasFocus
          }else{
            //lostFocus
            verifyAndSetToIncludeNumber(toIncludeNumberTEC.text);
          }
        }
    );
    super.initState();
  }

  @override
  void dispose() {
    toExcludeNumberTEC.dispose();
    toIncludeNumberTEC.dispose();
    toExcludeNumberFN.dispose();
    toIncludeNumberFN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: getWidth(),
      height: getHeight(),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            "assets/lotteryBackground.jpg",
          ),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.9), // Adjust the opacity
            BlendMode.dstATop, // Blend mode to apply transparency
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MaterialButton(
                  onPressed: () async {
                    await openLotteryConfigurationDial();
                  },
                  elevation: 5,
                  color: Colors.blue,
                  child: Text(
                    "$lotteryNumberCount/$lotteryNumberRange",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: Row(
                    children: [
                      Text("Exclude Number(s):", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),),
                      Expanded(
                        child: Container(
                          color: Colors.white,
                          child: TextField(
                            focusNode: toExcludeNumberFN,
                            controller: toExcludeNumberTEC,
                            onTapOutside: (event) {
                              FocusScope.of(context).unfocus();
                              verifyAndSetToExcludeNumber(toExcludeNumberTEC.text);
                            },
                            onEditingComplete: () {
                              FocusScope.of(context).unfocus();
                              verifyAndSetToExcludeNumber(toExcludeNumberTEC.text);
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "E.g. 52,17",
                              hintStyle: TextStyle(
                                  color: Colors.grey.withAlpha(150)
                              )
                            ),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[0-9,]"))],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: Row(
                    children: [
                      Text("Include Number(s):", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),),
                      Expanded(
                        child: Container(
                          color: Colors.white,
                          child: TextField(
                            focusNode: toIncludeNumberFN,
                            controller: toIncludeNumberTEC,
                            onTapOutside: (event) {
                              FocusScope.of(context).unfocus();
                              verifyAndSetToIncludeNumber(toIncludeNumberTEC.text);
                            },
                            onEditingComplete: () {
                              FocusScope.of(context).unfocus();
                              verifyAndSetToIncludeNumber(toIncludeNumberTEC.text);
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "E.g. 23,45",
                              hintStyle: TextStyle(
                                  color: Colors.grey.withAlpha(150)
                              )
                            ),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[0-9,]"))],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                MaterialButton(
                  onPressed: () async {
                    await openDrawCountConfigurationDial();
                  },
                  elevation: 5,
                  color: Colors.blue,
                  child: Text(
                    "Set(s): $drawCount",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Material(
                  elevation: 10,
                  child: Container(
                    width: getWidth()/1.85,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          "assets/ticketBackground.jpg",
                        ),
                        fit: BoxFit.fill,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.9), // Adjust the opacity
                          BlendMode.dstATop, // Blend mode to apply transparency
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "LUCKY PICK",
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'RaleWay'
                                  ),
                                )
                              ],
                            ),
                            ...rngResultList.map(
                              (drawResult) {
                              return MouseRegion(
                                onHover: (event) {
                                  setState(() {
                                    hoveringSet = drawResult;
                                  });
                                },
                                onExit: (event) {
                                  setState(() {
                                    hoveringSet = [];
                                  });
                                },
                                child: Container(
                                  color: hoveringSet == drawResult ? Colors.blue.shade100 : null,
                                  child: Row(
                                    children: drawResult.map((number) {
                                      return Expanded(
                                        child: Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(5),
                                            child: Text(
                                              "$number",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 21,
                                                fontWeight: FontWeight.w500
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      );
                                    },).toList(),
                                  ),
                                ),
                              );
                            },
                            ).toList()
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MaterialButton(
                  onPressed: close,
                  color: Colors.deepPurpleAccent,
                  elevation: 3,
                  child: Text(
                    "LEAVE",
                    style: TextStyle(
                      color: Colors.white
                    ),
                  ),
                ),
                MaterialButton(
                  onPressed: startDraw,
                  color: Colors.green,
                  elevation: 5,
                  child: Text(
                    "SIMULATE DRAW",
                    style: TextStyle(
                      color: Colors.white
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> openLotteryConfigurationDial() async {
    //region ConfirmationDial
    final _getTextDialKey = GlobalKey<GetTextDialState>();

    AlertDialog dialog = AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      content: GetTextDial(
        key: _getTextDialKey,
        fontSize: 17,
        height: 450,
        question: "Please key in lottery configuration\r\n<Lottery Count>/<Lottery Number Range>",
        subQuestion: "E.g. 6/58, 6/55",
        filteringTextInputFormatter: FilteringTextInputFormatter.allow(RegExp(r"[0-9/]")),
        verification: (text) {

          if(text.split("/").length != 2){
            return "Invalid format.";
          }

          int lotteryCount = int.tryParse(text.split("/").first) ?? -1;
          int lotteryNumberRange = int.tryParse(text.split("/").last) ?? -1;

          if(lotteryCount > lotteryNumberRange){
            return "Invalid data, Lottery Count cannot be larger than Lottery Number Range";
          }
          if(lotteryCount < 0){
            return "Invalid Lottery Count";
          }
          if(lotteryNumberRange < 0){
            return "Invalid Lottery Number Range";
          }

          return "";
        },
      ),
    );

    String? pattern = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return dialog;
      },
    );

    if(pattern != null){
      setState(() {
        lotteryNumberCount = int.parse(pattern.split("/").first);
        lotteryNumberRange = int.parse(pattern.split("/").last);
      });
    }
  }

  Future<void> openDrawCountConfigurationDial() async {

    //region ConfirmationDial
    final _getTextDialKey = GlobalKey<GetTextDialState>();

    AlertDialog dialog = AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      insetPadding: const EdgeInsets.all(0),
      content: GetTextDial(
        key: _getTextDialKey,
        fontSize: 18,
        height: 250,
        question: "Please key in total draw count you wish to simulate.\r\nMax Limit: $MAX_DRAW_COUNT_LIMIT",
        subQuestion: "",
        filteringTextInputFormatter: FilteringTextInputFormatter.allow(RegExp(r"[0-9]")),
        verification: (text) {

          int drawCount = int.tryParse(text) ?? -1;
          if(drawCount < 0){
            return "Invalid data";
          }
          if(drawCount > MAX_DRAW_COUNT_LIMIT){
            return "Value out of range (MAX: $MAX_DRAW_COUNT_LIMIT)";
          }

          return "";
        },
      ),
    );

    String? text = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return dialog;
      },
    );

    if(text != null){
      setState(() {
        drawCount = int.parse(text);
      });
    }
  }

  void verifyAndSetToExcludeNumber(String text){
    if(text.isEmpty){
      toExcludeNumber.clear();
      return;
    }

    //Convert to string list
    List<String> numberStrings = text.split(",");

    //Remove empty String (cases of ,,,,, behind)
    numberStrings.removeWhere((_text) => _text.isEmpty,);

    List<int> _toExcludeNumber = numberStrings.map((e) => int.parse(e),).toList();
    _toExcludeNumber.removeWhere(
      (element) => element > lotteryNumberRange || toIncludeNumber.contains(element),
    );

    toExcludeNumberTEC.text = _toExcludeNumber.toString().replaceAll("[", "").replaceAll("]", "").replaceAll(" ", "");
    setState(() {
      toExcludeNumber = List<int>.from(_toExcludeNumber);
    });
  }

  void verifyAndSetToIncludeNumber(String text){
    if(text.isEmpty){
      toIncludeNumber.clear();
      return;
    }

    //Convert to string list
    List<String> numberStrings = text.split(",");

    //Remove empty String (cases of ,,,,, behind)
    numberStrings.removeWhere((_text) => _text.isEmpty,);

    List<int> _toIncludeNumber = numberStrings.map((e) => int.parse(e),).toList();
    _toIncludeNumber.removeWhere(
      (element) => element > lotteryNumberRange || toExcludeNumber.contains(element),
    );
    print("${toIncludeNumber} vs $toExcludeNumber");

    toIncludeNumberTEC.text = _toIncludeNumber.toString().replaceAll("[", "").replaceAll("]", "").replaceAll(" ", "");
    setState(() {
      toIncludeNumber = List<int>.from(_toIncludeNumber);
      print("toinclude: $toIncludeNumber");
    });
  }

  void close(){
    Navigator.pop(context);
  }

  void startDraw(){

    //Define Lottery Pull
    List<int> lotteryPool = [];
    for(int i = 1; i <= lotteryNumberRange; i++){
      if(toExcludeNumber.contains(i) || toIncludeNumber.contains(i)) continue;

      lotteryPool.add(i);
    }

    //Define Draw Function
    List<int> draw(){
      List<int> _lotteryPool = List<int>.from(lotteryPool);

      List<int> result = [];
      for(int _toIncludeNumber in toIncludeNumber){
        if(result.length < lotteryNumberCount){
          result.add(_toIncludeNumber);
        }
      }

      while(result.length < lotteryNumberCount){
        int randomIndex = random.nextInt(_lotteryPool.length);
        int randomNumberPicked = _lotteryPool.removeAt(randomIndex);

        result.add(randomNumberPicked);
      }

      result.sort();

      return result;
    }

    //Clear rngResultList
    rngResultList.clear();

    //Draw 'N' times according to drawCount
    for(int drawCount = 0; drawCount < this.drawCount; drawCount++){
        rngResultList.add(draw());
    }

    //update ui
    setState(() {});
  }

  double getWidth(){
    return MediaQuery.of(context).size.width*0.9;
  }

  double getHeight(){
    return MediaQuery.of(context).size.height*0.9;
  }

}