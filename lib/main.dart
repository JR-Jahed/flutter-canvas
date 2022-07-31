import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:vector_math/vector_math_64.dart' as vmath;

void main() {
  runApp(const MaterialApp(
    home: HomePage(),
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double xPos = 0;
  double yPos = 0;
  bool dragging = false;

  double scaleX = 1.0, scaleY = 1.0;
  double tX = 0.0, tY = 0.0;
  double rotateAngle = 0.0;
  bool zoomedIn = false;
  bool rect = false;

  List<Pair<Offset, double>> curCircles = [];

  double tapX = 0.0, tapY = 0.0;

  double widthAtBeginningOfDrag = 0.0;
  double heightAtBeginningOfDrag = 0.0;

  double padTop = 0.0;

  bool circleSelectedForScale = false;

  bool _insideRect2(double x, double y) =>
      x >= Painter.curOffset.dx + MediaQuery.of(context).padding.left &&
      x <= Painter.curOffset.dx + MediaQuery.of(context).padding.left + Painter.curWidthRect &&
      y >= Painter.curOffset.dy + MediaQuery.of(context).padding.top &&
      y <= Painter.curOffset.dy + MediaQuery.of(context).padding.top + Painter.curHeightRect;

  bool _insideRect(double x, double y) =>
      x >= xPos + MediaQuery.of(context).padding.left &&
      x <= xPos + MediaQuery.of(context).padding.left + Painter.curWidthRect &&
      y >= yPos + MediaQuery.of(context).padding.top &&
      y <= yPos + MediaQuery.of(context).padding.top + Painter.curHeightRect;

  int _insideCircle(double x, double y) {
    for (int i = 0; i < curCircles.length; i++) {
      final o = curCircles[i].first;
      if (x >= o.dx - 20 + MediaQuery.of(context).padding.left &&
          x <= o.dx + 20 + MediaQuery.of(context).padding.left &&
          y >= o.dy - 20 + MediaQuery.of(context).padding.top &&
          y <= o.dy + 20 + MediaQuery.of(context).padding.top) {
        return i;
      }
    }
    return -1;
  }

  int _insideCircle2(double x, double y) {

    List<Offset> tmp = [];
    tmp.add(Painter.curOffset);
    tmp.add(Offset(Painter.curOffset.dx + Painter.curWidthRect, Painter.curOffset.dy));
    tmp.add(Offset(Painter.curOffset.dx, Painter.curOffset.dy + Painter.curHeightRect));
    tmp.add(Offset(Painter.curOffset.dx + Painter.curWidthRect, Painter.curOffset.dy + Painter.curHeightRect));
    tmp.add(Offset(Painter.curOffset.dx + Painter.curWidthRect / 2, Painter.curOffset.dy + Painter.curHeightRect * 2));

    for (int i = 0; i < tmp.length; i++) {
      final o = tmp[i];
      if (x >= o.dx - 20 + MediaQuery.of(context).padding.left &&
          x <= o.dx + 20 + MediaQuery.of(context).padding.left &&
          y >= o.dy - 20 + MediaQuery.of(context).padding.top &&
          y <= o.dy + 20 + MediaQuery.of(context).padding.top) {
        return i;
      }
    }
    return -1;
  }

  double degToRad(double deg) {
    return deg * pi / 180.0;
  }
  double radToDeg(double rad) {
    return rad * 180.0 / pi;
  }

  @override
  Widget build(BuildContext context) {
    padTop = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          return GestureDetector(
            onTapDown: (details) {

              tapX = details.globalPosition.dx;
              tapY = details.globalPosition.dy;

              curCircles = Painter.curCirclesStatic;
              final idx = _insideCircle2(
                  details.globalPosition.dx, details.globalPosition.dy);

              if (idx != -1) {
                setState(() {
                  circleSelectedForScale = true;
                  curCircles[idx].second = 10;
                });
              }

              widthAtBeginningOfDrag = Painter.curWidthRect - 10;
              heightAtBeginningOfDrag = Painter.curHeightRect - 10;
            },
            onTapUp: (details) {
              final idx = _insideCircle2(details.globalPosition.dx, details.globalPosition.dy);
              if (idx != -1) {
                setState(() {
                  circleSelectedForScale = false;
                  curCircles[idx].second = 5;
                });
              }
            },
            onTap: () {

              setState(() {
                rect = _insideRect2(tapX, tapY);
              });
            },
            onPanStart: (details) {
              dragging = _insideRect2(details.globalPosition.dx, details.globalPosition.dy);
              widthAtBeginningOfDrag = Painter.curWidthRect - 10;
              heightAtBeginningOfDrag = Painter.curHeightRect - 10;
            },

            onPanUpdate: (details) {
              final x = details.globalPosition.dx;
              double y = details.globalPosition.dy;

              final idx = _insideCircle2(x, y);

              y -= padTop;

              if(circleSelectedForScale) {
                final midX = Painter.textBeginX + widthAtBeginningOfDrag / 2;
                final midY = Painter.textBeginY + heightAtBeginningOfDrag / 2;
                final widthFromMidUntilCurPoint = (x - midX).abs();
                final heightFromMidUntilCurPoint = (y - midY).abs();

                // if(curCircles.length > 1) {
                //   print('${curCircles[0].first.dx}  ${curCircles[0].first.dy} '
                //       ' ---  ${curCircles[1].first.dx}  ${curCircles[1].first
                //       .dy}');
                // }

                if(idx != 4) {
                  setState(() {
                    curCircles.clear();
                    scaleX = widthFromMidUntilCurPoint / (widthAtBeginningOfDrag / 2);
                    scaleY = heightFromMidUntilCurPoint / (heightAtBeginningOfDrag / 2);
                  });
                }
                else {

                  double angle = 0.0;

                  if(widthFromMidUntilCurPoint != 0) {
                    double angleRad = atan(heightFromMidUntilCurPoint / widthFromMidUntilCurPoint);
                    angle = degToRad(radToDeg(angleRad) - 45);

                    print('${radToDeg(angle)}  $x  $y off ${Painter.curOffset.dx}  ${Painter.curOffset.dy}');
                  }
                  else {
                    angle = degToRad(90.0);
                  }

                  setState(() {
                    curCircles.clear();
                    rotateAngle = angle;
                  });
                }
              }

              if (dragging) {
                setState(() {
                  // double curX = xPos + details.delta.dx;
                  // double curY = yPos + details.delta.dy;
                  // curCircles.clear();
                  //
                  // // curX = max(MediaQuery.of(context).padding.left, curX);
                  // // curY = max(MediaQuery.of(context).padding.top, curY);
                  // //
                  // // curX = min(MediaQuery.of(context).size.width - MediaQuery.of(context).padding.right - width, curX);
                  // // curY = min(MediaQuery.of(context).size.height - MediaQuery.of(context).padding.bottom - height, curY);
                  //
                  // xPos = curX;
                  // yPos = curY;

                  tX += details.delta.dx;
                  tY += details.delta.dy;
                });
              }
            },
            onPanEnd: (details) {
              dragging = false;

              setState(() {
                circleSelectedForScale = false;
              //   curCircles.clear();
              //   xPos = Painter.curOffset.dx;
              //   yPos = Painter.curOffset.dy;
              });
            },

            onDoubleTap: () {
              setState(() {
                rotateAngle = 0.0;
                if (zoomedIn) {
                  scaleX = 1.0;
                  scaleY = 1.0;
                }
                else {
                  scaleX = 1.5;
                  scaleY = 1.5;
                }
                zoomedIn = !zoomedIn;
              });
            },

            // onLongPress: () {
            //   setState(() {
            //     tX += 1;
            //     tY += 1;
            //   });
            // },

            // child: Container(
            //   margin: const EdgeInsets.all(10.0),
            //   padding: const EdgeInsets.all(5.0),
            //   decoration: BoxDecoration(
            //     border: Border.all(color: Colors.black, width: 5.0),
            //     borderRadius: const BorderRadius.all(Radius.circular(15)),
            //   ),

            child: CustomPaint(
              painter: Painter(
                  offset: Offset(xPos, yPos),
                  scaleX: scaleX,
                  scaleY: scaleY,
                  curCircles: curCircles,
                  rect: rect,
                  rotateAngle: rotateAngle,
                  mat: Matrix4.identity(),
                  tX: tX,
                  tY: tY),
              child: Container(),
            ),
            //),
          );
        }),
      ),
    );
  }
}

