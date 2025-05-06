import 'dart:async';
import 'dart:isolate';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toto/Object/SingleDisplayTemplate.dart';
import 'package:toto/Progressor.dart';
import 'package:toto/Util/MyConst.dart';
import 'package:toto/Widget/TableChartContainer.dart';

import 'Object/DayPrizesObj.dart';
import 'Object/PrizeObj.dart' as p;

import 'Util/Pair.dart';

class DataManager implements Progressor{

  static final DataManager _instance = DataManager._internal();

  DataManager._internal();


  final Map<String, List<DayPrizesObj>> SortedByPrizeMap = {};
  final Map<String, List<DayPrizesObj>> SortedByPrizeMap_ChainHead = {};
  final Map<String, List<DayPrizesObj>> SortedByPrizeMap_ChainTail = {};

  final Map<DateTime, List<DayPrizesObj>> SortedByDateMap = {};

  final Map<String, List<DateTime>> InvalidDateStringMap = {};
  final Map<String, List<DateTime>> NoDrawDateMap = {};

  final StreamController<double> _saveProgressStreamController = StreamController.broadcast();
  bool _isCanceling = false;

  static DataManager getInstance(){
    return _instance;
  }

  Future<void> load() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    //await sp.clear();

    List<DayPrizesObj> dayPrizesObjList = [];
    for(String key in sp.getKeys()){

      print(key);
      
      if(!key.startsWith(RegExp(r'[0-9]'))){print(key); continue;}
      
      List<String> prizeStringList = sp.getStringList(key)!; //xxxx-xxxx-xxxxMAGNUM

      for(String prizeString in prizeStringList){
        DayPrizesObj dayPrizesObj = DayPrizesObj();
        dayPrizesObj.setDateTime(key);
        dayPrizesObj.setPrize(prizeString);

        dayPrizesObjList.add(dayPrizesObj);
      }

    }
    addToSortedMap(dayPrizesObjList);

