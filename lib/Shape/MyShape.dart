import 'dart:math';

import 'package:flutter/material.dart';

class TrapezoidPainter extends CustomPainter{

  Color color;
  MyDirection direction;
  PaintingStyle paintingStyle;

  TrapezoidPainter(
    {
      required this.direction,
      this.paintingStyle = PaintingStyle.fill,
      this.color = const Color.fromARGB(255, 33, 150, 243),
    }
  );

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint0 = Paint()
      ..color = color
      ..style = paintingStyle
      ..strokeWidth = 1;

    Path path0 = Path();

    switch(direction){
      case MyDirection.left:
        path0.moveTo(size.width*1,size.height*1);
        path0.lineTo(size.width*1,size.height*0);
        path0.lineTo(size.width*0,size.height*0.25);
        path0.lineTo(size.width*0,size.height*0.75);
        path0.lineTo(size.width*1,size.height*1);
        path0.close();
      break;

      case MyDirection.right:
        path0.moveTo(0,size.height*1);
        path0.lineTo(0,size.height*0);
        path0.lineTo(size.width*1,size.height*0.25);
        path0.lineTo(size.width*1,size.height*0.75);
        path0.lineTo(0,size.height*1);
        path0.close();
      break;

      case MyDirection.up:
        path0.moveTo(size.width*0,size.height*1);
        path0.lineTo(size.width*1,size.height*1);
        path0.lineTo(size.width*0.75,size.height*0);
        path0.lineTo(size.width*0.25,size.height*0);
        path0.lineTo(size.width*0,size.height*1);
        path0.close();
      break;

      case MyDirection.down:
        path0.moveTo(size.width*0,size.height*0);
        path0.lineTo(size.width*1,size.height*0);
        path0.lineTo(size.width*0.75,size.height*1);
        path0.lineTo(size.width*0.25,size.height*1);
        path0.lineTo(size.width*0,size.height*0);
        path0.close();
        break;
    }


    canvas.drawPath(path0, paint0);


  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}

class UpperDenturePainter extends CustomPainter{

  Color color;
  PaintingStyle paintingStyle;

  UpperDenturePainter(
      {
        this.paintingStyle = PaintingStyle.fill,
        this.color = const Color.fromARGB(255, 192, 203, 243),
      }
  );

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint0 = Paint()
      ..color = color
      ..style = paintingStyle
      ..strokeWidth = 1;

    Path path0 = Path();
    path0.moveTo(size.width/2, size.height*1);
    path0.arcToPoint(Offset(0, size.height*1), clockwise: true, radius: Radius.elliptical(size.width/2, size.height*1), rotation: pi, largeArc: true);
    //path0.arcToPoint(Offset(size.width*0.5, size.height*0));
    //path0.relativeQuadraticBezierTo(size.width*0.5, 0, size.width*0.5, 0);
    //path0.relativeQuadraticBezierTo(size.width*0.5, 0, size.width*1, size.height*1);

    final radius = size.height/2;
    final center = Offset(size.width/2, size.height);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0, -pi, false, paint0);

    canvas.drawPath(path0, paint0);


  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}

class HalfOvalPainter extends CustomPainter {

  MyDirection direction;
  Color color;
  Rect rect;

  HalfOvalPainter(
    { required this.direction,
      required this.color,
      required this.rect,
    }
  );

  @override
  void paint(Canvas canvas, Size size) {

    double rotation;
    double start;

    switch(direction){
      case MyDirection.up:
        start = 0;
        rotation = -pi;
        break;
      case MyDirection.down:
        start = 0;
        rotation = pi;
        break;
      case MyDirection.right:
        start = 0.5*pi;
        rotation = -pi;
        break;
      case MyDirection.left:
        start = 0.5*pi;
        rotation = pi;
        break;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = this.rect;
    canvas.drawArc(rect, start, rotation, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RectangularPainter extends CustomPainter{

  Color color;
  PaintingStyle paintingStyle;
  double widthStroke;

  RectangularPainter(
      {
        this.paintingStyle = PaintingStyle.stroke,
        this.color = const Color.fromARGB(255, 33, 150, 243),
        required this.widthStroke,
      }
      );

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint0 = Paint()
      ..color = color
      ..style = paintingStyle
      ..strokeWidth = widthStroke;

    Path path0 = Path();

    path0.moveTo(size.width*0,size.height*0);
    path0.lineTo(size.width*1,size.height*0);
    path0.lineTo(size.width*1,size.height*1);
    path0.lineTo(size.width*0,size.height*1);
    path0.lineTo(size.width*0,size.height*0);

    canvas.drawPath(path0, paint0);

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}


enum MyDirection{
  left,
  right,
  up,
  down,
}


