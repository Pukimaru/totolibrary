class Pair<T, K>{
  T? first;
  K? second;

  Pair(this.first, this.second);

  static Pair<T,K> copyFrom<T,K>(Pair<T,K> original){
    Pair<T,K> newPair = Pair(original.first, original.second);

    return newPair;
  }

  static List<Pair<T, K>> getPairListFromMap_BasedOnValue<T, K>(Map<T, List<K>> map){
      List<Pair<T, K>> list = [];

      for(MapEntry<T, List<K>> entry in map.entries){

          T key = entry.key;
          List<K> valueList = entry.value;

          for(K value in valueList){
            list.add(Pair(key, value));
          }
      }

      return list;
  }

  static List<Pair<T, K>> getPairListFromMap_BasedOnKey<T, K>(Map<T, K> map){
    List<Pair<T, K>> list = [];

    for(MapEntry<T, K> entry in map.entries){
        list.add(Pair(entry.key, entry.value));
    }

    return list;
  }

  static Map<T, List<K>> getMapFromPairList_KeyToValueList<T, K>(List<Pair<T, K>> list){

    Map<T, List<K>> map = {};

      for(Pair<T, K> pair in list){
          if(!map.containsKey(pair.first)){
            map[pair.first!] = [];
          }

          map[pair.first!]!.add(pair.second!);
      }

      return map;
  }

  static Map<T, K> getMapFromPairList_KeyToValue<T, K>(List<Pair<T, K>> list){

    Map<T, K> map = {};

    for(Pair<T, K> pair in list){
      if(!map.containsKey(pair.first)){
        map[pair.first!] = pair.second!;
      }else{
        throw Exception();
      }
    }

    return map;
  }

}