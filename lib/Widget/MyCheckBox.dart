import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyCheckBox extends StatefulWidget{

  bool value;
  void Function(bool? value) onChange;
  String text;
  Widget? child;
  double width;
  double fontSize;
  double checkBoxSize;
  EdgeInsets padding;

  MyCheckBox(
      {
        super.key,
        required this.value,
        required this.onChange,
        this.child,
        this.text = "",
        this.width = 100,
        this.fontSize = 18,
        this.checkBoxSize = 20,
        this.padding = const EdgeInsets.fromLTRB(0, 5, 5, 5),
      }
  );

  @override
  State<StatefulWidget> createState() {
    return _MyCheckBoxState();
  }

}

class _MyCheckBoxState extends State<MyCheckBox>{

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        widget.onChange.call(!widget.value);
      },
      child: SizedBox(
        width: widget.width,
        child: Row(
          children: [
            Flexible(
              child: Padding(
                padding: widget.padding,
                child: Material(
                  color: Colors.transparent,
                  child: widget.child ?? Text(
                    widget.text,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                    ),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: Transform.scale(
                scale: widget.checkBoxSize/20,
                child:Checkbox(
                  value: widget.value,
                  onChanged: widget.onChange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}