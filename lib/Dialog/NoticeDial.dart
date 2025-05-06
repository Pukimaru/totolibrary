import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NoticeDial extends StatefulWidget{

  double height;
  double width;
  double fontSize;
  String notice;
  String subNotice;

  NoticeDial(
    {
      super.key,
      this.height = 200,
      this.width = 500,
      required this.fontSize,
      this.notice = "",
      this.subNotice = "",
    }
  );

  @override
  State<StatefulWidget> createState() {
    return NoticeDialState();
  }

}

class NoticeDialState extends State<NoticeDial>{
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 3),
            child: Text(
              widget.notice,
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
                widget.subNotice,
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
                      onPressed: () {Navigator.pop(context, true);},
                      child: const Center(child: Text("OK", textAlign: TextAlign.center, style: TextStyle(fontSize: 20),), ),
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