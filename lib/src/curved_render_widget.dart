import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' as math_64;

class CurvedRenderWidget extends SingleChildRenderObjectWidget {
  const CurvedRenderWidget({
    super.key,
    required this.text,
    this.textStyle,
    required this.curvature,
    this.beforeDrawing,
    this.afterDrawing,
  });

  final String text;
  final TextStyle? textStyle;
  final double curvature;
  final PainterDelegate? beforeDrawing;
  final PainterDelegate? afterDrawing;

  @override
  CurvedRender createRenderObject(BuildContext context) =>
      CurvedRender(
        text: text,
        textStyle: textStyle,
        curvature: curvature,
        beforeDrawing: beforeDrawing,
        afterDrawing: afterDrawing,
      );

  @override
  void updateRenderObject(BuildContext context, CurvedRender renderObject) {
    renderObject.refreshData(
      text: text,
      textStyle: textStyle,
      curvature: curvature,
      beforeDrawing: beforeDrawing,
      afterDrawing: afterDrawing,
    );
  }
}

class CurvedRender extends RenderBox {
  CurvedRender({
    String text = '',
    TextStyle? textStyle,
    double curvature = 1,
    PainterDelegate? beforeDrawing,
    PainterDelegate? afterDrawing,
  })  :
        _text = text,
        _textStyle = textStyle
  {
    _beforeDrawing = beforeDrawing;
    _afterDrawing = afterDrawing;
    _textPainter
      ..text = TextSpan(text: _text, style: textStyle)
      ..layout(minWidth: 0, maxWidth: double.maxFinite);
    _radius = math.max(_textPainter.height/2, _textPainter.width/2/math.pi/math.max(0.001, curvature.abs()) - _textPainter.height);
    _width = _radius;
    _height = _radius;
    _effectiveRadius = _radius + _textPainter.height;
    _curvature = curvature;
    _initialAngle = curvature>=0?0:math.pi;
    final double alignmentOffset =
    _getAlignmentOffset(sweepAngle);
    if(curvature<0){
      _angleWithAlignment = _initialAngle - alignmentOffset + math.pi;
      _angleMultiplier = -1;
      _heightOffset = _effectiveRadius;
    }else{
      _angleWithAlignment = _initialAngle + alignmentOffset;
      _angleMultiplier = 1;
      _heightOffset = -_effectiveRadius - _textPainter.height;
    }
  }

  String _text;
  TextStyle? _textStyle;
  late double _curvature;
  late double _initialAngle;
  late double _effectiveRadius;
  late int _angleMultiplier;
  late double _heightOffset;
  late double _angleWithAlignment;
  late double _radius;
  late double _width;
  late double _height;
  PainterDelegate? _beforeDrawing;
  PainterDelegate? _afterDrawing;

  set width(double value) {
    if (_width == value) return;
    _width = value;
    markNeedsLayout();
  }

  set height(double value) {
    if (_height == value) return;
    _height = value;
    markNeedsLayout();
  }

  double get radius => _radius;
  double get effectiveRadius => _effectiveRadius;
  double get curvature => _curvature;
  Offset get centerOffset => Offset(_width / 2, _effectiveRadius+_textPainter.height);
  double get letterWidth => _textPainter.width;
  double get letterHeight => _textPainter.height;

  final _textPainter = TextPainter(textDirection: TextDirection.ltr);

  void refreshData({
    required String text,
    TextStyle? textStyle,
    double curvature = 1,
    PainterDelegate? beforeDrawing,
    PainterDelegate? afterDrawing
  }) {
    _text = text;
    _textStyle = textStyle;
    _beforeDrawing = beforeDrawing;
    _afterDrawing = afterDrawing;
    {
      _textPainter
        ..text = TextSpan(text: _text, style: textStyle)
        ..layout(minWidth: 0, maxWidth: double.maxFinite);
      _radius = math.max(_textPainter.height/2/math.pi/math.max(0.001, curvature.abs()),
        _textPainter.width/2/math.pi/math.max(0.001, curvature.abs())-_textPainter.height*2,);
      _width = _radius;
      _height = _radius;
      _effectiveRadius = _radius + _textPainter.height;
      _curvature = curvature;
      _initialAngle = curvature>=0?0:math.pi;
      sweepAngle = _calculateSweepAngle(
        _textPainter,
        _textStyle,
        _effectiveRadius,
        _text,
      );
      final double alignmentOffset =
      _getAlignmentOffset(sweepAngle);
      if(curvature<0){
        _angleWithAlignment = _initialAngle - alignmentOffset + math.pi;
        _angleMultiplier = -1;
        _heightOffset = _effectiveRadius;
      }else{
        _angleWithAlignment = _initialAngle + alignmentOffset;
        _angleMultiplier = 1;
        _heightOffset = -_effectiveRadius - _textPainter.height;
      }
    }
    markNeedsLayout();
  }

