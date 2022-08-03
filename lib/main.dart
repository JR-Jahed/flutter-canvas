import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:vector_math/vector_math_64.dart' as vmath;

void main() {
  runApp(const MaterialApp(
      home: HomePage()
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}


Matrix4 downMat = Matrix4.identity();
Matrix4 opMat = Matrix4.identity();
Matrix4 finalMat = Matrix4.identity();



List<Pair<Offset, double>> curCircles = [];

double prWidth = -1, prHeight = -1;

double totalScaleX = 1, totalScaleY = 1;
double prDist = 0;

double curX = -1, curY = -1;

class _HomePageState extends State<HomePage> {

  double padLeft = 0.0, padTop = 0.0;

  double tapX = 0.0, tapY = 0.0;
  double lastX = 0.0, lastY = 0.0;
  double dragFinishX = 0.0, dragFinishY = 0.0;

  bool dragging = false;
  bool rect = false;
  bool circleSelected = false;

  int idxOfSelectedCircle = -1;

  double curWidthRect = -1, curHeightRect = -1;


  /// *****

  bool zoomedIn = false;

  /// *****


  @override
  void initState() {
    super.initState();
  }

  double distance(double x1, double y1, double x2, double y2) {
    return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
  }

  bool _insideRect(double x, double y) {
    return x >=finalMat.getTranslation().x &&
        x <= Painter.curWidthRect * finalMat.storage[0] + finalMat.getTranslation().x &&
        y >=finalMat.getTranslation().y &&
        y <= Painter.curHeightRect * finalMat.storage[5] + finalMat.getTranslation().y;
  }

  int _insideCircle(double x, double y) {
    List<Offset> tmp = [];
    tmp.add(Offset(finalMat.getTranslation().x, finalMat.getTranslation().y));
    tmp.add(Offset(Painter.curWidthRect * finalMat.storage[0] + finalMat.getTranslation().x, finalMat.getTranslation().y));
    tmp.add(Offset(finalMat.getTranslation().x, Painter.curHeightRect * finalMat.storage[5] + finalMat.getTranslation().y));
    tmp.add(Offset(Painter.curWidthRect * finalMat.storage[0] + finalMat.getTranslation().x,
        Painter.curHeightRect * finalMat.storage[5] + finalMat.getTranslation().y));
    //tmp.add(Offset(Painter.curWidthRect / 2, Painter.curHeightRect * 2));

    for (int i = 0; i < tmp.length; i++) {
      final o = tmp[i];
      if (x >= o.dx - 20 * finalMat.storage[0] &&
          x <= o.dx + 20 * finalMat.storage[0] &&
          y >= o.dy - 20 * finalMat.storage[5] &&
          y <= o.dy + 20 * finalMat.storage[5]) {
        return i;
      }
    }
    return -1;
  }

  void scale(double sX, sY) {
    opMat.setFrom(downMat);
    opMat.scale(sX, sY);
    finalMat.setFrom(opMat);
  }

  void translate(double tX, double tY) {
    opMat.setFrom(downMat);
    opMat.translate(tX, tY);
    finalMat.setFrom(opMat);
  }

  void rotate(double r) {
    opMat.setFrom(downMat);
    opMat.rotateZ(r);
    finalMat.setFrom(opMat);
  }

  @override
  Widget build(BuildContext context) {
    padLeft = MediaQuery.of(context).padding.left;
    padTop = MediaQuery.of(context).padding.top;

    return Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraint) {
              return GestureDetector(

                  onTapDown: (details) {
                    lastX = details.globalPosition.dx - padLeft;
                    lastY = details.globalPosition.dy - padTop;
                    tapX = lastX;
                    tapY = lastY;

                    downMat.setFrom(finalMat);

                    idxOfSelectedCircle = _insideCircle(tapX, tapY);

                    if(curX == -1 && curY == -1) {
                      curX = Painter.curWidthRect / 2;
                      curY = Painter.curHeightRect / 2;
                    }

                    if(curWidthRect == -1 && curHeightRect == -1) {
                      curWidthRect = Painter.curWidthRect;
                      curHeightRect = Painter.curHeightRect;
                    }

                    prWidth = curWidthRect;
                    prHeight = curHeightRect;

                    if(idxOfSelectedCircle != -1) {
                      setState(() {
                        circleSelected = true;
                        curCircles[idxOfSelectedCircle].second = 10;
                      });
                    }
                  },

                  onTapUp: (details) {
                    double x = details.globalPosition.dx - padLeft;
                    double y = details.globalPosition.dy - padTop;
                    idxOfSelectedCircle = _insideCircle(x, y);

                    if(idxOfSelectedCircle != -1) {
                      setState(() {
                        circleSelected = false;
                        curCircles[idxOfSelectedCircle].second = 5;
                      });
                    }
                  },

                  onTap: () {
                    setState(() {
                      rect = _insideRect(lastX, lastY);
                    }
                    );
                  },

                  onPanStart: (details) {
                    lastX = details.globalPosition.dx - padLeft;
                    lastY = details.globalPosition.dy - padTop;
                    dragging = _insideRect(lastX, lastY);
                    idxOfSelectedCircle = _insideCircle(tapX, tapY);

                    if(curWidthRect == -1 && curHeightRect == -1) {
                      curWidthRect = Painter.curWidthRect;
                      curHeightRect = Painter.curHeightRect;
                    }

                    downMat.setFrom(finalMat);

                    prWidth = curWidthRect;
                    prHeight = curHeightRect;

                    if(idxOfSelectedCircle != -1) {
                      setState(() {
                        circleSelected = true;
                        curCircles[idxOfSelectedCircle].second = 10;
                      });
                    }
                  },

                  onPanUpdate: (details) {

                    double x = details.globalPosition.dx - padLeft;
                    double y = details.globalPosition.dy - padTop;

                    dragFinishX = x;
                    dragFinishY = y;

                    if(idxOfSelectedCircle != -1) {

                      double tx = finalMat.getTranslation().x;
                      double ty = finalMat.getTranslation().y;

                      double scaleX = (x - tx) / prWidth;
                      double scaleY = (y - ty) / prHeight;

                      scale(scaleX, scaleY);

                      curWidthRect = prWidth * scaleX;
                      curHeightRect = prHeight * scaleY;

                      setState(() {});
                    }
                    double dx = x - lastX;
                    double dy = y - lastY;

                    if(dragging && idxOfSelectedCircle == -1)  {
                      translate(dx / finalMat.storage[0], dy / finalMat.storage[5]);
                      setState(() {});
                    }
                  },

                  onPanEnd: (details) {
                    dragging = false;

                    if(idxOfSelectedCircle != -1) {
                      setState(() {
                        curCircles[idxOfSelectedCircle].second = 5;
                      });
                    }
                  },

                  /**************************/

                  // onDoubleTap: () {
                  //
                  //   if(zoomedIn) {
                  //     scale(.75, .75);
                  //   }
                  //   else {
                  //     scale(1.5, 1.5);
                  //   }
                  //
                  //   setState(() {});
                  //   zoomedIn = !zoomedIn;
                  // },

                  /*************************/

                  child: CustomPaint(
                    painter: Painter(
                      rect: rect,
                      curCirclesPainter: curCircles,
                    ),
                    child: Container(),
                  )
              );
            },
          ),
        )
    );
  }
}

