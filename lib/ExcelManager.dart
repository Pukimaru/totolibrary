import 'dart:io';

import 'package:excel/excel.dart';
import 'package:toto/Object/DayPrizesObj.dart';
import 'package:toto/Object/PrizeObj.dart';
import 'package:toto/Util/MyConst.dart';

class ExcelManager{
  static Future<List<DayPrizesObj>> extract(String filePath) async {

    var bytes = File(filePath).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    bool prevIsDate = false;
    List<DayPrizesObj> dayPrizesObjList = [];
    DayPrizesObj? dayPrizesObj;

    for (var table in excel.tables.keys) {
      if(!MyConst.ValidSheetNameList_Lowercase.contains( table.toLowerCase() )){
        continue;
      }

      for (var row in excel.tables[table]!.rows) {
        for(var cell in row){
          if(cell != null){
            String value = cell.value.toString();
            String type = "";

            //Handle certain dates have no DRAW therefore the cell beside date will be empty
            if(value.isEmpty || value.toLowerCase().contains("null")){
              if(prevIsDate){
                prevIsDate = false;
              }
              continue;
            }

            if(filePath.toLowerCase().contains("magnum")){
                type = PrizeObj.TYPE_MAGNUM4D;
            }else if(filePath.toLowerCase().contains("toto")){
                type = PrizeObj.TYPE_TOTO;
            }else if(filePath.toLowerCase().contains("damacai")){
                type = PrizeObj.TYPE_DAMACAI;
            }else{
                throw Exception();
            }

            value = value + type;

            bool isDate = value.contains("T00:");

            if(isDate){
              dayPrizesObj = DayPrizesObj();
              dayPrizesObj.setDateTime(value);

            }else if(prevIsDate){
              if(dayPrizesObj != null){
                try{
                  dayPrizesObj.setPrize(value);
                }catch(e){
                  print("value: $value");
                  print("table: $table");
                  print("row: ${row.toString()}");
                  print("cell: ${cell.cellIndex}");
                  throw Exception();
                }

                //print("$table, ${cell.cellIndex}");
                //dayPrizesObj.printDetail();

                dayPrizesObjList.add(dayPrizesObj);
              }
            }

            prevIsDate = isDate;
          }
        }
      }
    }

    for(DayPrizesObj dayPrizesObj in dayPrizesObjList){
      //dayPrizesObj.printDetail();
    }

    return dayPrizesObjList;
    print("Hello?");
  }
}