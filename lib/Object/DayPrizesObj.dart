import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:toto/DataManager.dart';
import 'package:toto/Object/PrizeObj.dart';
import 'package:toto/Util/MyConst.dart';
import 'package:toto/Util/MyUtil.dart';

class DayPrizesObj{
  DateTime? dateTime;
  String? firstPrize;
  String? secondPrize;
  String? thirdPrize;

  String? firstPrize6D;
  String? secondPrize6D;
  String? thirdPrize6D;

  String? type;

  PrizeObj? firstPrizeObj;
  PrizeObj? secondPrizeObj;
  PrizeObj? thirdPrizeObj;
  PrizeObj? firstPrize6DObj;
  PrizeObj? secondPrize6DObj;
  PrizeObj? thirdPrize6DObj;

  static DateFormat dateFormatDefault = MyUtil.getDefaultDateFormat();
  static DateFormat dateFormatDefaultShort = DateFormat("yy-MM-dd");
  static DateFormat dateFormatCommon = DateFormat("dd/MM/yyyy");
  static DateFormat dateFormatCommonShort = DateFormat("dd/MM/yy");

  void setDateTime(String dateTimeString){
    String filtered = dateTimeString.split("T").first;
    List<String> subStrings = filtered.split("-");

    int year = int.parse( subStrings[0] );
    int month = int.parse( subStrings[1] );
    int day = int.parse( subStrings[2] );

    dateTime = DateTime(year, month, day);
  }

  void setPrize(String prizeString){

    List<String> subStrings = prizeString.split("-");

    firstPrize = subStrings[0].replaceAll(RegExp(r"\D"), "");
    secondPrize = subStrings[1].replaceAll(RegExp(r"\D"), "");
    thirdPrize = subStrings[2].replaceAll(RegExp(r"\D"), "");
    type = prizeString.replaceAll(RegExp(r"[^A-Za-z]"), "");

    if(subStrings.length >= 6){
      firstPrize6D = subStrings[3].replaceAll(RegExp(r"\D"), "");
      secondPrize6D = subStrings[4].replaceAll(RegExp(r"\D"), "");
      thirdPrize6D = subStrings[5].replaceAll(RegExp(r"\D"), "");
    }

  }

  String getPrizeString(){
    if(firstPrize != null && secondPrize != null && thirdPrize != null){

      if(firstPrize6D != null && secondPrize6D != null && thirdPrize6D != null){
        return "$firstPrize-$secondPrize-$thirdPrize-$firstPrize6D-$secondPrize6D-$thirdPrize6D$type";
      }

      return "$firstPrize-$secondPrize-$thirdPrize$type";
    }

    throw Exception();
  }

  List<PrizeObj> getPrizeObjList(){
      List<PrizeObj> list = [];
      list.add(PrizeObj(this, firstPrize!, type!, 1, dateTime!));
      list.add(PrizeObj(this, secondPrize!, type!, 2, dateTime!));
      list.add(PrizeObj(this, thirdPrize!, type!, 3, dateTime!));

      if(firstPrize6D != null && secondPrize6D != null && thirdPrize6D != null){
        list.add(PrizeObj(this, firstPrize6D!, type!, 1, dateTime!));
        list.add(PrizeObj(this, secondPrize6D!, type!, 2, dateTime!));
        list.add(PrizeObj(this, thirdPrize6D!, type!, 3, dateTime!));
      }

      return list;
  }

  String getDefaultDateString(){
    return getDateString(true, false);
  }

  String getDateString(bool defaultForm, bool shortform){

      if(dateTime == null){return "null";}

      if(!defaultForm){
        if(shortform){
          return dateFormatCommonShort.format(dateTime!);
        }

        return dateFormatCommon.format(dateTime!);
      }else{
        if(shortform){
          return dateFormatDefaultShort.format(dateTime!);
        }
      }

      return dateFormatDefault.format(dateTime!);
  }

  String getUniqueKey(){
    return "${getDefaultDateString()}$type";
  }

  AssetImage getAssetImage(){
    return AssetImage(
      type == PrizeObj.TYPE_MAGNUM4D ? "assets/magnum.ico":
      type == PrizeObj.TYPE_TOTO ? "assets/toto.ico" :
      type == PrizeObj.TYPE_DAMACAI ?"assets/damacai.ico" : throw Exception()
    );
  }

  static bool hasDuplicateUniqueKey(List<DayPrizesObj?> list, DayPrizesObj toCheck){

      for(DayPrizesObj? dayPrizesObj in list){

          if(dayPrizesObj == null){
            continue;
          }

          if(dayPrizesObj.getUniqueKey() == toCheck.getUniqueKey()){
            return true;
          }
      }

      return false;
  }

