import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GlowContainer extends StatefulWidget{
  double width;
  double height;
  BoxShape boxShape;
  Widget? child;
  bool glow;

  GlowContainer(
    {
      super.key,
      required this.width,
      required this.height,
      required this.boxShape,
      required this.glow,
      required this.child,
    }
  );

  @override
  State<StatefulWidget> createState() {
      return GlowContainerState();
  }


}

class GlowContainerState extends State<GlowContainer> with SingleTickerProviderStateMixin{

  late AnimationController _animationController;
  late Animation _animation;

  bool glow = true;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animationController.repeat(reverse: true);
    _animation = Tween(begin: 2.0, end: 15.0).animate(_animationController);
    _animation.addListener(() {
      setState(() {

      });
    });

    glow = widget.glow;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
        width: widget.width,
        height: widget.height,
        child: widget.child,
        decoration: BoxDecoration(
          shape: widget.boxShape,
          color: Colors.white,
          boxShadow: glow ? [
            BoxShadow(
              color: const Color.fromARGB(130, 237, 125, 50),
              blurRadius: _animation.value,
              spreadRadius: _animation.value,
            ),
            BoxShadow(
              color: const Color.fromARGB(100, 245, 175, 30),
              blurRadius: _animation.value*1.5,
              spreadRadius: _animation.value*1.5,
            )
          ] : []
        ),
    );
  }

  void setGlow(bool glow){
    setState(() {
      this.glow = glow;
    });
  }
}