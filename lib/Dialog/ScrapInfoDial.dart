import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toto/Object/DayPrizesObj.dart';

import '../Progressor.dart';
import '../Util/Pair.dart';

class ScrapInfoDial extends StatefulWidget{

  Progressor? progressor;
  Stream<double>? progressStream;
  Stream<Pair<String,DayPrizesObj?>> scrapStream;
  double fontSize;

  ScrapInfoDial(
    {
      super.key,
      required this.progressor,
      required this.progressStream,
      required this.scrapStream,
      required this.fontSize,
    }
  );

  @override
  State<StatefulWidget> createState() {
      return ScrapInfoDialState();
  }

}

class ScrapInfoDialState extends State<ScrapInfoDial>{

  StreamSubscription<double>? progressStreamSub;
  StreamSubscription<Pair<String,DayPrizesObj?>>? scrapStreamSub;
  List<Pair<String, DayPrizesObj?>> scrappedPairList = [];
  double? progress;
  bool isCanceling = false;
  bool pin = false;
  
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    if(widget.progressStream != null){
      progressStreamSub = widget.progressStream!.listen((event) {
        setState(() {
          progress = event;
        });
      });
    }
    scrapStreamSub = widget.scrapStream.listen((event) {
      try{
        if(!pin){
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      }catch(e, ex){

      }
    });

    scrollController.addListener(() {
      if(scrollController.offset >= scrollController.position.maxScrollExtent){
        if(pin){
          pin = false;
        }
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    progressStreamSub?.cancel();
    scrapStreamSub?.cancel();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      return Container(
        width: 550,
        height: 600,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                "Scrapping entry from the web...",
                style: TextStyle(
                  fontSize: widget.fontSize+2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: Container(
                width: 490,
                height: 410,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1,
                    color: Colors.black
                  )
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    pin = true;
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: StreamBuilder<Pair<String, DayPrizesObj?>>(
                      stream: widget.scrapStream,
                      builder: (context, snapshot) {

                          if(snapshot.data != null && !scrappedPairList.contains(snapshot.data)){
                            scrappedPairList.add(snapshot.data!);
                          }

                          return ListView.builder(
                              controller: scrollController,
                              itemCount: scrappedPairList.length,
                              itemBuilder: (context, index) {

                                  String label = scrappedPairList[index].first!;
                                  DayPrizesObj? dayPrizesObj = scrappedPairList[index].second;
                                  Color lineColor = label.toLowerCase().contains("invalid") || label.toLowerCase().contains("conflict") ? Colors.red :
                                                      label.toLowerCase().contains("dupe") ? Colors.orangeAccent :
                                                          Colors.black;

                                  String detailString = dayPrizesObj != null ? ": ${dayPrizesObj.type} ${dayPrizesObj.getDateString(false, false)} - ${dayPrizesObj.getPrizeString().replaceAll(RegExp(r'[^0-9-]'), '')}" : "";

                                  return Text(
                                    "$label $detailString",
                                    style: TextStyle(
                                      fontSize: widget.fontSize,
                                      color: lineColor
                                    ),
                                  );
                              },
                          );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 500,
              height: 130,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(5),
                          child: LinearProgressIndicator(
                            value: progress,
                          )
                      ),
                      progress != null ? Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          "${((progress!*10000).round()/100)} %",
                          style: TextStyle(
                            fontSize: widget.fontSize-2,
                          ),
                        ),
                      ) : const SizedBox.shrink(),
                      const SizedBox(height: 10,),
                      widget.progressor != null ? TextButton(
                          onPressed: isCanceling ? null : () {
                            widget.progressor?.cancelProgress();
                            setState(() {
                              isCanceling = true;
                            });
                          },
                          child: Text(
                            isCanceling ? "Canceling..." : "Cancel",
                            style: TextStyle(
                              fontSize: widget.fontSize,
                            ),
                          )
                      ) : const SizedBox.shrink(),
                    ]
                ),
              ),
            )
          ],
        ),
      );
  }

  void close(){
    Navigator.pop(context);
  }
}