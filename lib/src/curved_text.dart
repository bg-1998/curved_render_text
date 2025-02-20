import 'package:flutter/widgets.dart';

import 'curved_render_widget.dart';

class CurvedText extends StatelessWidget{
  const CurvedText({
    super.key,
    required this.text,
    this.textStyle,
    this.curvature = 0,
    this.beforeDrawing,
    this.afterDrawing,
  });

  final String text;
  final TextStyle? textStyle;

  /// 弯曲程度，曲率值，值越大，越弯曲。
  /// Degree of curvature, curvature value, the greater the value, the more curved.
  final double curvature;
  /// 绘制文本前的绘制方法
  /// Drawing method before drawing text
  final PainterDelegate? beforeDrawing;
  /// 绘制文本后的绘制方法
  /// Drawing method after drawing text
  final PainterDelegate? afterDrawing;

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle effectiveTextStyle = defaultTextStyle.style.merge(textStyle);

    if (MediaQuery.boldTextOf(context)) {
      effectiveTextStyle = effectiveTextStyle
          .merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    if(text.isEmpty){
      return SizedBox();
    }
    return CurvedRenderWidget(
      text: text,
      textStyle: effectiveTextStyle,
      curvature: curvature,
      beforeDrawing: beforeDrawing,
      afterDrawing: afterDrawing,
    );
  }
}