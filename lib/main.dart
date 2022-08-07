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

double rotatedAngle = 0;

const double mnWidthRect = 20, mnHeightRect = 10;


class _HomePageState extends State<HomePage> {

  double padLeft = 0.0, padTop = 0.0;

  double tapX = -1, tapY = -1;
  double lastX = -1, lastY = -1;
  double dragFinishX = 0.0, dragFinishY = 0.0;

  bool dragging = false;
  bool rect = false;
  bool circleSelected = false;

  int idxOfSelectedCircle = -1;

  double curWidthRect = -1, curHeightRect = -1;

  double midX = 0, midY = 0;

  double curRotation = 0;

  double ratio = 0;

  bool maintainRatio = false;

  bool _insideRect(double x, double y) {
    return x >= finalMat.getTranslation().x &&
        x <= curWidthRect + finalMat.getTranslation().x &&
        y >= finalMat.getTranslation().y &&
        y <= curHeightRect + finalMat.getTranslation().y;
  }

  bool _insideRect2(double x, double y) {

    return x >=finalMat.getTranslation().x * cos(degToRad(rotatedAngle)) &&
        x <= curWidthRect + finalMat.getTranslation().x * cos(degToRad(degToRad(rotatedAngle))) &&
        y >=finalMat.getTranslation().y * sin(degToRad(rotatedAngle)) &&
        y <= curHeightRect + finalMat.getTranslation().y * sin(degToRad(rotatedAngle));
  }