class Painter extends CustomPainter {
  final Offset offset;
  double scaleX, scaleY;
  List<Pair<Offset, double>> curCircles;
  bool rect;
  double rotateAngle;
  Matrix4 mat;
  double tX, tY;

  Painter(
      {required this.offset,
      this.scaleX = 1.0,
      this.scaleY = 1.0,
      required this.curCircles,
      required this.rect,
      this.rotateAngle = 0.0,
      required this.mat,
      this.tX = 0.0,
      this.tY = 0.0});

  static double curWidthRect = 0, curHeightRect = 0;
  static double textBeginX = 0, textBeginY = 0;
  static List<Pair<Offset, double>> curCirclesStatic = [];
  static late  Offset curOffset;

  @override
  void paint(Canvas canvas, Size size) {

    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.yellow;

    final TextPainter textPainter = TextPainter(
      text: const TextSpan(
        text: 'HELLO',
        style: TextStyle(
          color: Colors.black,
          fontSize: 30,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 20 - 15);

    curWidthRect = textPainter.width + 10;
    curHeightRect = textPainter.height + 10;

    double nextWidthRect = curWidthRect * scaleX;
    double nextHeightRect = curHeightRect * scaleY;

    curOffset = Offset(offset.dx + (curWidthRect - nextWidthRect) / 2, offset.dy + (curHeightRect - nextHeightRect) / 2);

    mat.translate(textBeginX + textPainter.width / 2, textBeginY + textPainter.height / 2);

    mat.scale(scaleX, scaleY);
    mat.rotateZ(rotateAngle);
    mat.translate(tX, tY);

    mat.translate(-(textBeginX + textPainter.width / 2), -(textBeginY + textPainter.height / 2));

    canvas.transform(mat.storage);

    print('$mat\n');

    if (rect) {
      canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, curWidthRect, curHeightRect), paint);

      if(!find(offset)) {
        curCircles.add(Pair(first: offset, second: 5));
      }
      if(!find(Offset(offset.dx + curWidthRect, offset.dy))) {
        curCircles.add(Pair(first: Offset(offset.dx + curWidthRect, offset.dy), second: 5));
      }
      if(!find(Offset(offset.dx, offset.dy + curHeightRect))) {
        curCircles.add(Pair(first: Offset(offset.dx, offset.dy + curHeightRect), second: 5));
      }
      if(!find(Offset(offset.dx + curWidthRect, offset.dy + curHeightRect))) {
        curCircles.add(Pair(first: Offset(offset.dx + curWidthRect, offset.dy + curHeightRect), second: 5));
      }
      if(!find(Offset(offset.dx + curWidthRect / 2, offset.dy + curHeightRect * 2))) {
        curCircles.add(Pair(first: Offset(offset.dx + curWidthRect / 2, offset.dy + curHeightRect * 2), second: 5));
      }

      curCirclesStatic = curCircles;

      for (Pair p in curCircles) {
        canvas.drawCircle(
            p.first,
            p.second,
            Paint()
              ..style = PaintingStyle.fill
              ..color = (p == curCircles.last ? Colors.red : Colors.green));
      }
    }

    textBeginX = offset.dx + 5;
    textBeginY = offset.dy + 5;

    //canvas.drawCircle(Offset(textBeginX, textBeginY), 3, paint..color = Colors.brown);

    //final off = Offset(textBeginX + textPainter.width / 2, textBeginY + textPainter.height / 2);

    //canvas.drawCircle(off, 3, Paint()..color = Colors.blue);

    textPainter.paint(canvas, Offset(textBeginX, textBeginY));

    curWidthRect = nextWidthRect;
    curHeightRect = nextHeightRect;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  bool find(Offset offset) {
    for (final p in curCircles) {
      if (p.first == offset) return true;
    }
    return false;
  }

  // void drawRotated(Canvas canvas, Offset center, double angle, VoidCallback drawFunction) {
  //   canvas.save();
  //   canvas.translate(center.dx, center.dy);
  //   canvas.rotate(angle * pi / 180);
  //
  //   canvas.translate(-center.dx, -center.dy);
  //
  //   drawFunction();
  //
  //   canvas.restore();
  // }
}

class Pair<T, U> {
  T first;
  U second;

