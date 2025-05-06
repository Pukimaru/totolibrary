import 'dart:ui';

import 'package:toto/Object/DayPrizesObj.dart';

class RelevantDetail{
  String prizeHovered;
  DayPrizesObj dayPrizesObjHovered;
  Offset hoverPosition;

  RelevantDetail(
    {
      required this.prizeHovered,
      required this.dayPrizesObjHovered,
      required this.hoverPosition
    }
  );
}