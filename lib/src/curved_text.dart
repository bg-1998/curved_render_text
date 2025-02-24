import 'package:flutter/widgets.dart';

import 'curved_render_widget.dart';

class CurvedText extends StatelessWidget{
  const CurvedText({
    super.key,
    required this.text,
    this.textSpan,
    this.textStyle,
    this.generalText,
    this.curvature = 0,
    this.beforeDrawing,
    this.afterDrawing,
    this.ignoreDecoration = false,
  });

  final String text;
  final TextStyle? textStyle;
  final TextSpan? textSpan;
  ///文本曲率为0时，默认显示RichText，建议自己传widget
  final Widget? generalText;
  /// 弯曲程度，曲率值，值越大，越弯曲。
  /// Degree of curvature, curvature value, the greater the value, the more curved.
  final double curvature;
  /// 绘制文本前的绘制方法
  /// Drawing method before drawing text
  final PainterDelegate? beforeDrawing;
  /// 绘制文本后的绘制方法
  /// Drawing method after drawing text
  final PainterDelegate? afterDrawing;
  ///忽略文本装饰
  ///Ignore text decoration
  final bool ignoreDecoration;

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle effectiveTextStyle = defaultTextStyle.style.merge(textStyle);

    if (MediaQuery.boldTextOf(context)) {
      effectiveTextStyle = effectiveTextStyle
          .merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    TextSpan textSpanChild = TextSpan(
      text: text,
      style: effectiveTextStyle,
      children: textSpan != null ? <TextSpan>[textSpan!] : null,
    );
    if(text.isEmpty&&(textSpan?.toPlainText()??'').isEmpty){
      return SizedBox();
    } else if(curvature==0){
      return generalText??RichText(text: textSpanChild,);
    }
    return CurvedRenderWidget(
      text: textSpanChild,
      curvature: curvature,
      beforeDrawing: beforeDrawing,
      afterDrawing: afterDrawing,
      ignoreDecoration: ignoreDecoration,
    );
  }
}