  int _insideCircle(double x, double y) {
    if(!rect || curCircles.isEmpty) return -1;

    List<Offset> tmp = [];
    tmp.add(Offset(finalMat.getTranslation().x, finalMat.getTranslation().y));
    tmp.add(Offset(curWidthRect + finalMat.getTranslation().x, finalMat.getTranslation().y));
    tmp.add(Offset(finalMat.getTranslation().x, curHeightRect + finalMat.getTranslation().y));
    tmp.add(Offset(curWidthRect + finalMat.getTranslation().x, curHeightRect + finalMat.getTranslation().y));
    tmp.add(Offset(curWidthRect / 2 + finalMat.getTranslation().x,
        curHeightRect * 2 + finalMat.getTranslation().y));

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

  void calculateMid() {

    midX = finalMat.getTranslation().x + curWidthRect / 2;
    midY = finalMat.getTranslation().y + curHeightRect / 2;
  }
  double degToRad(double deg) {
    return deg * pi / 180;
  }
  double radToDeg(double rad) {
    return rad * 180 / pi;
  }

  void scale(double sX, double sY, double tX, double tY) {
    opMat.setFrom(downMat);
    opMat.translate(tX, tY);
    opMat.scale(sX, sY);
    opMat.translate(-tX, -tY);
    finalMat.setFrom(opMat);
  }

  void translate(double tX, double tY) {
    opMat.setFrom(downMat);
    opMat.translate(tX, tY);
    finalMat.setFrom(opMat);
  }

  void rotate(double r, double tX, double tY) {
    opMat.setFrom(downMat);
    opMat.translate(tX, tY);
    opMat.rotateZ(r);
    opMat.translate(-tX, -tY);
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
                    tapX = details.globalPosition.dx - padLeft;
                    tapY = details.globalPosition.dy - padTop;

                    lastX = tapX;
                    lastY = tapY;

                    downMat.setFrom(finalMat);

                    idxOfSelectedCircle = _insideCircle(lastX, lastY);

                    ratio = curHeightRect / curWidthRect;

                    print('tapdown  $tapX  $tapY');

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
                    tapX = tapY = -1;
                    double x = details.globalPosition.dx - padLeft;
                    double y = details.globalPosition.dy - padTop;
                    idxOfSelectedCircle = _insideCircle(x, y);

                    //print('tapup   $idxOfSelectedCircle');

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
                    });
                  },

                  onPanStart: (details) {

                    if(tapX == -1 && tapY == -1) {
                      lastX = details.globalPosition.dx - padLeft;
                      lastY = details.globalPosition.dy - padTop;
                    }
                    dragging = _insideRect(lastX, lastY);

                    if(curWidthRect == -1 && curHeightRect == -1) {
                      curWidthRect = Painter.curWidthRect;
                      curHeightRect = Painter.curHeightRect;
                    }

                    downMat.setFrom(finalMat);

                    prWidth = curWidthRect;
                    prHeight = curHeightRect;

                    if(idxOfSelectedCircle == -1) {
                      idxOfSelectedCircle = _insideCircle(lastX, lastY);

                      if (idxOfSelectedCircle != -1) {
                        setState(() {
                          circleSelected = true;
                          curCircles[idxOfSelectedCircle].second = 10;
                        });
                      }
                    }
                    //print('panstart   $idxOfSelectedCircle');
                  },

                  onPanUpdate: (details) {

                    double x = details.globalPosition.dx - padLeft;
                    double y = details.globalPosition.dy - padTop;

                    dragFinishX = x;
                    dragFinishY = y;

                    double dx = x - lastX;
                    double dy = y - lastY;

                    if(idxOfSelectedCircle >= 0 && idxOfSelectedCircle <= 3) {
                      double scaleX = 1, scaleY = 1;

                      if(maintainRatio) {

                        double ddx = 0;

                        if(idxOfSelectedCircle == 0) {
                          ddx = (dx + dy) / 2;
                        }
                        else if(idxOfSelectedCircle == 1) {
                          ddx = (-dx + dy) / 2;
                        }
                        else if(idxOfSelectedCircle == 2) {
                          ddx = (dx - dy) / 2;
                        }
                        else {
                          ddx = (-dx - dy) / 2;
                        }

                        scaleX = (prWidth - ddx * 2) / prWidth;
                        scaleY = (prHeight - ddx * ratio * 2) / prHeight;
                      }
                      else {
                        double ddx = 0, ddy = 0;

                        calculateMid();

                        if (idxOfSelectedCircle == 0) {
                          if(x <= midX) {
                            ddx = dx;
                          }
                          else {
                            ddx = min((midX - mnWidthRect / 2), x) - lastX;
                          }

                          if(y <= midY - mnHeightRect / 2) {
                            ddy = dy;
                          }
                          else {
                            ddy = min((midY - mnHeightRect / 2), y) - lastY;
                          }
                        }
                        else if (idxOfSelectedCircle == 1) {
                          if(x >= midX + mnWidthRect / 2) {
                            ddx = -dx;
                          }
                          else {
                            ddx = -(max((midX + mnWidthRect / 2), x) - lastX);
                          }

                          if(y <= midY - 10) {
                            ddy = dy;
                          }
                          else {
                            ddy = min((midY - mnHeightRect / 2), y) - lastY;
                          }
                        }
                        else if (idxOfSelectedCircle == 2) {
                          if(x <= midX - mnWidthRect / 2) {
                            ddx = dx;
                          }
                          else {
                            ddx = min((midX - mnWidthRect / 2), x) - lastX;
                          }

                          if(y >= midY + mnHeightRect / 2) {
                            ddy = -dy;
                          }
                          else {
                            ddy = -(max((midY + mnHeightRect / 2), y) - lastY);
                          }
                        }
                        else {
                          if(x >= midX + mnWidthRect / 2) {
                            ddx = -dx;
                          }
                          else {
                            ddx = -(max((midX + mnWidthRect / 2), x) - lastX);
                          }

                          if(y >= midY + mnHeightRect / 2) {
                            ddy = -dy;
                          }
                          else {
                            ddy = -(max((midY + mnHeightRect / 2), y) - lastY);
                          }
                        }
                        scaleX = (prWidth - ddx * 2) / prWidth;
                        scaleY = (prHeight - ddy * 2) / prHeight;
                      }

                      double nextWidthRect = prWidth * scaleX;
                      double nextHeightRect = prHeight * scaleY;

                        if(nextWidthRect >= mnWidthRect && nextHeightRect >= mnHeightRect) {
                          double tX = (Painter.curWidthRect / 2),
                              tY = (Painter.curHeightRect / 2);

                          scale(scaleX, scaleY, tX, tY);
                          curWidthRect = nextWidthRect;
                          curHeightRect = nextHeightRect;
                          setState(() {});
                        }

                    }
                    else if(idxOfSelectedCircle == 4) {

                      calculateMid();

                      double ddx = midX - x;
                      double ddy = y - midY;

                      double tX = Painter.curWidthRect / 2, tY = Painter.curHeightRect / 2;

                      double angle = atan(ddx / ddy);
                      //print('$angle   $ddx   $ddy   midx = $midX  midy = $midY tX = ${finalMat.getTranslation().x} tY = ${finalMat.getTranslation().y}');
                      rotate(angle, tX, tY);
                      setState(() {});
                    }

                    if(dragging && idxOfSelectedCircle == -1)  {
                      translate(dx / finalMat.storage[0], dy / finalMat.storage[5]);
                      setState(() {});
                    }
                  },

                  onPanEnd: (details) {
                    dragging = false;

                    tapX = tapY = -1;

                    //print('panend   $idxOfSelectedCircle');

                    if(idxOfSelectedCircle != -1) {
                      setState(() {
                        curCircles[idxOfSelectedCircle].second = 5;
                      });
                      idxOfSelectedCircle = -1;
                    }
                  },

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
    ..color = Colors.blue;

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
  static double tX = -1, tY = -1;

  @override
  void paint(Canvas canvas, Size size) {

    if(tX != -1 && tY != -1) {
      canvas.translate(tX, tY);
    }

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

      for (Pair p in curCirclesPainter) {
        canvas.drawCircle(
            p.first,
            p.second,
            (p == curCirclesPainter.last ? _paintGreen : _paintRed));
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
