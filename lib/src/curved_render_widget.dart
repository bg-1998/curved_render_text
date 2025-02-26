import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' as math_64;

class CurvedRenderWidget extends MultiChildRenderObjectWidget {
  CurvedRenderWidget({
    super.key,
    required this.text,
    required this.curvature,
    this.textScaler = TextScaler.noScaling,
    this.beforeDrawing,
    this.afterDrawing,
    this.ignoreDecoration = false,
  }) : super(
          children: _extractChildren(text, textScaler),
        );

  final TextSpan text;
  final TextScaler textScaler;
  final double curvature;
  final PainterDelegate? beforeDrawing;
  final PainterDelegate? afterDrawing;
  final bool ignoreDecoration;

  @override
  CurvedRender createRenderObject(BuildContext context) => CurvedRender(
        text: text,
        textScaler: textScaler,
        curvature: curvature,
        beforeDrawing: beforeDrawing,
        afterDrawing: afterDrawing,
        ignoreDecoration: ignoreDecoration,
      );

  @override
  void updateRenderObject(BuildContext context, CurvedRender renderObject) {
    renderObject.refreshData(
      text: text,
      textScaler: textScaler,
      curvature: curvature,
      beforeDrawing: beforeDrawing,
      afterDrawing: afterDrawing,
      ignoreDecoration: ignoreDecoration,
    );
  }

  static List<Widget> _extractChildren(
    InlineSpan span,
    TextScaler textScaler,
  ) {
    final List<Widget> result = <Widget>[
      ...WidgetSpan.extractFromInlineSpan(span, textScaler)
    ];
    return result;
  }
}

