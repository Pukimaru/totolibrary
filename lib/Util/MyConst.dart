import 'dart:ui';

import 'package:flutter/material.dart';

class MyConst{
    static String Key_DisplayRow = "displayRow";
    static String Key_DisplayColumn = "displayColumn";
    static String Key_DisplayFontSize = "displayFontSize";

    static String Key_DisplayYear = "displayYear";
    static String Key_DisplayMonth = "displayMonth";
    static String Key_DisplayDay = "displayDay";
    static String Key_DisplayType = "displayType";

    static String Key_WindowHeader = "window"; //+ windowName = WindowKey
    static String Key_WindowKeyList = "windowkeys";

    static String Key_PanelHeader = "panel";
    static String Key_PanelKeyList = "panelkeys";

    static String Key_NoDrawDateMap = "noDrawDateMap";

    static Color defaultHighlight = Colors.yellow;
    static Color Highlight1 = Colors.lightBlueAccent;
    static Color Highlight2 = Colors.lightGreen;
    static Color Highlight3 = Colors.orange;
    static Color Highlight4 = Colors.deepPurpleAccent.withAlpha(70);
    static Color Highlight5 = Colors.red.withAlpha(70);
    static Color Highlight6 = Colors.pinkAccent;
    static Color Highlight7 = Colors.blueGrey.withAlpha(70);
    static Color Highlight8 = Colors.brown.withAlpha(70);
    static Color Highlight9 = Colors.indigo.withAlpha(90);
    static Color Highlight10 = Colors.lightGreenAccent;
    static Color Highlight11 = Colors.grey;
    static Color Highlight12 = Colors.greenAccent;

    static DateTime EarliestScrapDate = DateTime(1985, 4, 27);


    static final List<Color> HighlightList = [
        Highlight1, Highlight2, Highlight3, Highlight4, Highlight5, Highlight6, Highlight7, Highlight8, Highlight9, Highlight10, Highlight11, Highlight12
    ];

    static final ValidSheetNameList_Lowercase = [
        "jan", "feb", "mar", "apr","may","jun","july","aug","sept","oct","nov","dec"
    ];

}