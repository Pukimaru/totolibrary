import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConfirmationDial extends StatefulWidget{

  double height;
  double width;
  double fontSize;
  String question;
  String subQuestion;

  ConfirmationDial(
    {
      super.key,
      this.height = 200,
      this.width = 500,
      required this.fontSize,
      this.question = "",
      this.subQuestion = "",
    }
  );

  @override
  State<StatefulWidget> createState() {
    return ConfirmationDialState();
  }

}

class ConfirmationDialState extends State<ConfirmationDial>{
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
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
            child: Center(
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
          ),
          const Expanded(child: SizedBox()),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: TextButton(
                    onPressed: () {Navigator.pop(context, false);},
                    child: const Center(child: Text("No", textAlign: TextAlign.center, style: TextStyle(fontSize: 20),), ),
                  ),
                )
              ),
              Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: TextButton(
                      onPressed: () {Navigator.pop(context, true);},
                      child: const Center(child: Text("Yes", textAlign: TextAlign.center, style: TextStyle(fontSize: 20),), ),
                    ),
                  )
              ),
            ],
          )
        ],
      ),
    );
  }

}