class Painter extends CustomPainter {

  final bool rect;
  List<Pair<Offset, double>> curCirclesPainter;

  Painter({
    required this.rect,
    required this.curCirclesPainter,
  });

  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..color = Colors.yellow;

  final Paint _paintRed = Paint()
    ..color = Colors.red;

  final Paint _paintGreen = Paint()
    ..color = Colors.green;

  static final TextPainter textPainter = TextPainter(
    text: const TextSpan(
      text: 'HELLO',
      style: TextStyle(
        color: Colors.black,
        fontSize: 30,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  );

  static final double curWidthRect = textPainter.width + 10, curHeightRect = textPainter.height + 10;

  @override
  void paint(Canvas canvas, Size size) {

    canvas.transform(finalMat.storage);

    textPainter.layout(maxWidth: size.width - 20 - 15);

    textPainter.paint(canvas, const Offset(5, 5));

    if(rect) {
      canvas.drawRect(Rect.fromLTWH(0, 0, curWidthRect, curHeightRect), _paint);

      if(!find(const Offset(0, 0))) {
        curCirclesPainter.add(Pair(first: const Offset(0, 0), second: 5));
      }
      if(!find(Offset(curWidthRect, 0))) {
        curCirclesPainter.add(Pair(first: Offset(curWidthRect, 0), second: 5));
      }
      if(!find(Offset(0, curHeightRect))) {
        curCirclesPainter.add(Pair(first: Offset(0, curHeightRect), second: 5));
      }
      if(!find(Offset(curWidthRect, curHeightRect))) {
        curCirclesPainter.add(Pair(first: Offset(curWidthRect, curHeightRect), second: 5));
      }
      if(!find(Offset(curWidthRect / 2, curHeightRect * 2))) {
        curCirclesPainter.add(Pair(first: Offset(curWidthRect / 2, curHeightRect * 2), second: 5));
      }

      curCircles = curCirclesPainter;

      //print('cu')

      for (Pair p in curCirclesPainter) {
        canvas.drawCircle(
            p.first,
            p.second,
            (p == curCirclesPainter.last ? _paintRed : _paintGreen));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  bool find(Offset offset) {
    for (final p in curCirclesPainter) {
      if (p.first == offset) return true;
    }
    return false;
  }
}

class Pair<T, U> {
  T first;
  U second;

  Pair({
    required this.first,
    required this.second
  });
}