  Pair({required this.first, required this.second});
}

// class Painter extends CustomPainter {
//   final Rect rect;
//   Painter(this.rect);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint()
//       ..style = PaintingStyle.fill
//       ..color = Colors.red;
//
//     canvas.drawRect(rect, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

// import 'dart:math';
//
// import 'package:flutter/animation.dart';
// import 'package:flutter/material.dart';
//
// import 'bar.dart';
//
// void main() {
//   runApp(const MaterialApp(home: ChartPage()));
// }
//
// class ChartPage extends StatefulWidget {
//   const ChartPage({Key? key}) : super(key: key);
//
//   @override
//   ChartPageState createState() => ChartPageState();
// }
//
// class ChartPageState extends State<ChartPage> with TickerProviderStateMixin {
//   final random = Random();
//   late AnimationController animation;
//   late BarTween tween;
//
//   @override
//   void initState() {
//     super.initState();
//     animation = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     tween = BarTween(Bar(0.0), Bar(50.0));
//     animation.forward();
//   }
//
//   @override
//   void dispose() {
//     animation.dispose();
//     super.dispose();
//   }
//
//   void changeData() {
//     setState(() {
//       tween = BarTween(
//         tween.evaluate(animation),
//         Bar(random.nextDouble() * 100.0),
//       );
//       animation.forward(from: 0.0);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: CustomPaint(
//           size: const Size(200.0, 100.0),
//           painter: BarChartPainter(tween.animate(animation)),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: changeData,
//         child: const Icon(Icons.refresh),
//       ),
//     );
//   }
// }
//
//
// // import 'dart:io';
// // import 'dart:math';
// // import 'dart:typed_data';
// // import 'dart:ui' as ui;
// //
// // import 'package:flutter/material.dart';
// // import 'package:flutter/rendering.dart';
// // import 'package:image_editor/image_editor.dart';
// // import 'package:matrix4_transform/matrix4_transform.dart';
// //
// // void main() {
// //   runApp(MaterialApp(
// //       title: 'Flutter Demo',
// //       theme: ThemeData(
// //         primarySwatch: Colors.blue,
// //       ),
// //       home: const MyHomePage()));
// // }
// //
// // class MyHomePage extends StatefulWidget {
// //   const MyHomePage({Key? key}) : super(key: key);
// //
// //   @override
// //   State<MyHomePage> createState() => _MyHomePageState();
// // }
// //
// // class _MyHomePageState extends State<MyHomePage> {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //         appBar: AppBar(
// //           title: const Text('Canvas'),
// //         ),
// //         body: Stack(children: [
// //           SizedBox(
// //             width: MediaQuery.of(context).size.width,
// //             height: MediaQuery.of(context).size.height * .6,
// //             child: Transform(
// //               transform: Matrix4.identity()..translate(0.0, 0.0, 0.0),
// //               alignment: Alignment.center,
// //               child: Container(
// //                   color: Colors.cyanAccent,
// //                   child: LayoutBuilder(
// //                       builder: (_, constraints) => SizedBox(
// //                             width: constraints.widthConstraints().maxWidth,
// //                             height: constraints.widthConstraints().maxHeight,
// //                             child: CustomPaint(
// //                               painter: MyPainter(),
// //                               //foregroundPainter: MyPainter(),
// //                               willChange: true,
// //                             ),
// //                           ))),
// //             ),
// //           ),
// //         ])
// //
// //         // Column(
// //         //   children: [
// //         //     Container(
// //         //       //padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
// //         //       width: MediaQuery.of(context).size.width,
// //         //       height: MediaQuery.of(context).size.height * .7,
// //         //       color: Colors.black,
// //         //
// //         //       child: FractionallySizedBox(
// //         //         alignment: Alignment.center,
// //         //         widthFactor: .7,
// //         //         heightFactor: .7,
// //         //         child: Container(
// //         //           color: c,
// //         //           child: LayoutBuilder(
// //         //             builder: (_, constraints) => SizedBox(
// //         //               width: constraints.widthConstraints().maxWidth,
// //         //               height: constraints.widthConstraints().maxHeight,
// //         //               child: CustomPaint(
// //         //                 painter: MyPainter(),
// //         //                 //foregroundPainter: MyPainter(),
// //         //                 willChange: true,
// //         //               ),
// //         //             )
// //         //           )
// //         //         )
// //         //       ),
// //         //     ),
// //         //
// //         //     Padding(
// //         //       padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
// //         //       child: ElevatedButton(
// //         //         onPressed: () {
// //         //           setState(() {});
// //         //         },
// //         //         child: const Text('Press'),
// //         //       )
// //         //     )
// //         //   ]
// //         // )
// //         );
// //   }
// // }
// //
// // class MyPainter extends CustomPainter {
// //   //
// //   // final Color color;
// //   //
// //   // MyPainter({required this.color});
// //
// //   @override
// //   void paint(Canvas canvas, Size size) {
// //     // canvas.saveLayer(Rect.largest, Paint());
// //     // canvas.drawRect(const Rect.fromLTWH(50, 50, 80, 80), Paint()..color = Colors.red);
// //     // canvas.drawCircle(const Offset(90, 90), 40, Paint()..blendMode = BlendMode.clear);
// //     // canvas.restore();
// //
// //     // canvas.saveLayer(Rect.largest, Paint());
// //     // canvas.drawRect(Rect.fromLTWH(50, 50, 100, 100), Paint()..color = Colors.red);
// //     // canvas.drawCircle(Offset(100, 100), 50, Paint()..blendMode = BlendMode.clear);
// //     // canvas.restore();
// //
// //     // List<Color> c = [Colors.red, Colors.blue, Colors.black, Colors.cyanAccent, Colors.amber, Colors.deepPurple];
// //     //
// //     // int len = c.length;
// //     //
// //     // final random = Random();
// //     //
// //     // final paint = Paint()
// //     //   ..style = PaintingStyle.stroke
// //     //   ..strokeWidth = 3.0
// //     //   ..color = Colors.pink;
// //     //
// //     // double l = 50, t = 50;
// //     //
// //     // for(int i = 0; i < 5; i++) {
// //     //
// //     //   final rect = Rect.fromLTWH(l, t, 50, 50);
// //     //
// //     //   int idx = random.nextInt(len);
// //     //
// //     //   print(idx);
// //     //
// //     //   paint.color = c[idx];
// //     //
// //     //   canvas.drawRect(rect, paint);
// //     //
// //     //  sleep(const Duration(seconds: 1));
// //     //
// //     //   l += 3;
// //     //   t += 3;
// //     // }
// //
// //     final paint = Paint()
// //       ..style = PaintingStyle.stroke
// //       ..strokeWidth = 3.0
// //       ..color = Colors.pink;
// //
// //     final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
// //       fontSize: 30,
// //       textAlign: TextAlign.center,
// //       maxLines: 1,
// //     ))
// //       ..pushStyle(ui.TextStyle(color: Colors.pink))
// //       ..addText('Jahed')
// //       ..pop();
// //
// //     final paragraph = builder.build();
// //
// //     paragraph.layout(const ui.ParagraphConstraints(width: 200));
// //
// //     canvas.drawParagraph(paragraph, Offset(30, 30));
// //
// //     const rect = Rect.fromLTWH(50, 150, 20, 50);
// //
// //     // canvas.rotate(6);
// //     //
// //     // canvas.scale(2, 1);
// //     //
// //     // canvas.skew(1.1, 1.5);
// //
// //     // canvas.rotate(degtoRad(350));
// //
// //     Float64List m = Float64List(16);
// //
// //     m[0] = m[5] = m[10] = m[15] = 1;
// //     //m[2] = 1;
// //     m[4] = 1;
// //     //m[3] = 1;
// //
// //     canvas.transform(m);
// //
// //     canvas.drawRect(rect, paint);
// //
// //     final path = Path()
// //       ..moveTo(0, 0)
// //       ..lineTo(100, 100)
// //       ..lineTo(0, 100)
// //       ..lineTo(0, 0)
// //       ..lineTo(100, 200)
// //       ..arcTo(const Rect.fromLTWH(100, 200, 150, 150), 90, 45, true);
// //
// //     //canvas.drawPath(path, paint);
// //   }
// //
// //   double degtoRad(double deg) {
// //     return deg * pi / 180;
// //   }
// //
// //   @override
// //   bool shouldRepaint(covariant CustomPainter oldDelegate) {
// //     return false;
// //   }
// // }
// //
// // // //
// // // // class RenderFo extends StatefulWidget {
// // // //   const RenderFo({Key? key,}) : super(key: key);
// // // //
// // // //   @override
// // // //   _RenderFoState createState() => _RenderFoState();
// // // // }
// // // //
// // // // class _RenderFoState extends State<RenderFo> {
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return const RenderFooObjectWidget();
// // // //   }
// // // // }
// // // //
// // // // class RenderFooObjectWidget extends LeafRenderObjectWidget {
// // // //   const RenderFooObjectWidget({Key? key}) : super(key: key);
// // // //
// // // //   @override
// // // //   RenderObject createRenderObject(BuildContext context) {
// // // //     return RenderFoo();
// // // //   }
// // // // }
// // // //
// // // // class RenderFoo extends RenderBox {
// // // //
// // // //
// // // //   static const double _overlayRadius = 16.0;
// // // //   static const double _overlayDiameter = _overlayRadius * 2.0;
// // // //   static const double _trackHeight = 2.0;
// // // //   static const double _preferredTrackWidth = 144.0;
// // // //   static const double _preferredTotalWidth =
// // // //       _preferredTrackWidth + 2 * _overlayDiameter;
// // // //   static const double _thumbRadius = 6.0;
// // // //
// // // //   /// -------------------------------------------
// // // //   /// The size of this RenderBox is defined by
// // // //   /// the parent
// // // //   /// -------------------------------------------
// // // //   @override
// // // //   bool get sizedByParent => true;
// // // //
// // // //   /// -------------------------------------------
// // // //   /// Update of the RenderBox size using only
// // // //   /// the constraints which are provided by
// // // //   /// its parent.
// // // //   /// Compulsory when sizedByParent returns true
// // // //   /// -------------------------------------------
// // // //   @override
// // // //   void performResize() {
// // // //     size = Size(
// // // //       constraints.hasBoundedWidth ? constraints.maxWidth : _preferredTotalWidth,
// // // //       constraints.hasBoundedHeight ? constraints.maxHeight : _oer,
// // // //     );
// // // //   }
// // // //
// // // //   /// ------------------------------------------------------------------
// // // //   /// Computation of the min,max intrinsic
// // // //   /// width and height of the box.
// // // //   /// The following 4 methods must be implemented.
// // // //   ///
// // // //   /// computeMinIntrinsicWidth: minimal width.  Here as there are
// // // //   ///                           2 thumbs, enough space to display them
// // // //   /// computeMaxIntrinsicWidth: smallest width beyond which increasing
// // // //   ///                           the width never decreases the height
// // // //   /// computeMinIntrinsicHeight: minimal height.  Diameter of a thumb.
// // // //   /// computeMaxIntrinsicHeight: maximal height:  Diameter of a thumb.
// // // //   /// ------------------------------------------------------------------
// // // //   @override
// // // //   double computeMinIntrinsicWidth(double height) {
// // // //     return 2 * _overlayDiameter;
// // // //   }
// // // //
// // // //   @override
// // // //   double computeMaxIntrinsicWidth(double height) {
// // // //     return _preferredTotalWidth;
// // // //   }
// // // //
// // // //   @override
// // // //   double computeMinIntrinsicHeight(double width) {
// // // //     return _overlayDiameter;
// // // //   }
// // // //
// // // //   @override
// // // //   double computeMaxIntrinsicHeight(double width) {
// // // //     return _overlayDiameter;
// // // //   }
// // // //
// // // //
// // // //   @override
// // // //   void paint(PaintingContext context, Offset offset) {
// // // //     final canvas = context.canvas;
// // // //
// // // //     //_paintTrack(canvas, offset);
// // // //
// // // //
// // // //     double l = 50, t = 20;
// // // //
// // // //     for(int i = 0; i < 3; i++) {
// // // //       paintRect(canvas, Offset(offset.dx + l, offset.dy + l));
// // // //
// // // //       l += 5;
// // // //
// // // //       sleep(const Duration(seconds: 1));
// // // //     }
// // // //   }
// // // //
// // // //   void paintRect(Canvas canvas, Offset offset) {
// // // //
// // // //     Paint paint = Paint()
// // // //       ..color = Colors.red
// // // //       ..style = PaintingStyle.stroke
// // // //       ..strokeWidth = 4.0;
// // // //
// // // //     double l = offset.dx + 50;
// // // //     double t = offset.dy + 50;
// // // //
// // // //     print('$l   $t');
// // // //
// // // //     double width = 100;
// // // //     double height = 100;
// // // //
// // // //     canvas.drawRect(Rect.fromLTWH(l, t, width, height), paint);
// // // //   }
// // // // }
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //                   // child: FractionallySizedBox(
// // //                   //   alignment: Alignment.center,
// // //                   //   widthFactor: .7,
// // //                   //   heightFactor: .7,
// // //                   //   child: Container(
// // //                   //     color: Colors.white,
// // //                   //     child: LayoutBuilder(
// // //                   //       builder: (_, constraints) => SizedBox(
// // //                   //         width: constraints.widthConstraints().maxWidth,
// // //                   //         height: constraints.widthConstraints().maxHeight,
// // //                   //         child: CustomPaint(
// // //                   //             painter: MyPainter(),
// // //                   //             willChange: true,
// // //                   //         ),
// // //                   //
// // //                   //       )
// // //                   //     )
// // //                   //   )
// // //                   // ),
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //
// // //     //canvas.drawLine(const Offset(40, 10), const Offset(200, 10), paint);
// // //     // canvas.drawCircle(const Offset(40, 200), 50, paint);
// // //     //
// // //     // canvas.drawArc(const Rect.fromLTWH(150, 150, 50, 50), 90, 180, false, paint);
// // //     //
// // //     // canvas.drawOval(const Rect.fromLTRB(40, 300, 100, 350), paint);
// // //
// // //     // final builder = ui.ParagraphBuilder(
// // //     //     ui.ParagraphStyle(
// // //     //       textAlign: TextAlign.center,
// // //     //       maxLines: 1,
// // //     //       fontSize: 40,
// // //     //     ))..pushStyle(ui.TextStyle(color: Colors.pink))
// // //     //       ..addText('Jahed')
// // //     //       ..pop();
// // //     //
// // //     // final paragraph = builder.build();
// // //     //
// // //     // paragraph.layout(const ui.ParagraphConstraints(width: 200));
// // //     //
// // //     // canvas.drawParagraph(paragraph, const Offset(150, 300));
// // //
// // //
// // //
// // //
// // // /*
// // //
// // // child: Stack(
// // //
// // //               children: [
// // //                 Positioned(
// // //                   child: GestureDetector(
// // //
// // //                     onTap: () {
// // //
// // //                     },
// // //                     onDoubleTap: () {
// // //
// // //                     },
// // //
// // //                     child: Draggable(
// // //                       feedback: FractionallySizedBox(
// // //                         alignment: Alignment.center,
// // //                         widthFactor: .7,
// // //                         heightFactor: .7,
// // //                         child: Container(
// // //                           color: Colors.white,
// // //                           child: LayoutBuilder(
// // //                             builder: (_, constraints) => SizedBox(
// // //                               width: constraints.widthConstraints().maxWidth,
// // //                               height: constraints.widthConstraints().maxHeight,
// // //                               child: CustomPaint(
// // //                                 painter: MyPainter(),
// // //                                 willChange: true,
// // //                               ),
// // //                             )
// // //                           )
// // //                         )
// // //                       ),
// // //
// // //                       child: FractionallySizedBox(
// // //                         alignment: Alignment.center,
// // //                         widthFactor: .7,
// // //                         heightFactor: .7,
// // //                         child: Container(
// // //                           color: Colors.white,
// // //                           child: LayoutBuilder(
// // //                             builder: (_, constraints) => SizedBox(
// // //                               width: constraints.widthConstraints().maxWidth,
// // //                               height: constraints.widthConstraints().maxHeight,
// // //                               child: CustomPaint(
// // //                                 painter: MyPainter(),
// // //                                 willChange: true,
// // //                               ),
// // //                             )
// // //                           )
// // //                         )
// // //                       ),
// // //
// // //                       onDragEnd: (drag) {
// // //                         final renderBox = context.findRenderObject() as RenderBox;
// // //                         Offset off = renderBox.globalToLocal(drag.offset);
// // //
// // //                         setState(
// // //                             () {
// // //
// // //                             }
// // //                         );
// // //                       },
// // //                     ),
// // //                   )
// // //                 )
// // //               ]
// // //             )
// // //
// // // */
// // //
// // //
// // //
// // //
