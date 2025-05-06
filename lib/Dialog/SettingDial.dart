import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Widget/FreePanel.dart';
import '../Window.dart';

class SettingDial extends StatefulWidget{

  WindowState? windowState;
  FreePanelState? freePanelState;

  SettingDial(
      {
        super.key,
        required this.windowState,
        required this.freePanelState,
      }
  );

  @override
  State<StatefulWidget> createState() {
      return SettingDialState();
  }

}

class SettingDialState extends State<SettingDial>{

  double labelFontSize = 16;

  TextEditingController rowTEC = TextEditingController();
  TextEditingController columnTEC = TextEditingController();
  TextEditingController fontSizeTEC = TextEditingController();

  @override
  void initState() {

    if(widget.windowState != null){
      rowTEC.text = widget.windowState!.row.toString();
      columnTEC.text = widget.windowState!.column.toString();
      fontSizeTEC.text = widget.windowState!.fontSize.toString();

    }else if(widget.freePanelState != null){

      columnTEC.text = widget.freePanelState!.column.toString();
      fontSizeTEC.text = widget.freePanelState!.fontSize.toString();

    }else{
      throw Exception();
    }


    super.initState();
  }

  @override
  Widget build(BuildContext context) {
      return Container(
        width: getThisWidth(),
        //height: getThisHeight(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.windowState != null ? Row(
                  children: [
                      Text("Row: ", style: TextStyle(fontSize: labelFontSize),),
                      const Expanded(child: SizedBox.shrink()),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: rowTEC,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder()
                          ),
                          onSubmitted: (value) async {
                            await submit();
                          },
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      )
                  ],
                ) : const SizedBox.shrink(),
                Row(
                  children: [
                    Text("Column: ", style: TextStyle(fontSize: labelFontSize),),
                    const Expanded(child: SizedBox.shrink()),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: columnTEC,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder()
                        ),
                        onSubmitted: (value) async {
                          await submit();
                        },
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    Text("FontSize: ", style: TextStyle(fontSize: labelFontSize),),
                    const Expanded(child: SizedBox.shrink()),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: fontSizeTEC,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder()
                        ),
                        onSubmitted: (value) async {
                          await submit();
                        },
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 75,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: TextButton(
                              onPressed: () {close();},
                              child: const Center(child: Text("Cancel", textAlign: TextAlign.center, style: TextStyle(fontSize: 20),), ),
                            ),
                          )
                      ),
                      Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: TextButton(
                              onPressed: () async { await submit();},
                              child: const Center(child: Text("Submit", textAlign: TextAlign.center, style: TextStyle(fontSize: 20),), ),
                            ),
                          )
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );
  }

  double getThisWidth(){
      return MediaQuery.of(context).size.width*0.5;
  }

  double getThisHeight(){
    return MediaQuery.of(context).size.width*0.8;
  }

  void close(){
    Navigator.pop(context);
  }

  Future<void> submit() async {

      if(widget.windowState != null){
        widget.windowState!.row = int.tryParse(rowTEC.text) ?? widget.windowState!.row;
        widget.windowState!.column = int.tryParse(columnTEC.text) ?? widget.windowState!.column;
        widget.windowState!.fontSize = int.tryParse(fontSizeTEC.text) ?? widget.windowState!.fontSize;
        await widget.windowState!.saveToPref();

      }else if(widget.freePanelState != null){
        widget.freePanelState!.column = int.tryParse(columnTEC.text) ?? widget.freePanelState!.column;
        widget.freePanelState!.fontSize = double.tryParse(fontSizeTEC.text) ?? widget.freePanelState!.fontSize;
        await widget.freePanelState!.saveToPref();
      }

      Navigator.pop(context, true);
  }
}