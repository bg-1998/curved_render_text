import 'package:curved_render_text/curved_render_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        // useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter CurvedText Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double curvature = 20;
  final TextStyle _textStyle = const TextStyle(fontSize: 18, color: Colors.black);
  TextStyle _textDecorationStyle = const TextStyle(fontSize: 18, color: Colors.black,decorationThickness: 2);
  final TextEditingController _textEditingController = TextEditingController
    (text: '文本根据曲率弯曲，通过自定义渲染widget实现，弯曲后可返回widget的实际宽度和高度');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Expanded(child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 1,
                    ),
                  ),
                  child: CurvedText(
                    text: _textEditingController.text,
                    textStyle: _textStyle,
                    curvature: curvature/100.0,
                    afterDrawing: _makeDelegate(_textDecorationStyle,),
                  ),
                )
              ],
            ),),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Slider(
                        value: curvature,
                        divisions: 200,
                        label: '弯曲程度${curvature.toInt()}%',
                        min: -100,
                        max: 100,
                        onChanged: (value){
                          setState(() {
                            curvature = value.floorToDouble();
                          });
                        },
                      ),
                      Row(
                        children: [
                          CupertinoSwitch(value: _textDecorationStyle.decoration==TextDecoration.overline,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (value){
                              setState(() {
                                _textDecorationStyle = _textDecorationStyle.copyWith(
                                  decoration: value?TextDecoration.overline:TextDecoration.none,
                                );
                              });
                            },),
                          Text('上划线',style: TextStyle(fontSize: 14,color: Theme.of(context).primaryColor),),
                        ],
                      ),
                      Row(
                        children: [
                          CupertinoSwitch(value: _textDecorationStyle.decoration==TextDecoration.lineThrough,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (value){
                              setState(() {
                                _textDecorationStyle = _textDecorationStyle.copyWith(
                                  decoration: value?TextDecoration.lineThrough:TextDecoration.none,
                                );
                              });
                            },),
                          Text('删除线',style: TextStyle(fontSize: 14,color: Theme.of(context).primaryColor),),
                        ],
                      ),
                      Row(
                        children: [
                          CupertinoSwitch(value: _textDecorationStyle.decoration==TextDecoration.underline,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (value){
                              setState(() {
                                _textDecorationStyle = _textDecorationStyle.copyWith(
                                  decoration: value?TextDecoration.underline:TextDecoration.none,
                                );
                              });
                            },),
                          Text('下划线',style: TextStyle(fontSize: 14,color: Theme.of(context).primaryColor),),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 200,height: 80,child: CupertinoTextField(
                  showCursor: true,
                  controller: _textEditingController,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                  maxLines: null,
                  onChanged: (value){
                    setState(() {
                      _textEditingController.text = value;
                    });
                  },
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PainterDelegate _makeDelegate(TextStyle textStyle) =>
          (PaintingContext context,
          Offset offset,
          Size size,
          double radius,
          double startAngle,
          double sweepAngle,
          double finalAngle,
          Offset centerOffset,
          double letterWidth,
          double letterHeight,
          double curvature,) {
        Rect? rect;
        if(textStyle.decoration == TextDecoration.overline){
          rect = Rect.fromCircle(
            center: centerOffset,
            radius: radius,
          );
        } else if(textStyle.decoration == TextDecoration.lineThrough){
          rect = Rect.fromCircle(
            center: centerOffset,
            radius: radius+letterHeight/2,
          );
        } else if(textStyle.decoration == TextDecoration.underline){
          rect = Rect.fromCircle(
            center: centerOffset,
            radius: radius+(curvature>=0?0:1)*letterHeight,
          );
        }
        if (rect!=null) {
          context.canvas.drawArc(
            rect,
            startAngle,
            sweepAngle,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = textStyle.decorationThickness??1
              ..color = textStyle.decorationColor??textStyle.color??Colors.black,
          );
        }
      };
}
