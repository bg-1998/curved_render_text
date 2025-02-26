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
  double curvature = 100;
  final TextStyle _textStyle = const TextStyle(fontSize: 18, color: Colors.black);
  final TextEditingController _textEditingController = TextEditingController
    (text: '文本根据曲率弯曲，通过自定义渲染widget实现，弯曲后可返回widget的实际宽度和高度');
  bool ignoreDecoration = true;
  TextDecoration textDecoration = TextDecoration.none;

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
                OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 1,
                      ),
                    ),
                    child: CurvedText(
                      ignoreDecoration: ignoreDecoration,
                      text: _textEditingController.text,
                      textStyle: _textStyle.copyWith(
                        fontSize: 14,
                        decoration: textDecoration,
                        decorationColor: _textStyle.color,
                        decorationThickness: 2,
                      ),
                      textSpan: TextSpan(
                        children: [
                          WidgetSpan(child: Icon(Icons.ac_unit,size: 40,color: Colors.green,),alignment: PlaceholderAlignment.middle),
                          WidgetSpan(child: Icon(Icons.sailing_sharp,size: 20,color: Colors.blueAccent,),alignment: PlaceholderAlignment.middle),
                          TextSpan(
                            text: 'TextSpan',
                            style: _textStyle.copyWith(
                              color: Colors.blue,
                              decoration: textDecoration,
                              decorationColor: Colors.blue,
                              decorationThickness: 2,
                            ),
                          ),
                          WidgetSpan(child: Icon(Icons.access_alarm,size: 20,color: Colors.purple,),alignment: PlaceholderAlignment.middle),
                          WidgetSpan(child: Icon(Icons.local_activity,size: 20,color: Colors.amber,),alignment: PlaceholderAlignment.middle),
                          TextSpan(
                            text: 'TextSpan',
                            style: _textStyle.copyWith(
                              decoration: textDecoration,
                              decorationColor: _textStyle.color,
                              decorationThickness: 2,
                            ),
                          ),
                        ],
                      ),
                      curvature: curvature/100.0,
                      afterDrawing: _makeDelegate(),
                    ),
                  ),
                )
              ],
            ),),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 200,
                      child:Slider(
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
                    ),
                    Row(
                      children: [
                        Column(
                          children: [
                            Row(
                              children: [
                                CupertinoSwitch(value: textDecoration==TextDecoration.overline,
                                  activeColor: Theme.of(context).primaryColor,
                                  onChanged: (value){
                                    setState(() {
                                      textDecoration = value?TextDecoration.overline:TextDecoration.none;
                                    });
                                  },),
                                Text('上划线',style: TextStyle(fontSize: 14,color: Theme.of(context).primaryColor),),
                              ],
                            ),
                            Row(
                              children: [
                                CupertinoSwitch(value: textDecoration==TextDecoration.lineThrough,
                                  activeColor: Theme.of(context).primaryColor,
                                  onChanged: (value){
                                    setState(() {
                                      textDecoration = value?TextDecoration.lineThrough:TextDecoration.none;
                                    });
                                  },),
                                Text('删除线',style: TextStyle(fontSize: 14,color: Theme.of(context).primaryColor),),
                              ],
                            ),
                            Row(
                              children: [
                                CupertinoSwitch(value: textDecoration==TextDecoration.underline,
                                  activeColor: Theme.of(context).primaryColor,
                                  onChanged: (value){
                                    setState(() {
                                      textDecoration = value?TextDecoration.underline:TextDecoration.none;
                                    });
                                  },),
                                Text('下划线',style: TextStyle(fontSize: 14,color: Theme.of(context).primaryColor),),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(width: 20,),
                        Column(
                          children: [
                            Row(
                              children: [
                                CupertinoSwitch(value: ignoreDecoration,
                                  activeColor: Theme.of(context).primaryColor,
                                  onChanged: (value){
                                    setState(() {
                                      ignoreDecoration = !ignoreDecoration;
                                    });
                                  },),
                                Text('忽略默认文本装饰',style: TextStyle(fontSize: 14,color: Theme.of(context).primaryColor),),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(width: 20,),
                SizedBox(width: 200,height: 80,child: CupertinoTextField(
                  showCursor: true,
                  controller: _textEditingController,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                  maxLines: null,
                  onChanged: (value){
                    setState(() {});
                  },
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PainterDelegate _makeDelegate() =>
          (PaintingContext context,
          Offset offset,
          Size size,
          double radius,
          double startAngle,
          double sweepAngle,
          double finalAngle,
          Offset centerOffset,
          double curvature,
          double letterHeight,
          List<TextRun> textRuns,) {
            for (var textRun in textRuns) {
              Rect? rect;
              if(textRun.style?.decoration == TextDecoration.overline){
                rect = Rect.fromCircle(
                  center: centerOffset,
                  radius: radius+(curvature>=0?1:-1)*letterHeight/2,
                );
              } else if(textRun.style?.decoration == TextDecoration.lineThrough){
                rect = Rect.fromCircle(
                  center: centerOffset,
                  radius: radius,
                );
              } else if(textRun.style?.decoration == TextDecoration.underline){
                rect = Rect.fromCircle(
                  center: centerOffset,
                  radius: radius+(curvature>=0?-1:1)*letterHeight/2,
                );
              }
              if (rect!=null) {
                context.canvas.drawArc(
                  rect,
                  textRun.startAngle,
                  textRun.sweepAngle,
                  false,
                  Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeCap = StrokeCap.round
                    ..strokeWidth = textRun.textSpan.style?.decorationThickness??1
                    ..color = textRun.textSpan.style?.decorationColor??textRun.textSpan.style?.color??Colors.black,
                );
              }
            }
      };
}