  void drawPaint(PaintingContext context, Offset offset) {
    double offsetY = 0;
    if(_curvature<0){
      offsetY = -_effectiveRadius * 2+_height-_textPainter.height*2;
    }
    context.canvas.translate(offset.dx, offset.dy+offsetY);
    final effectiveOffset = Offset(_width / 2, _effectiveRadius+_textPainter.height);
    context.canvas..save()
      ..translate(effectiveOffset.dx, effectiveOffset.dy)
      ..rotate(_angleWithAlignment);
    _drawText(context.canvas, _angleMultiplier, _heightOffset);
    context.canvas.restore();
  }

  /// [startAngle] + [sweepAngle] == [finalAngle].
  double get startAngle {
    if(_curvature<0){
      return _angleWithAlignment + math.pi / 2 - sweepAngle;
    }else{
      return _angleWithAlignment - math.pi / 2;
    }
  }

  /// 返回文本渲染停止的角度
  /// Returns angle where the text rendering stops.
  late double sweepAngle = _calculateSweepAngle(
    _textPainter,
    _textStyle,
    _effectiveRadius,
    _text,
  );

  /// 返回文本停止的最终角度
  /// Returns final angle at which the text stops.
  double get finalAngle => startAngle + sweepAngle;

  void _drawText(Canvas canvas, int angleMultiplier, double heightOffset) {
    for (int i = 0; i < _text.characters.length; i++) {
      final graphemeCluster = _text.characters.toList()[i];
      final translation = _getTranslation(
        _textPainter,
        _textStyle,
        _effectiveRadius,
        graphemeCluster,
      );
      final halfAngleOffset = translation.alpha / 2 * angleMultiplier;
      canvas.rotate(halfAngleOffset);
      _textPainter.paint(
        canvas,
        Offset(-translation.letterWidth / 2, heightOffset),
      );
      canvas.rotate(halfAngleOffset);
    }
  }

