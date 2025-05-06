import 'package:http/http.dart' as http;

class CheckPatch{

  static const String version = "1.12";
  static const String versionURL = "https://drive.google.com/uc?export=download&id=1Lh3xTtwbNDmuuFC1bnlaS_IyWLyZpYVY";

  static final CheckPatch _instance = CheckPatch._internal();

  static CheckPatch getInstance(){
    return _instance;
  }

  CheckPatch._internal();

  Future<double> getLatestVersion() async {
    
    try{
      String latestVersionString = await readStringFromUrl(versionURL);
      double latestVersionDouble = double.tryParse(latestVersionString) ?? -1;

      return latestVersionDouble;
    }catch(e){

      print(e);

      return -1;
    }
  }

  double getCurrentVersion(){
    return double.parse(version);
  }

  Future<bool?> requireUpdate() async {
    
    double latestVersion = await getLatestVersion();
    
    if(latestVersion < 0){
      return null;
    }
    
    return latestVersion != getCurrentVersion();
  }


  Future<String> readStringFromUrl(String url) async {
    http.Response response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    return response.body;
  }
}