  static bool hasDuplicateType(List<DayPrizesObj> list, DayPrizesObj toCheck){

      for(DayPrizesObj dayPrizesObj in list){
          if(dayPrizesObj.type == toCheck.type){
            return true;
          }
      }

      return false;
  }

  static DayPrizesObj? getDayPrizesObjWithUniqueKey(String uniqueKey){
      String type = uniqueKey.replaceAll(RegExp(r"[^A-Za-z]"), "");
      String dateString = uniqueKey.replaceAll(RegExp(r"[A-Za-z]"), "");

      List<String> dateStringList = dateString.split("-");

      int year = int.parse( dateStringList[0] );
      int month = int.parse( dateStringList[1] );
      int day = int.parse( dateStringList[2] );

      DateTime dateTime = DateTime(year, month, day);

      if(DataManager.getInstance().SortedByDateMap.containsKey(dateTime)){
        for(DayPrizesObj dayPrizesObj in DataManager.getInstance().SortedByDateMap[dateTime]!){
          if(dayPrizesObj.type == type){
            return dayPrizesObj;
          }
        }
      }

      return null;
  }

  void printDetail(){
    print("${dateFormatDefault.format(dateTime!)} -> $firstPrize $secondPrize $thirdPrize");
  }

  PrizeObj getFirstPrizeObj(){
    if(firstPrizeObj == null){
      firstPrizeObj = PrizeObj(this, firstPrize!, type!, 1, dateTime!);
    }
    return firstPrizeObj!;
  }
  PrizeObj getSecondPrizeObj(){
    if(secondPrizeObj == null){
      secondPrizeObj = PrizeObj(this, secondPrize!, type!, 2, dateTime!);
    }
    return secondPrizeObj!;
  }
  PrizeObj getThirdPrizeObj(){
    if(thirdPrizeObj == null){
      thirdPrizeObj = PrizeObj(this, thirdPrize!, type!, 3, dateTime!);
    }
    return thirdPrizeObj!;
  }

  PrizeObj? getFirstPrizeObj6D(){
    if(firstPrize6DObj == null){
      firstPrize6DObj = firstPrize6D != null ? PrizeObj(this, firstPrize6D!, type!, 1, dateTime!) : null;
    }
    return firstPrize6DObj;
  }
  PrizeObj? getSecondPrizeObj6D(){
    if(secondPrize6DObj == null){
      secondPrize6DObj = secondPrize6D != null ? PrizeObj(this, secondPrize6D!, type!, 2, dateTime!) : null;
    }
    return secondPrize6DObj;
  }
  PrizeObj? getThirdPrizeObj6D(){
    if(thirdPrize6DObj == null){
      thirdPrize6DObj = thirdPrize6D != null ? PrizeObj(this, thirdPrize6D!, type!, 3, dateTime!) : null;
    }
    return thirdPrize6DObj;
  }

  bool hasRelevantPrizeObj(String? prizeHovered){

    if(prizeHovered == null){
      return false;
    }

    return (
      firstPrizeObj?.checkDefaultRelevantString(prizeHovered) != null ||
      secondPrizeObj?.checkDefaultRelevantString(prizeHovered) != null ||
      thirdPrizeObj?.checkDefaultRelevantString(prizeHovered) != null ||
      firstPrize6DObj?.checkDefaultRelevantString(prizeHovered) != null ||
      secondPrize6DObj?.checkDefaultRelevantString(prizeHovered) != null ||
      thirdPrize6DObj?.checkDefaultRelevantString(prizeHovered) != null
    );
  }

  Map<String, dynamic> toJson(){

    if(dateTime == null || type == null || firstPrize == null || secondPrize == null || thirdPrize == null){
      throw Exception();
    }

    return {
      "dateTime" : dateTime!.toIso8601String(),
      "firstPrize" : firstPrize!,
      "secondPrize" : secondPrize!,
      "thirdPrize" : thirdPrize!,
      "type" : type!,

      "firstPrize6D" : firstPrize6D,
      "secondPrize6D" : secondPrize6D,
      "thirdPrize6D" : thirdPrize6D
    };
  }

  static DayPrizesObj fromJson(Map<String ,dynamic> json){
    DayPrizesObj dayPrizesObj = DayPrizesObj();

    dayPrizesObj.dateTime = DateTime.parse(json["dateTime"]);
    dayPrizesObj.firstPrize = json["firstPrize"];
    dayPrizesObj.secondPrize = json["secondPrize"];
    dayPrizesObj.thirdPrize = json["thirdPrize"];
    dayPrizesObj.type = json["type"];

    dayPrizesObj.firstPrize6D = json["firstPrize6D"];
    dayPrizesObj.secondPrize6D = json["secondPrize6D"];
    dayPrizesObj.thirdPrize6D = json["thirdPrize6D"];

    return dayPrizesObj;
  }
}