  @override
  void performLayout() {
    final Offset center = Offset(_effectiveRadius, _effectiveRadius);
    double letterWidth = 0;
    double letterHeight = 0;
    for (int i = 0; i < _text.characters.length; i++) {
      final graphemeCluster = _text.characters.toList()[i];
      final translation = _getTranslation(
        _textPainter,
        _textStyle,
        _effectiveRadius,
        graphemeCluster,
      );
      if (translation.letterWidth > letterWidth) {
        letterWidth = translation.letterWidth;
      }
      if (translation.letterHeight > letterHeight) {
        letterHeight = translation.letterHeight;
      }
    }
    final LetterTranslation firstTranslation;
    final double rotationZ;
    firstTranslation = _getTranslation(
      _textPainter,
      _textStyle,
      _effectiveRadius,
      _text.characters.first,
    );
    final halfAngleOffset = firstTranslation.alpha / 2 * _angleMultiplier;
    rotationZ =
        math.min(math.pi * 2, sweepAngle.abs()) / 2 + halfAngleOffset;
    final Offset ltOffset =
    Offset(_effectiveRadius - letterWidth / 2,-letterHeight);
    final Offset lbOffset = Offset(
      _effectiveRadius +
          letterWidth / 2 * (_curvature>=0 ? -1 : 1),0,);
    final Offset rtOffset =
    Offset(_effectiveRadius + letterWidth / 2, -letterHeight);
    final Matrix4 matrix = Matrix4.rotationZ(rotationZ);
    final math_64.Vector3 pointLTVector = math_64.Vector3(
      ltOffset.dx - center.dx,
      ltOffset.dy - center.dy,
      0,
    );
    final math_64.Vector3 rotatedLTVector = matrix.transformed3(pointLTVector);
    final Offset ltOffsetRotated = Offset(
      rotatedLTVector.x + center.dx,
      rotatedLTVector.y + center.dy,
    );
    final math_64.Vector3 pointLBVector = math_64.Vector3(
      lbOffset.dx - center.dx,
      lbOffset.dy - center.dy,
      0,
    );
    final math_64.Vector3 rotatedLBVector = matrix.transformed3(pointLBVector);
    final Offset lbOffsetRotated = Offset(
      rotatedLBVector.x + center.dx,
      rotatedLBVector.y + center.dy,
    );
    final math_64.Vector3 pointRTVector = math_64.Vector3(
      rtOffset.dx - center.dx,
      rtOffset.dy - center.dy,
      0,
    );
    final math_64.Vector3 rotatedRTVector = matrix.transformed3(pointRTVector);
    final Offset rtOffsetRotated = Offset(
      rotatedRTVector.x + center.dx,
      rotatedRTVector.y + center.dy,
    );
    double layoutWidth = 0;
    double layoutHeight = 0;
    if (sweepAngle.abs() > math.pi) {
      layoutWidth =
          (_effectiveRadius + math.max(letterWidth, letterHeight)) * 2;
    } else {
      layoutWidth = (((_curvature>=0)
          ? math.min(ltOffsetRotated.dx, rtOffsetRotated.dx)
          : math.max(ltOffsetRotated.dx, rtOffsetRotated.dx)) -
          center.dx)
          .abs() *
          2;
    }
    layoutWidth = math.min(
      (_effectiveRadius + math.max(letterWidth, letterHeight)) * 2,
      layoutWidth,);
    layoutHeight =
        math.max(lbOffsetRotated.dy, _curvature>=0?ltOffsetRotated.dy:rtOffsetRotated.dy) + letterHeight;
    _width = layoutWidth;
    _height = layoutHeight;
    size = Size(_width, _height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _beforeDrawing?.call(context, offset, size,effectiveRadius,startAngle, sweepAngle, finalAngle,centerOffset,letterWidth, letterHeight,curvature);
    drawPaint(context,offset);
    _afterDrawing?.call(context, offset, size,effectiveRadius,startAngle, sweepAngle, finalAngle,centerOffset,letterWidth, letterHeight,curvature);
  }
}

double _getAlignmentOffset(double angle) => -angle / 2;

double _calculateSweepAngle(
    TextPainter painter,
    TextStyle? style,
    double radius,
    String text,
    ) {
  double finalRotation = 0;
  for (final graphemeCluster in text.characters) {
    final translation = _getTranslation(
      painter,
      style,
      radius,
      graphemeCluster,
    );
    finalRotation += translation.alpha;
  }
  return finalRotation;
}

/// 计算字符的宽高和角度
/// Calculates width，height and central angle for the provided [letter].
LetterTranslation _getTranslation(
    TextPainter painter,
    TextStyle? style,
    double radius,
    String letter,
    ) {
  painter
    ..text = TextSpan(text: letter, style: style)
    ..layout(minWidth: 0, maxWidth: double.maxFinite);

  return LetterTranslation.fromRadius(painter.width, painter.height, radius);
}

class LetterTranslation {
  const LetterTranslation(this.letterWidth, this.letterHeight, this.alpha);

  LetterTranslation.fromRadius(
      this.letterWidth, this.letterHeight, double radius,)
      : alpha = 2 * math.asin(letterWidth / (2 * radius));

  final double letterWidth;
  final double letterHeight;
  final double alpha;
}

typedef PainterDelegate = void Function(
    PaintingContext context,
    Offset offset,
    Size size,
    double radius,
    double startAngle,
    double sweepAngle,
    double finalAngle,
    Offset centerOffset,
    double letterWidth,
    double letterHeight,
    double curvature,
    );
