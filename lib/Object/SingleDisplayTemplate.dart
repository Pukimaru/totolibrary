import '../Util/Pair.dart';
import 'DayPrizesObj.dart';
import 'PrizeObj.dart';

class SingleDisplayTemplate{
  String key_String;
  String type;
  List<Pair<String, PrizeObj>> value_PrizeObj_List;

  SingleDisplayTemplate(
    this.key_String,
    this.type,
    this.value_PrizeObj_List
  );

  Pair<String, PrizeObj> getPair(int index){
      return value_PrizeObj_List[index];
  }

  printDetail(){
    for(Pair<String, PrizeObj> pair in value_PrizeObj_List){
      pair.second!.printDetail();
    }
    print(value_PrizeObj_List.length);
  }
}