class CurvedRender extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TextParentData>,
        RenderInlineChildrenContainerDefaults {
  CurvedRender({
    required TextSpan text,
    double curvature = 1,
    PainterDelegate? beforeDrawing,
    PainterDelegate? afterDrawing,
    this.ignoreDecoration = false,
    this.textScaler = TextScaler.noScaling,
  }) : _text = text {
    _textRuns = _getTextRuns(_text, _text.style);
    _beforeDrawing = beforeDrawing;
    _afterDrawing = afterDrawing;
    _curvature = curvature;
  }

  TextSpan _text;
  TextScaler textScaler;
  List<TextRun> _textRuns = [];
  late double _curvature;
  late double _initialAngle;
  late double _effectiveRadius;
  late int _angleMultiplier;
  late double _heightOffset;
  late double _angleWithAlignment;
  late double _radius;
  late double _width;
  late double _height;
  late double _letterHeight;
  PainterDelegate? _beforeDrawing;
  PainterDelegate? _afterDrawing;
  bool ignoreDecoration;

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

  double get effectiveRadius => _effectiveRadius + _letterHeight / 2;

  double get curvature => _curvature;

  Offset get centerOffset =>
      Offset(_width / 2, _effectiveRadius + _letterHeight);

  double get letterHeight => _letterHeight;

  final _textPainter = TextPainter(textDirection: TextDirection.ltr);

  void refreshData({
    required TextSpan text,
    double curvature = 1,
    PainterDelegate? beforeDrawing,
    PainterDelegate? afterDrawing,
    bool ignoreDecoration = false,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    _beforeDrawing = beforeDrawing;
    _afterDrawing = afterDrawing;
    {
      this.textScaler = textScaler;
      if (_text != text || this.ignoreDecoration != ignoreDecoration) {
        this.ignoreDecoration = ignoreDecoration;
        _text = text;
        _textRuns = _getTextRuns(_text, _text.style);
      }
      _curvature = curvature;
    }
    markNeedsLayout();
  }

  void drawPaint(PaintingContext context, Offset offset) {
    double offsetY = 0;
    if (_curvature < 0) {
      offsetY = -_effectiveRadius * 2 + _height - _letterHeight * 2;
    }
    context.canvas.translate(offset.dx, offset.dy + offsetY);
    final effectiveOffset =
        Offset(_width / 2, _effectiveRadius + _letterHeight);
    context.canvas
      ..save()
      ..translate(effectiveOffset.dx, effectiveOffset.dy)
      ..rotate(_angleWithAlignment);
    _drawText(context, _angleMultiplier, _heightOffset);
    context.canvas.restore();
  }

  /// [startAngle] + [sweepAngle] == [finalAngle].
  double get startAngle {
    if (_curvature < 0) {
      return _angleWithAlignment + math.pi / 2 - sweepAngle;
    } else {
      return _angleWithAlignment - math.pi / 2;
    }
  }

  /// 返回文本渲染停止的角度
  /// Returns angle where the text rendering stops.
  late double sweepAngle = _calculateSweepAngle(
    _effectiveRadius,
    _textRuns,
  );

  /// 返回文本停止的最终角度
  /// Returns final angle at which the text stops.
  double get finalAngle => startAngle + sweepAngle;

  void _drawText(
      PaintingContext context, int angleMultiplier, double heightOffset) {
    RenderBox? child = firstChild;
    for (int i = 0; i < _textRuns.length; i++) {
      final size = _getLetterSize(
        _textPainter,
        _textRuns[i],
        child: (_textRuns[i].textSpan is! TextSpan) ? child : null,
      );
      final translation = _getTranslation(
        _effectiveRadius,
        _textRuns[i],
      );
      final halfAngleOffset = translation.alpha / 2 * angleMultiplier;
      context.canvas.rotate(halfAngleOffset);
      if (_textRuns[i].textSpan is TextSpan) {
        _textPainter.paint(
          context.canvas,
          Offset(-size.width / 2,
              heightOffset - (size.height - _letterHeight) / 2),
        );
      } else {
        context.paintChild(
            child as RenderBox,
            Offset(-size.width / 2,
                heightOffset - (size.height - _letterHeight) / 2));
        child = childAfter(child);
      }
      context.canvas.rotate(halfAngleOffset);
    }
  }

  List<TextRun> _getTextRuns(InlineSpan textSpan, TextStyle? style) {
    final List<TextRun> spans = [];
    if (textSpan is TextSpan) {
      if ((textSpan.text ?? '').isNotEmpty) {
        TextStyle? createStyle;
        if (ignoreDecoration) {
          createStyle = style?.copyWith(
            decoration: TextDecoration.none,
          );
        } else {
          createStyle = style;
        }
        for (var char in textSpan.text!.characters) {
          spans.add(
              TextRun(TextSpan(text: char, style: createStyle), style: style));
        }
      }
      if ((textSpan.children ?? []).isNotEmpty) {
        for (final InlineSpan child in textSpan.children ?? []) {
          spans.addAll(_getTextRuns(child, child.style ?? style));
        }
      }
    } else {
      TextStyle? createStyle;
      if (ignoreDecoration) {
        createStyle = style?.copyWith(
          decoration: TextDecoration.none,
        );
      } else {
        createStyle = style;
      }
      spans.add(TextRun(textSpan, style: createStyle));
    }
    return spans;
  }

  @override
  void performLayout() {
    double letterWidth = 0;
    double letterHeight = 0;
    RenderBox? child = firstChild;
    int maxHeightIndex = 0;
    for (int i = 0; i < _textRuns.length; i++) {
      final span = _textRuns.toList()[i];
      final size = _getLetterSize(_textPainter, span,
        child:(span.textSpan is! TextSpan) ? child : null,);
      _textRuns[i]
        ..width = size.width
        ..height = size.height;
      if (size.width > letterWidth) {
        letterWidth = size.width;
      }
      if (size.height > letterHeight) {
        letterHeight = size.height;
        maxHeightIndex = i;
      }
      if (span.textSpan is! TextSpan) {
        child = childAfter(child!);
      }
    }
    double textWidth = _textRuns.map((e)=>e.width).fold(0.0, (previousValue, element)=>previousValue+element);
    _letterHeight = letterHeight;
    _radius = math.max(_letterHeight / 2,
        textWidth / 2 / math.pi / curvature.abs() - _letterHeight);
    _width = _radius;
    _height = _radius;
    _effectiveRadius = _radius + _letterHeight;
    _initialAngle = curvature >= 0 ? 0 : math.pi;
    sweepAngle = _calculateSweepAngle(
      _effectiveRadius,
      _textRuns,
    );
    final double alignmentOffset = _getAlignmentOffset(sweepAngle);
    if (curvature < 0) {
      _angleWithAlignment = _initialAngle - alignmentOffset + math.pi;
      _angleMultiplier = -1;
      _heightOffset = _effectiveRadius;
    } else {
      _angleWithAlignment = _initialAngle + alignmentOffset;
      _angleMultiplier = 1;
      _heightOffset = -_effectiveRadius - _letterHeight;
    }
    final Offset center = Offset(_effectiveRadius, _effectiveRadius);
    double currentAngle = startAngle + (curvature > 0 ? 0 : sweepAngle);
    double maxHalfAngleOffset = 0;
    for (int i = 0; i < _textRuns.length; i++) {
      final span = _textRuns.toList()[i];
      final translation = _getTranslation(
        _effectiveRadius,
        span,
      );
      final halfAngleOffset = translation.alpha / 2 * _angleMultiplier;
      _textRuns[i].startAngle = currentAngle;
      currentAngle += halfAngleOffset * 2;
      _textRuns[i].endAngle = currentAngle;
      if(i==maxHeightIndex){
        maxHalfAngleOffset = halfAngleOffset;
      }
    }
    final double rotationZ;
    rotationZ = math.min(math.pi * 2, sweepAngle.abs()) / 2 + maxHalfAngleOffset;
    final Offset ltOffset =
        Offset(_effectiveRadius - letterWidth / 2, -letterHeight);
    final Offset lbOffset = Offset(
      _effectiveRadius + letterWidth / 2 * (_curvature >= 0 ? -1 : 1),
      0,
    );
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
      layoutWidth = (((_curvature >= 0)
                      ? math.min(ltOffsetRotated.dx, rtOffsetRotated.dx)
                      : math.max(ltOffsetRotated.dx, rtOffsetRotated.dx)) -
                  center.dx)
              .abs() *
          2;
    }
    layoutWidth = math.min(
      (_effectiveRadius + math.max(letterWidth, letterHeight)) * 2,
      layoutWidth,
    );
    layoutHeight = math.max(lbOffsetRotated.dy,
            _curvature >= 0 ? ltOffsetRotated.dy : rtOffsetRotated.dy) +
        letterHeight;
    _width = layoutWidth;
    _height = layoutHeight;
    size = Size(_width, _height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _beforeDrawing?.call(
        context,
        offset,
        size,
        effectiveRadius,
        startAngle,
        sweepAngle,
        finalAngle,
        centerOffset,
        curvature,
        letterHeight,
        _textRuns);
    drawPaint(context, offset);
    _afterDrawing?.call(
        context,
        offset,
        size,
        effectiveRadius,
        startAngle,
        sweepAngle,
        finalAngle,
        centerOffset,
        curvature,
        letterHeight,
        _textRuns);
  }

  double _getAlignmentOffset(double angle) => -angle / 2;

  double _calculateSweepAngle(
    double radius,
    List<TextRun> textSpans,
  ) {
    double finalRotation = 0;
    for (final span in textSpans) {
      final translation = _getTranslation(
        radius,
        span,
      );
      finalRotation += translation.alpha;
    }
    return finalRotation;
  }

  /// 计算字符角度
  /// Calculates central angle for the provided [letter].
  LetterTranslation _getTranslation(
      double radius, TextRun letter) {
    return LetterTranslation.fromRadius(letter.width, letter.height, radius);
  }

  /// 计算字符的宽高
  /// Calculates width，height for the provided [letter].
  Size _getLetterSize(TextPainter painter, TextRun letter,
      {RenderBox? child}){
    PlaceholderDimensions? dimension;
    if (child != null) {
      BoxConstraints childConstraints =
      BoxConstraints(maxWidth: double.maxFinite);
      PlaceholderSpan span = letter.textSpan as PlaceholderSpan;
      dimension = PlaceholderDimensions(
        size: ChildLayoutHelper.layoutChild(child, childConstraints),
        alignment: span.alignment,
        baseline: span.baseline,
        baselineOffset: switch (span.alignment) {
          PlaceholderAlignment.aboveBaseline ||
          PlaceholderAlignment.belowBaseline ||
          PlaceholderAlignment.bottom ||
          PlaceholderAlignment.middle ||
          PlaceholderAlignment.top =>
          null,
          PlaceholderAlignment.baseline => ChildLayoutHelper.getBaseline(
              child, childConstraints, span.baseline!),
        },
      );
    }
    painter
      ..text = letter.textSpan
      ..textScaler = textScaler
      ..setPlaceholderDimensions(dimension == null ? null : [dimension])
      ..layout(minWidth: 0, maxWidth: double.maxFinite);
    return Size(painter.width, painter.height,);
  }
}

class LetterTranslation {
  const LetterTranslation(this.letterWidth, this.letterHeight, this.alpha);

  LetterTranslation.fromRadius(
    this.letterWidth,
    this.letterHeight,
    double radius,
  ) : alpha = 2 * math.asin(letterWidth / (2 * radius));

  final double letterWidth;
  final double letterHeight;
  final double alpha;
}

class TextRun {
  TextRun(this.textSpan,
      {this.style,
      this.startAngle = 0,
      this.endAngle = 0,
      this.width = 0,
      this.height = 0});

  final InlineSpan textSpan;
  TextStyle? style;
  double startAngle;
  double endAngle;
  double width;
  double height;

  double get sweepAngle => endAngle - startAngle;
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
  double curvature,
  double letterHeight,
  List<TextRun> textRuns,
);