    await loadNoDrawDate();
  }

  List<DayPrizesObj> addToSortedMap(List<DayPrizesObj> detailObjList, {bool overrideDupe = false}){

    List<DayPrizesObj> duplicateFoundList = [];

    for(DayPrizesObj dayPrizesObj in detailObjList){

      DateTime dateTime = dayPrizesObj.dateTime!;

      //region SortedByPrize
      if(!SortedByPrizeMap.containsKey(dayPrizesObj.firstPrize!)){
        SortedByPrizeMap[dayPrizesObj.firstPrize!] = [];
      }
      if(!SortedByPrizeMap.containsKey(dayPrizesObj.secondPrize!)){
        SortedByPrizeMap[dayPrizesObj.secondPrize!] = [];
      }
      if(!SortedByPrizeMap.containsKey(dayPrizesObj.thirdPrize!)){
        SortedByPrizeMap[dayPrizesObj.thirdPrize!] = [];
      }
      if(!DayPrizesObj.hasDuplicateUniqueKey(SortedByPrizeMap[dayPrizesObj.firstPrize!]!, dayPrizesObj)){
        SortedByPrizeMap[dayPrizesObj.firstPrize!]!.add(dayPrizesObj);
      }

      if(!DayPrizesObj.hasDuplicateUniqueKey(SortedByPrizeMap[dayPrizesObj.secondPrize!]!, dayPrizesObj)){
        SortedByPrizeMap[dayPrizesObj.secondPrize!]!.add(dayPrizesObj);
      }

      if(!DayPrizesObj.hasDuplicateUniqueKey(SortedByPrizeMap[dayPrizesObj.thirdPrize!]!, dayPrizesObj)){
        SortedByPrizeMap[dayPrizesObj.thirdPrize!]!.add(dayPrizesObj);
      }
      //endregion

      //region SortedByPrize_ChainHead
        //region firstPrize
        String label1 = "${dayPrizesObj.firstPrize!.substring(0,3)}?";
        if(!SortedByPrizeMap_ChainHead.containsKey(label1)){
          SortedByPrizeMap_ChainHead[label1] = [];
        }
        if(!DayPrizesObj.hasDuplicateUniqueKey(SortedByPrizeMap_ChainHead[label1]!, dayPrizesObj)){
          SortedByPrizeMap_ChainHead[label1]!.add(dayPrizesObj);
        }
        //endregion

        //region secondPrize
        String label2 = "${dayPrizesObj.secondPrize!.substring(0,3)}?";
        if(!SortedByPrizeMap_ChainHead.containsKey(label2)){
          SortedByPrizeMap_ChainHead[label2] = [];
        }
        if(!DayPrizesObj.hasDuplicateUniqueKey(SortedByPrizeMap_ChainHead[label2]!, dayPrizesObj)){
          SortedByPrizeMap_ChainHead[label2]!.add(dayPrizesObj);
        }
        //endregion

        //region thirdPrize
        String label3 = "${dayPrizesObj.thirdPrize!.substring(0,3)}?";
        if(!SortedByPrizeMap_ChainHead.containsKey(label3)){
          SortedByPrizeMap_ChainHead[label3] = [];
        }
        if(!DayPrizesObj.hasDuplicateUniqueKey(SortedByPrizeMap_ChainHead[label3]!, dayPrizesObj)){
          SortedByPrizeMap_ChainHead[label3]!.add(dayPrizesObj);
        }
        //endregion
      //endregion

      //region SortedByPrize_ChainTail
      //region firstPrize
      String _label1 = "?${dayPrizesObj.firstPrize!.substring(1,4)}";
      if(!SortedByPrizeMap_ChainTail.containsKey(_label1)){
        SortedByPrizeMap_ChainTail[_label1] = [];
      }
      if(!DayPrizesObj.hasDuplicateUniqueKey(SortedByPrizeMap_ChainTail[_label1]!, dayPrizesObj)){
        SortedByPrizeMap_ChainTail[_label1]!.add(dayPrizesObj);
      }
      //endregion

      //region secondPrize
      String _label2 = "?${dayPrizesObj.secondPrize!.substring(1,4)}";
      if(!SortedByPrizeMap_ChainTail.containsKey(_label2)){
        SortedByPrizeMap_ChainTail[_label2] = [];
      }
      if(!DayPrizesObj.hasDuplicateUniqueKey(SortedByPrizeMap_ChainTail[_label2]!, dayPrizesObj)){
        SortedByPrizeMap_ChainTail[_label2]!.add(dayPrizesObj);
      }
      //endregion

      //region thirdPrize
      String _label3 = "?${dayPrizesObj.thirdPrize!.substring(1,4)}";
      if(!SortedByPrizeMap_ChainTail.containsKey(_label3)){
        SortedByPrizeMap_ChainTail[_label3] = [];
      }
      if(!DayPrizesObj.hasDuplicateUniqueKey(SortedByPrizeMap_ChainTail[_label3]!, dayPrizesObj)){
        SortedByPrizeMap_ChainTail[_label3]!.add(dayPrizesObj);
      }
      //endregion
      //endregion


      //region SortedByDate
      if(!SortedByDateMap.containsKey(dateTime)) {
        SortedByDateMap[dateTime] = [];
      }
      if(!DayPrizesObj.hasDuplicateType(SortedByDateMap[dateTime]!, dayPrizesObj)){
          SortedByDateMap[dateTime]!.add(dayPrizesObj);

      }else if(overrideDupe) {
          for(DayPrizesObj sortMapDayPrizesObj in SortedByDateMap[dateTime]!){
              if(sortMapDayPrizesObj.type == dayPrizesObj.type){
                SortedByDateMap[dateTime]!.remove(sortMapDayPrizesObj);
                SortedByDateMap[dateTime]!.add(dayPrizesObj);
                break;
              }
          }

      }else{
          duplicateFoundList.add(dayPrizesObj);
      }
      //endregion
    }

    return duplicateFoundList;
  }

  List<Pair<DayPrizesObj, UploadAttempt>> getUploadAttemptList(List<DayPrizesObj> dayPrizesObjList){
      List<Pair<DayPrizesObj, UploadAttempt>> list = [];

      for(DayPrizesObj dayPrizesObj in dayPrizesObjList){
          DateTime dateTime = dayPrizesObj.dateTime!;
          String type = dayPrizesObj.type!;

          UploadAttempt uploadAttempt = UploadAttempt.clean;
          if(SortedByDateMap.containsKey(dateTime)){
              for(DayPrizesObj sortedMapDayPrizesObj in SortedByDateMap[dateTime]!){
                  if(sortedMapDayPrizesObj.type == type){
                      uploadAttempt = UploadAttempt.dupe;

                      List<p.PrizeObj> prizeObjList = dayPrizesObj.getPrizeObjList();
                      List<p.PrizeObj> sortedMapPrizeObjList = sortedMapDayPrizesObj.getPrizeObjList();

                      if(prizeObjList.length != sortedMapPrizeObjList.length){
                          uploadAttempt = UploadAttempt.conflict;
                          continue;
                      }
                      for(int i = 0; i < sortedMapPrizeObjList.length; i++){
                          if(prizeObjList[i].getFullString() != sortedMapPrizeObjList[i].getFullString()){

                            //print("Conflict: ${prizeObjList[i].getFullString()} != ${sortedMapPrizeObjList[i].getFullString()}");

                            uploadAttempt = UploadAttempt.conflict;
                            continue;
                          }
                      }
                  }
              }
          }

          if(uploadAttempt == UploadAttempt.conflict){
            //print(dayPrizesObj.getDateString(false, false) + "-" + dayPrizesObj.getPrizeString());
          }

          list.add(Pair<DayPrizesObj, UploadAttempt>(dayPrizesObj, uploadAttempt));
      }

      list.sort((a, b) {

        int magnum = 1;
        int toto = 2;
        int damacai = 3;

        if(a.first!.dateTime!.isAtSameMomentAs(b.first!.dateTime!)){
          int a_value = a.first!.type == p.PrizeObj.TYPE_MAGNUM4D ? magnum : a.first!.type == p.PrizeObj.TYPE_TOTO ? toto : damacai;
          int b_value = b.first!.type == p.PrizeObj.TYPE_MAGNUM4D ? magnum : b.first!.type == p.PrizeObj.TYPE_TOTO ? toto : damacai;

          return a_value - b_value;
        }

        return a.first!.dateTime!.isBefore(b.first!.dateTime!) ? -1 : 1;

      },);
      return list;
  }

  Future<List<DayPrizesObj>> uploadAndSave(List<DayPrizesObj> dayPrizesObjList, {SendPort? sendPort}) async {

      SharedPreferences sp = await SharedPreferences.getInstance();
      //await sp.reload();

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
        _saveProgressStreamController.sink.add(progress);

        if(sendPort != null){
          sendPort.send(progress);
        }

        if(_isCanceling){
          break;
        }
      }

      addToSortedMap(savedList, overrideDupe: true);

      //await sp.reload();
      //await sp.commit();

      return savedList;
  }

  void updateInvalidDate(Map<String, List<DateTime>> _invalidDate){
    for(MapEntry<String, List<DateTime>> entry in _invalidDate.entries){
      String type = entry.key;
      List<DateTime> dateList = entry.value;

      if(!InvalidDateStringMap.containsKey(type)){
        InvalidDateStringMap[type] = [];
      }

      for(DateTime dateTime in dateList){
        if(!InvalidDateStringMap[type]!.contains(dateTime)){
          InvalidDateStringMap[type]!.add(dateTime);
        }
      }
    }

    InvalidDateStringMap.removeWhere(
        (key, value){

          if(NoDrawDateMap.containsKey(key)){
            InvalidDateStringMap[key]!.removeWhere((element) => NoDrawDateMap[key]!.contains(element));
          }

          if(value.isEmpty){
            return true;
          }

          return false;
        }
    );

  }

  void clearInvalidDate(){
    InvalidDateStringMap.clear();
  }

  Future<void> updateAndSaveNoDrawDate(Map<String, List<DateTime>> _noDrawDateMap) async {

    for(MapEntry<String, List<DateTime>> entry in _noDrawDateMap.entries){

      String type = entry.key;
      List<DateTime> dateTimeList = entry.value;

      if(!NoDrawDateMap.containsKey(type)){
        NoDrawDateMap[type] = [];
      }

      for(DateTime dateTime in dateTimeList){
        if(!NoDrawDateMap[type]!.contains(dateTime)){
          NoDrawDateMap[type]!.add(dateTime);
        }
      }
    }

    SharedPreferences sp = await SharedPreferences.getInstance();

    List<String> noDrawDateStringList = sp.getStringList(MyConst.Key_NoDrawDateMap) ?? [];

    for(MapEntry<String, List<DateTime>> entry in _noDrawDateMap.entries){

      String type = entry.key;
      List<DateTime> dateTimeList = entry.value;

      for(DateTime dateTime in dateTimeList){
        String formattedString = "$type|${dateTime.toIso8601String()}";

        if(!noDrawDateStringList.contains(formattedString)){

          //To save in SP
          noDrawDateStringList.add(formattedString);

          //Update in memory
          if(!NoDrawDateMap.containsKey(type)){
            NoDrawDateMap[type] = [];
          }
          NoDrawDateMap[type]!.add(dateTime);
        }
      }
    }

    await sp.setStringList(MyConst.Key_NoDrawDateMap, noDrawDateStringList);
  }

  Future<void> loadNoDrawDate() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    List<String> noDrawDateFormattedStringList = sp.getStringList(MyConst.Key_NoDrawDateMap) ?? [];

    for(String formattedString in noDrawDateFormattedStringList){
      String type = formattedString.split("|").first;
      DateTime dateTime = DateTime.parse(formattedString.split("|").last);

      if(!NoDrawDateMap.containsKey(type)){
        NoDrawDateMap[type] = [];
      }

      NoDrawDateMap[type]!.add(dateTime);
    }
  }
  /*static Future<void> save() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    for(List<DayPrizesObj> dayPrizesObjList in SortedByDateMap.values){
        for(DayPrizesObj dayPrizesObj in dayPrizesObjList){
            List<String> oriList = sp.getStringList(dayPrizesObj.getDefaultDateString()) ?? [];

            //Remove dupe type
            oriList.removeWhere((element) => element.contains(dayPrizesObj.type!));

            //Add into list if not similar data already exist
            if(!oriList.contains(dayPrizesObj.getPrizeString())){
              oriList.add(dayPrizesObj.getPrizeString());
            }

            sp.setStringList(dayPrizesObj.getDefaultDateString(), oriList);
        }
    }
  }*/

  DayPrizesObj? getDayPrizesObj(DateTime dateTime, String type){
      if(SortedByDateMap.containsKey(dateTime)){
          for(DayPrizesObj dayPrizesObj in SortedByDateMap[dateTime]!){
            if(dayPrizesObj.type == type){
                return dayPrizesObj;
            }
          }
      }

      return null;
  }

  List<DayPrizesObj> getSortedDateBasedDayPrizeObjList(Map<String, bool> typeBoolList,
      {int? year, int? month, int? day, int? yearMin, int? yearMax, int? monthMin, int? monthMax, int? dayMin, int? dayMax, List<String> filterList = const [],
      DrawDayType drawDayType = DrawDayType.AllDraw}
  ){

    List<DayPrizesObj> list = [];

      for(MapEntry<DateTime, List<DayPrizesObj>> entry in SortedByDateMap.entries){

        DateTime dateTime = entry.key;
        List<DayPrizesObj> dayPrizesObjList = entry.value;

        if(year != null && dateTime.year != year){
          continue;
        }
        if((yearMin != null && yearMax != null) && (dateTime.year < yearMin || dateTime.year > yearMax)){
          continue;
        }
        if(month != null && dateTime.month != month){
          continue;
        }
        if((monthMin != null && monthMax != null) && (dateTime.month < monthMin || dateTime.month > monthMax)){
          continue;
        }
        if(day != null && dateTime.day != day){
          continue;
        }
        if((dayMin != null && dayMax != null) && (dateTime.day < dayMin || dateTime.day > dayMax)){
          continue;
        }
        if(drawDayType == DrawDayType.RegularDraw){
          if(dateTime.weekday == 2){
            continue;
          }
        }
        if(drawDayType == DrawDayType.SpecialDraw){
          if(dateTime.weekday != 2){
            continue;
          }
        }

        for(DayPrizesObj dayPrizesObj in dayPrizesObjList){
            if(typeBoolList.containsKey(dayPrizesObj.type) && typeBoolList[dayPrizesObj.type]!){
              /*List<p.PrizeObj> prizeObjList = dayPrizesObj.getPrizeObjList();

              SingleDisplayTemplate singleDisplayTemplate = SingleDisplayTemplate(
                  dayPrizesObj.getDateString(true, true),
                  dayPrizesObj.type!,
                  prizeObjList.map<Pair<String, p.PrizeObj>>(
                          (e) => Pair<String, p.PrizeObj>("",e)
                  ).toList()
              );*/

              if(applyFilter(dayPrizesObj, filterList)){
                list.add( dayPrizesObj );
              }

            }
        }

      }

      list.sort((a, b) {

        int magnum = 1;
        int toto = 2;
        int damacai = 3;

        if(a.dateTime!.isAtSameMomentAs(b.dateTime!)){
            int a_value = a.type == p.PrizeObj.TYPE_MAGNUM4D ? magnum : a.type == p.PrizeObj.TYPE_TOTO ? toto : damacai;
            int b_value = b.type == p.PrizeObj.TYPE_MAGNUM4D ? magnum : b.type == p.PrizeObj.TYPE_TOTO ? toto : damacai;

            return a_value - b_value;
        }

        return a.dateTime!.isBefore(b.dateTime!) ? -1 : 1;
      },);

      print("${list.length} found");

      return list;
  }

  Map<String, List<DayPrizesObj>> getPrizeBasedDayPrizeObjMap(Map<String, bool> typeBoolList,
      {int? year, int? month, int? day, int? yearMin, int? yearMax, int? monthMin, int? monthMax, int? dayMin, int? dayMax,
        DrawDayType drawDayType = DrawDayType.AllDraw, required PrizePatternType prizePatternType}
  ){
      Map<String, List<DayPrizesObj>> map = {};

      Map<String, List<DayPrizesObj>> prizeMap = prizePatternType == PrizePatternType.Pattern_XYZ ? SortedByPrizeMap_ChainTail :
                                                  prizePatternType == PrizePatternType.PatternWXY_ ? SortedByPrizeMap_ChainHead : throw Exception();

      for(MapEntry<String, List<DayPrizesObj>> entry in prizeMap.entries){
          String label = entry.key;
          List<DayPrizesObj> dayPrizesObjList = entry.value;
          List<DayPrizesObj> filteredDayPrizesObjList = [];

          for(DayPrizesObj dayPrizesObj in dayPrizesObjList){
            DateTime dateTime = dayPrizesObj.dateTime!;

            if(year != null && dateTime.year != year){
              continue;
            }
            if((yearMin != null && yearMax != null) && (dateTime.year < yearMin || dateTime.year > yearMax)){
              continue;
            }
            if(month != null && dateTime.month != month){
              continue;
            }
            if((monthMin != null && monthMax != null) && (dateTime.month < monthMin || dateTime.month > monthMax)){
              continue;
            }
            if(day != null && dateTime.day != day){
              continue;
            }
            if((dayMin != null && dayMax != null) && (dateTime.day < dayMin || dateTime.day > dayMax)){
              continue;
            }
            if(drawDayType == DrawDayType.RegularDraw){
              if(dateTime.weekday == 2){
                continue;
              }
            }
            if(drawDayType == DrawDayType.SpecialDraw){
              if(dateTime.weekday != 2){
                continue;
              }
            }

            if(typeBoolList.containsKey(dayPrizesObj.type) && typeBoolList[dayPrizesObj.type]!){
              filteredDayPrizesObjList.add(dayPrizesObj);
            }
          }

          map[label] = filteredDayPrizesObjList;
      }

      return map;
  }

  bool applyFilter(DayPrizesObj dayPrizesObj, List<String> filterList){

      if(filterList.isEmpty){
          return true;
      }

      for(p.PrizeObj prizeObj in dayPrizesObj.getPrizeObjList()){
        String prizeString = prizeObj.getFullString();


        for(String filterString in filterList){
            if(prizeString.length != filterString.length){
              continue;
            }

            bool match = applyFilterSub(prizeString, filterString);

            if(match){
              return true;
            }

            /*String? let_X_Be;
            String? let_Y_Be;

            bool discrepancy = false;
            for(int i = 0; i < filterString.length; i++){
              String prizeStringChar = prizeString[i];
              String filterChar = filterString[i];

                switch(filterChar){
                  case "?":
                    continue;

                  case "x":
                    if(let_X_Be != null){
                        if(prizeStringChar != let_X_Be){
                          discrepancy = true;
                        }
                    }else if(let_Y_Be != null && prizeStringChar == let_Y_Be){
                      discrepancy = true;
                    }else{
                        let_X_Be = prizeStringChar;
                    }
                    break;

                  case "y":
                    if(let_Y_Be != null){
                      if(prizeStringChar != let_Y_Be){
                        discrepancy = true;
                      }
                    }else if(let_X_Be != null && prizeStringChar == let_X_Be){
                      discrepancy = true;
                    }else{
                      let_Y_Be = prizeStringChar;
                    }
                    break;

                  default:
                    if(filterChar != prizeStringChar){
                        discrepancy = true;
                    }
                }

                if(discrepancy){
                    break;
                }
            }

            if(!discrepancy){
                return true;
            }*/
        }
      }

      return false;
  }

  bool applyFilterSub(String prizeString, String filterString){
    String? let_X_Be;
    String? let_Y_Be;
    String? let_Z_Be;

    for(int i = 0; i < filterString.length; i++){
      String prizeStringChar = prizeString[i];
      String filterChar = filterString[i];

      switch(filterChar){
        case "?":
          continue;

        case "x":
          if(let_X_Be != null){
            if(prizeStringChar != let_X_Be){
              return false;
            }
          }else if((let_Y_Be != null && prizeStringChar == let_Y_Be) || (let_Z_Be != null && prizeStringChar == let_Z_Be)){
            return false;
          }else{
            let_X_Be = prizeStringChar;
          }
          break;

        case "y":
          if(let_Y_Be != null){
            if(prizeStringChar != let_Y_Be){
              return false;
            }
          }else if((let_X_Be != null && prizeStringChar == let_X_Be) || (let_Z_Be != null && prizeStringChar == let_Z_Be)){
            return false;
          }else{
            let_Y_Be = prizeStringChar;
          }
          break;

        case "z":
          if(let_Z_Be != null){
            if(prizeStringChar != let_Z_Be){
              return false;
            }
          }else if((let_X_Be != null && prizeStringChar == let_X_Be) || (let_Y_Be != null && prizeStringChar == let_Y_Be)){
            return false;
          }else{
            let_Z_Be = prizeStringChar;
          }
          break;

        default:
          if(filterChar != prizeStringChar){
            return false;
          }
      }
    }

    return true;
  }

  Map<String, List<DateTime>> getMissingEntry({bool getAllDateRegardless = false, int startYear = -1, int terminalYear = -1, bool ignoreNoDrawDates = false}){
      Map<String, List<DateTime>> missingEntryMap = {
        p.PrizeObj.TYPE_MAGNUM4D : [],
        p.PrizeObj.TYPE_TOTO : [],
        p.PrizeObj.TYPE_DAMACAI : [],
      };

      //Start date from yesterday (if no fromYear assigned)
      DateTime latestPossibleDateTime = DateTime( DateTime.now().year, DateTime.now().month, (DateTime.now().day-1));
      DateTime toLookDateTime = startYear == -1 ? latestPossibleDateTime : DateTime(startYear, 12, 31);

      if(toLookDateTime.isAfter(latestPossibleDateTime)){
        toLookDateTime = latestPossibleDateTime;
      }

      int offsetDay = toLookDateTime.weekday == 1 ? -1 :
                      //toLookDateTime.weekday == 2 ? -2 :  //include tuesday
                      toLookDateTime.weekday == 4 ? -1 :
                      toLookDateTime.weekday == 5 ? -2 : 0;


      toLookDateTime = DateTime( toLookDateTime.year, toLookDateTime.month, (toLookDateTime.day+offsetDay));

      DateTime terminalDateTime = terminalYear == -1 ? MyConst.EarliestScrapDate : DateTime(terminalYear-1, 12, 31);
      while(toLookDateTime.isAfter(terminalDateTime)){

            if(!SortedByDateMap.containsKey(toLookDateTime) || getAllDateRegardless){
              missingEntryMap[p.PrizeObj.TYPE_MAGNUM4D]!.add(toLookDateTime);
              missingEntryMap[p.PrizeObj.TYPE_TOTO]!.add(toLookDateTime);
              missingEntryMap[p.PrizeObj.TYPE_DAMACAI]!.add(toLookDateTime);
              //list.add(Pair<DateTime, String>(toLookDateTime, p.PrizeObj.TYPE_MAGNUM4D));
              //list.add(Pair<DateTime, String>(toLookDateTime, p.PrizeObj.TYPE_TOTO));
              //list.add(Pair<DateTime, String>(toLookDateTime, p.PrizeObj.TYPE_DAMACAI));

            }else{
              List<DayPrizesObj> dayPrizesObjList = SortedByDateMap[toLookDateTime]!;

              List<String> typeMissingList = [p.PrizeObj.TYPE_MAGNUM4D, p.PrizeObj.TYPE_TOTO, p.PrizeObj.TYPE_DAMACAI];

              for(DayPrizesObj dayPrizesObj in dayPrizesObjList){
                if(typeMissingList.contains(dayPrizesObj.type)){
                  typeMissingList.remove(dayPrizesObj.type);
                }
              }

              for(String type in typeMissingList){
                missingEntryMap[type]!.add(toLookDateTime);
                //list.add(Pair<DateTime, String>(toLookDateTime, type));
              }
            }

            toLookDateTime = DateTime(toLookDateTime.year, toLookDateTime.month, toLookDateTime.day-1);

            offsetDay = toLookDateTime.weekday == 1 ? -1 :
            //toLookDateTime.weekday == 2 ? -2 :  //include tuesday
            toLookDateTime.weekday == 4 ? -1 :
            toLookDateTime.weekday == 5 ? -2 : 0;


            toLookDateTime = DateTime(toLookDateTime.year, toLookDateTime.month, toLookDateTime.day+offsetDay);

            //print("doing ${toLookDateTime.day}/${toLookDateTime.month}/${toLookDateTime.year}");
      }

      if(ignoreNoDrawDates){
        for(MapEntry<String, List<DateTime>> entry in missingEntryMap.entries){

          String type = entry.key;

          missingEntryMap[type]!.removeWhere((element) => (NoDrawDateMap.containsKey(type) && NoDrawDateMap[type]!.contains(element)));
        }

        missingEntryMap.removeWhere((key, value) => value.isEmpty);
      }

      return missingEntryMap;
      //toLookDateTime.weekday
  }

  Stream<double> getSaveProgressStream(){
    return _saveProgressStreamController.stream;
  }

  void closeSaveProgressStreamController(){
    _saveProgressStreamController.close();
  }

  @override
  void cancelProgress() {
    _isCanceling = true;
  }
}

enum UploadAttempt{
  clean, dupe, conflict
}

enum DrawDayType{
  AllDraw, RegularDraw, SpecialDraw
}