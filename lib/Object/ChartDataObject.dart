import 'dart:convert';

import '../Util/Pair.dart';
import 'DayPrizesObj.dart';

class ChartDataObject{
  String label;
  List<DayPrizesObj> dayPrizesObjList;
  List<DayPrizesObj> filteredDayPrizesObjList = [];

  ChartDataObject({
    required this.label,
    required this.dayPrizesObjList,
  });

  void setFilteredDayPrizesObjList(List<DayPrizesObj> list){
    filteredDayPrizesObjList.clear();
    filteredDayPrizesObjList = List.from(list);
  }

  String getEncodedJson(){

    Map<String, dynamic> json = {
      "label": label,
      "dayPrizesObjListString": dayPrizesObjList.map<String>((e) => e.getUniqueKey()).toList(),
    };

    return jsonEncode(json);
  }

  static ChartDataObject fromJson(String encodedJson){
    Map<String, dynamic> json = jsonDecode(encodedJson);

    ChartDataObject chartDataObject = ChartDataObject(
      label: json["label"],
      dayPrizesObjList: List.from(json["dayPrizesObjListString"]).map<DayPrizesObj>((e) => DayPrizesObj.getDayPrizesObjWithUniqueKey(e)!).toList(),
    );


    return chartDataObject;
  }

  static List<ChartDataObject> getDataObjectList(List<Pair<String, List<DayPrizesObj>>> pairList){
    List<ChartDataObject> lineObjectList = pairList.map<ChartDataObject>((e) => ChartDataObject(label: e.first!, dayPrizesObjList: e.second!)).toList();

    return lineObjectList;
  }
}