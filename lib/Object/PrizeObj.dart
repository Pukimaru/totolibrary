import 'dart:ui';

import 'package:toto/Object/DayPrizesObj.dart';
import 'package:toto/Window.dart';

import '../Util/MyConst.dart';
import '../Util/Pair.dart';

class PrizeObj{

  DayPrizesObj dayPrizesObj;
  DateTime dateTime;

  int place;

  String digit1;
  String digit2;
  String digit3;
  String digit4;
  String digit5;
  String digit6;

  String type;

  static const String TYPE_ALL = "ALL";
  static const String TYPE_TOTO = "TOTO";
  static const String TYPE_MAGNUM4D = "MAGNUM";
  static const String TYPE_DAMACAI = "DAMACAI";

  PrizeObj(
      this.dayPrizesObj,
      String prizeString,
      this.type,
      this.place,
      this.dateTime
  ): digit1 = prizeString[0],
     digit2 = prizeString[1],
     digit3 = prizeString[2],
     digit4 = prizeString[3],
     digit5 = prizeString.length >= 5 ? prizeString[4] : "",
     digit6 = prizeString.length >= 6 ? prizeString[5] : "";

  printDetail(){
    print("${DayPrizesObj.dateFormatCommonShort.format(dateTime)} - (${(place == 1 ? "1st" : place == 2 ? "2nd" : "3rd")}) $digit1$digit2$digit3$digit4 [$type]");
  }

  String getFullString(){
    return "$digit1$digit2$digit3$digit4$digit5$digit6";
  }

  Color? getColorForPosition(String? defaultRevelantString,List<Pair<String, Color>> sortedFilterStringColorPairList, int position){ //position starts from 1

    Pair<String, Color>? pair;

    pair = checkDefaultRelevantString(defaultRevelantString);
    if(pair != null){

      String matchedEntry = pair.first!;

      if(matchedEntry.isEmpty || position > matchedEntry.length){return null;}

      if(matchedEntry.substring(position-1, position) == getFullString().substring(position-1, position)){
        return pair.second;
      }

      return null;
    }

    pair = checkFilterFormulaList(sortedFilterStringColorPairList);
    if(pair != null){
        return pair.second;
    }


    return null;
  }

  Pair<String, Color>? checkDefaultRelevantString(String? defaultRevelantString){
    //List<String> stringList = List.from(revelantStringList);

    String? entry = defaultRevelantString;

    if(entry == null){return null;}

    int matchedCount = 0;
    int maxConsequtiveCount = 0;
    int consequtiveCount = 0;

    bool prevMatched = false;

    for(int i = 0; i < entry.length; i++){

      String entryChar = entry.substring(i, i+1);
      String prizeObjChar = getFullString().substring(i, i+1);

      if(entryChar == prizeObjChar){
          matchedCount++;
          if(prevMatched){
            consequtiveCount++;
          }else{
            consequtiveCount = 1;
            prevMatched = true;
          }
      }else{
          if(consequtiveCount > maxConsequtiveCount){
              maxConsequtiveCount = consequtiveCount;
          }
          consequtiveCount = 0;
          prevMatched = false;
      }
    }

    if(consequtiveCount >= 3){//(matchedCount >= 3 || consequtiveCount >= 2){
      return Pair<String,Color>(entry, MyConst.defaultHighlight);
    }

    return null;
  }

  Pair<String, Color>? checkFilterFormulaList(List<Pair<String, Color>> sortedFilterStringColorPairList){

      for(int i = 0; i < sortedFilterStringColorPairList.length; i++){

          String filterString = sortedFilterStringColorPairList[i].first!;
          Color color = sortedFilterStringColorPairList[i].second!;

          String? let_X_Be;
          String? let_Y_Be;
          String? let_Z_Be;

          bool discrepancy = false;
          for(int i = 0; i < filterString.length; i++){
            String prizeStringChar = getFullString()[i];
            String filterChar = filterString[i];

            switch(filterChar){
              case "?":
                continue;

              case "x":
                //check if it matches registered "x"
                if(let_X_Be != null){
                  if(prizeStringChar != let_X_Be){
                    discrepancy = true;
                  }
                }
                //check if it matches other variable (cannot match other variable) e.g. 4444 shouldn't match "xyxy"
                else if( (let_Y_Be != null && prizeStringChar == let_Y_Be) || (let_Z_Be != null && prizeStringChar == let_Z_Be)){
                  discrepancy = true;
                }
                //register "x"
                else{
                  let_X_Be = prizeStringChar;
                }
                break;

              case "y":
                if(let_Y_Be != null){
                  if(prizeStringChar != let_Y_Be){
                    discrepancy = true;
                  }
                }else if( (let_X_Be != null && prizeStringChar == let_X_Be) || (let_Z_Be != null && prizeStringChar == let_Z_Be)){
                  discrepancy = true;
                }else{
                  let_Y_Be = prizeStringChar;
                }
                break;

              case "z":
                if(let_Z_Be != null){
                  if(prizeStringChar != let_Z_Be){
                    discrepancy = true;
                  }
                }else if( (let_X_Be != null && prizeStringChar == let_X_Be) || (let_Y_Be != null && prizeStringChar == let_Y_Be)){
                  discrepancy = true;
                }else{
                  let_Z_Be = prizeStringChar;
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
            return Pair<String, Color>(filterString, color);
          }
      }

      return null;
  }
}