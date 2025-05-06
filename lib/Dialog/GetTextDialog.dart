import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GetTextDial extends StatefulWidget{

  double height;
  double width;
  double fontSize;
  String question;
  String subQuestion;
  FilteringTextInputFormatter? filteringTextInputFormatter;
  String Function(String)? verification;

  GetTextDial(
    {
      super.key,
      this.height = 200,
      this.width = 500,
      required this.fontSize,
      this.question = "",
      this.subQuestion = "",
      this.filteringTextInputFormatter,
      this.verification
    }
  );

  @override
  State<StatefulWidget> createState() {
    return GetTextDialState();
  }

}

class GetTextDialState extends State<GetTextDial>{

  TextEditingController textTEC = TextEditingController();
  String errorMessage = "";

  @override
  void dispose() {
    textTEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 3),
              child: Text(
                widget.question,
                style: TextStyle(
                  fontSize: widget.fontSize
                ),
                maxLines: 3,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
              child: Text(
                widget.subQuestion,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: widget.fontSize-2,
                  color: Colors.grey,
                ),
                maxLines: 5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: SizedBox(
                width: widget.width-50,
                child: Center(
                  child: TextField(
                    controller: textTEC,
                    decoration: InputDecoration(
                      border: OutlineInputBorder()
                    ),
                    onTapOutside: (event){
                      FocusScope.of(context).requestFocus(FocusNode());
                    },
                    inputFormatters: widget.filteringTextInputFormatter != null ? [ widget.filteringTextInputFormatter! ] : [],
                  ),
                ),
              ),
            ),
            const Expanded(child: SizedBox()),
            if(errorMessage.isNotEmpty) Text(errorMessage, style: TextStyle(fontSize: widget.fontSize-1, color: Colors.red, fontStyle: FontStyle.italic),),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: TextButton(
                      onPressed: () {Navigator.pop(context);},
                      child: const Center(child: Text("Cancel", textAlign: TextAlign.center, style: TextStyle(fontSize: 20),), ),
                    ),
                  )
                ),
                Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: TextButton(
                        onPressed: (){
        
                          String text = textTEC.text;
        
                          setState(() {
                            errorMessage = text.isEmpty ? "All field(s) must be fill." :
                                            widget.verification != null ? widget.verification!(text) : "";
                          });
        
                          if(errorMessage.isEmpty){
                            Navigator.pop(
                                context, textTEC.text
                            );
                          }
                        },
                        child: const Center(child: Text("Submit", textAlign: TextAlign.center, style: TextStyle(fontSize: 20),), ),
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

}