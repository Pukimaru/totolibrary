import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Util/MyConst.dart';
import '../Util/Pair.dart';

class VerifyRangeDial extends StatefulWidget{

  double fontSize;

  VerifyRangeDial(
    {
      super.key,
      required this.fontSize,
    }
  );

  @override
  State<StatefulWidget> createState() {
    return VerifyRangeDialState();
  }

}

class VerifyRangeDialState extends State<VerifyRangeDial>{

  TextEditingController startDateTEC = TextEditingController();
  TextEditingController endDateTEC = TextEditingController();

  @override
  void dispose() {
    startDateTEC.dispose();
    endDateTEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 250,
      child: Padding(
        padding: EdgeInsets.all(7),
        child: Column(
          children: [
            Text(
              "You can specify the range of date you which to verify.",
              style: TextStyle(
                fontSize: widget.fontSize-2,
              ),
            ),
            SizedBox(height: 5,),
            Text(
              "Verification is done in descending order. E.g. 2024 -> 1985\r\nIf you wish to verify everything just leave it empty.",
              style: TextStyle(
                fontSize: widget.fontSize-2,
                color: Colors.red
              ),
            ),
            SizedBox(height: 25,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  "Start Year: "
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: startDateTEC,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      isCollapsed: true,
                    ),
                    style: TextStyle(
                      fontSize: widget.fontSize,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: false,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                    "End Year: "
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: endDateTEC,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        isCollapsed: true,
                    ),
                    style: TextStyle(
                      fontSize: widget.fontSize,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: false,
                  ),
                ),
              ],
            ),
            SizedBox(height: 25,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    close();
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: widget.fontSize
                    ),
                  )
                ),
                TextButton(
                  onPressed: () {
                    verifyAndSubmit();
                  },
                  child: Text(
                    "Start",
                    style: TextStyle(
                        fontSize: widget.fontSize
                    ),
                  )
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void close(){
    Navigator.pop(context);
  }

  void verifyAndSubmit(){
    int startYear = int.tryParse(startDateTEC.text) ?? -1;
    int endYear = int.tryParse(endDateTEC.text) ?? -1;

    if((startYear == -1 && startDateTEC.text.isNotEmpty) || (endYear == -1 && endDateTEC.text.isNotEmpty)){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Invalid Input Format! Only Numbers Are Allowed"),
      ));
      return;
    }

    if(startYear != -1 && (startYear < MyConst.EarliestScrapDate.year || startYear > DateTime.now().year)){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Earliest Year Allowed is ${MyConst.EarliestScrapDate.year} and the Latest Year Allowed is ${DateTime.now().year}. Please make sure you input a valid StartYear"),
      ));
      return;
    }

    if(startYear < endYear){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("StartYear should not be before EndYear.\r\nVerification is done in descending order. E.g. 2024 -> 1985)"),
      ));
      return;
    }

    if(endYear != -1 && (endYear < MyConst.EarliestScrapDate.year || endYear > DateTime.now().year)){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Earliest Year Allowed is ${MyConst.EarliestScrapDate.year} and the Latest Year Allowed is ${DateTime.now().year}.. Please make sure you input a valid EndYear"),
      ));
      return;
    }

    Navigator.pop(context, Pair<int, int>(startYear, endYear));
  }

}