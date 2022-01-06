import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:bonfire/bonfire.dart';
import 'package:bonfire/camera/bonfire_camera.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' as widget;

export 'attackable_extensions.dart';
export 'enemy/enemy_extensions.dart';
export 'enemy/enemy_extensions.dart';
export 'enemy/rotation_enemy_extensions.dart';
export 'game_component_extensions.dart';
export 'joystick_extensions.dart';
export 'movement_extensions.dart';
export 'player/player_extensions.dart';
export 'player/rotation_player_extensions.dart';

extension ImageExtension on Image {
  SpriteAnimation getAnimation({
    required Vector2 size,
    required double count,
    int startDx = 0,
    int startDy = 0,
    double stepTime = 0.1,
    bool loop = true,
  }) {
    List<Sprite> spriteList = [];
    for (int i = 0; i < count; i++) {
      spriteList.add(Sprite(
        this,
        srcPosition: Vector2(
          (startDx + (i * size.x)).toDouble(),
          startDy.toDouble(),
        ),
        srcSize: size,
      ));
    }
    return SpriteAnimation.spriteList(
      spriteList,
      loop: loop,
      stepTime: stepTime,
    );
  }

  Sprite getSprite({
    Vector2? position,
    Vector2? size,
  }) {
    return Sprite(
      this,
      srcPosition: position,
      srcSize: size,
    );
  }

  /// Do merge image. Overlaying the images
  Future<Image> overlap(Image other) {
    PictureRecorder recorder = PictureRecorder();
    final paint = Paint();
    Canvas canvas = Canvas(recorder);
    final totalWidth = max(this.width, other.width);
    final totalHeight = max(this.height, other.height);
    canvas.drawImage(this, Offset.zero, paint);
    canvas.drawImage(other, Offset.zero, paint);
    return recorder.endRecording().toImage(totalWidth, totalHeight);
  }

  /// Do merge image list. Overlaying the images
  Future<Image> overlapList(List<Image> others) {
    PictureRecorder recorder = PictureRecorder();
    final paint = Paint();
    Canvas canvas = Canvas(recorder);
    int totalWidth = this.width;
    int totalHeight = this.height;
    canvas.drawImage(this, Offset.zero, paint);
    others.forEach((i) {
      totalWidth = max(totalWidth, i.width);
      totalHeight = max(totalHeight, i.height);
      canvas.drawImage(i, Offset.zero, paint);
    });
    return recorder.endRecording().toImage(totalWidth, totalHeight);
  }
}

extension OffSetExt on Offset {
  Offset copyWith({double? x, double? y}) {
    return Offset(x ?? this.dx, y ?? this.dy);
  }

  Vector2 toVector2() {
    return Vector2(this.dx, this.dy);
  }
}

extension RectExt on Rect {
  Vector2 get positionVector2 => Vector2(left, top);
  Vector2 get sizeVector2 => Vector2(width, height);

  Rectangle getRectangleByTileSize(double tileSize) {
    final left = (this.left / tileSize).floorToDouble();
    final top = (this.top / tileSize).floorToDouble();
    final width = (this.width / tileSize).ceilToDouble();
    final height = (this.height / tileSize).ceilToDouble();

    return Rectangle(
      left,
      top,
      width,
      height,
    );
  }

  bool overlapComponent(PositionComponent c) {
    double left = c.position.x;
    double top = c.position.y;
    double right = c.position.x + c.size.x;
    double bottom = c.position.y + c.size.y;
    if (this.right <= left || right <= this.left) {
      return false;
    }
    if (this.bottom <= top || bottom <= this.top) {
      return false;
    }
    return true;
  }
}

extension SpriteExt on Sprite {
  void renderWithOpacity(
    Canvas canvas,
    Vector2 position,
    Vector2 size, {
    Paint? overridePaint,
    double opacity = 1,
  }) {
    if (paint.color.opacity != opacity) {
      paint.color = paint.color.withOpacity(opacity);
    }
    if (overridePaint != null && overridePaint.color.opacity != opacity) {
      overridePaint.color = overridePaint.color.withOpacity(opacity);
    }
    this.render(
      canvas,
      position: position,
      size: size,
      overridePaint: overridePaint,
    );
  }
}

extension NullableExt<T> on T? {
  FutureOr<void> let(FutureOr<void> Function(T i) call) => call(this!);
}

extension GameComponentExt on GameComponent {
  Direction? directionThePlayerIsIn() {
    Player? player = this.gameRef.player;
    if (player == null) return null;
    var diffX = center.x - player.center.x;
    var diffPositiveX = diffX < 0 ? diffX *= -1 : diffX;
    var diffY = center.y - player.center.y;
    var diffPositiveY = diffY < 0 ? diffY *= -1 : diffY;

    if (diffPositiveX > diffPositiveY) {
      if (player.center.x > center.y) {
        return Direction.right;
      } else if (player.center.x < center.y) {
        return Direction.left;
      }
    } else {
      if (player.center.y > center.x) {
        return Direction.down;
      } else if (player.center.y < position.x) {
        return Direction.up;
      }
    }

    return Direction.left;
  }
}

extension Vector2Ext on Vector2 {
  Vector2 translate(double x, double y) {
    return Vector2(this.x + x, this.y + y);
  }

  Vector2 copyWith({double? x, double? y}) {
    return Vector2(x ?? this.x, y ?? this.y);
  }
}

extension ObjectExt<T> on T {
  Future<T> asFuture() {
    return Future.value(this);
  }
}

extension FutureSpriteAnimationExt on FutureOr<SpriteAnimation> {
  widget.Widget asWidget({
    widget.Key? key,
    bool playing = true,
    Anchor anchor = Anchor.topLeft,
    widget.WidgetBuilder? errorBuilder,
    widget.WidgetBuilder? loadingBuilder,
  }) {
    if (this is Future) {
      return widget.FutureBuilder<SpriteAnimation>(
        key: key,
        future: this as Future<SpriteAnimation>,
        builder: (context, data) {
          if (!data.hasData) return widget.SizedBox.shrink();
          return widget.Container(
            constraints: widget.BoxConstraints(
              minWidth: data.data!.frames.first.sprite.src.width,
              minHeight: data.data!.frames.first.sprite.src.height,
            ),
            child: SpriteAnimationWidget(
              animation: data.data!,
              playing: playing,
              anchor: anchor,
              errorBuilder: errorBuilder,
              loadingBuilder: loadingBuilder,
            ),
          );
        },
      );
    }

    return widget.Container(
      key: key,
      constraints: widget.BoxConstraints(
        minWidth: (this as SpriteAnimation).frames.first.sprite.src.width,
        minHeight: (this as SpriteAnimation).frames.first.sprite.src.height,
      ),
      child: SpriteAnimationWidget(
        animation: this as SpriteAnimation,
        playing: playing,
        anchor: anchor,
        errorBuilder: errorBuilder,
        loadingBuilder: loadingBuilder,
      ),
    );
  }
}

extension FutureSpriteExt on FutureOr<Sprite> {
  widget.Widget asWidget({
    widget.Key? key,
    Anchor anchor = Anchor.topLeft,
    widget.WidgetBuilder? errorBuilder,
    widget.WidgetBuilder? loadingBuilder,
    double angle = 0,
    Vector2? srcPosition,
    Vector2? srcSize,
  }) {
    if (this is Future) {
      return widget.FutureBuilder<Sprite>(
        key: key,
        future: this as Future<Sprite>,
        builder: (context, data) {
          if (!data.hasData) return widget.SizedBox.shrink();
          return widget.Container(
            constraints: widget.BoxConstraints(
              minWidth: data.data!.src.width,
              minHeight: data.data!.src.height,
            ),
            child: SpriteWidget(
              sprite: data.data!,
              anchor: anchor,
              errorBuilder: errorBuilder,
              loadingBuilder: loadingBuilder,
              angle: angle,
              srcPosition: srcPosition,
              srcSize: srcSize,
            ),
          );
        },
      );
    }

    return widget.Container(
      key: key,
      constraints: widget.BoxConstraints(
        minWidth: (this as Sprite).src.width,
        minHeight: (this as Sprite).src.height,
      ),
      child: SpriteWidget(
        sprite: this as Sprite,
        anchor: anchor,
        errorBuilder: errorBuilder,
        loadingBuilder: loadingBuilder,
        angle: angle,
        srcPosition: srcPosition,
        srcSize: srcSize,
      ),
    );
  }
}

extension ComponentExt on Component {
  bool get isHud => positionType == PositionType.viewport;
}

extension CameraExt on Camera {
  void setGame(BonfireGame game) {
    if (!(this is BonfireCamera)) {
      return;
    }
    (this as BonfireCamera).gameRef = game;
  }

  GameComponent? get target => (this as BonfireCamera).target;
  set target(GameComponent? t) => (this as BonfireCamera).target = t;
  bool get isMoving => (this as BonfireCamera).isMoving;

  Rect get cameraRectWithSpacing =>
      (this as BonfireCamera).cameraRectWithSpacing;

  Rect get cameraRect => (this as BonfireCamera).cameraRect;

  void updateSpacingVisibleMap(double space) =>
      (this as BonfireCamera).updateSpacingVisibleMap(space);

  bool isComponentOnCamera(GameComponent c) =>
      (this as BonfireCamera).isComponentOnCamera(c);

  bool contains(Offset c) => (this as BonfireCamera).contains(c);

  bool isRectOnCamera(Rect c) => (this as BonfireCamera).isRectOnCamera(c);

  void moveToTargetAnimated(
    GameComponent target, {
    double zoom = 1,
    double angle = 0,
    VoidCallback? finish,
    Duration? duration,
    widget.Curve curve = widget.Curves.decelerate,
  }) {
    (this as BonfireCamera).moveToTargetAnimated(
      target,
      zoom: zoom,
      angle: angle,
      finish: finish,
      duration: duration,
      curve: curve,
    );
  }

  void moveToPlayerAnimated({
    Duration? duration,
    VoidCallback? finish,
    double zoom = 1,
    double angle = 0,
    widget.Curve curve = widget.Curves.decelerate,
  }) {
    (this as BonfireCamera).moveToPlayerAnimated(
      zoom: zoom,
      angle: angle,
      finish: finish,
      duration: duration,
      curve: curve,
    );
  }

  void moveToPositionAnimated(
    Vector2 position, {
    double zoom = 1,
    double angle = 0,
    VoidCallback? finish,
    Duration? duration,
    widget.Curve curve = widget.Curves.decelerate,
  }) {
    (this as BonfireCamera).moveToPositionAnimated(
      position,
      zoom: zoom,
      angle: angle,
      finish: finish,
      duration: duration,
      curve: curve,
    );
  }

  void moveTop(double displacement) =>
      (this as BonfireCamera).moveTop(displacement);
  void moveRight(double displacement) =>
      (this as BonfireCamera).moveRight(displacement);
  void moveDown(double displacement) =>
      (this as BonfireCamera).moveDown(displacement);
  void moveUp(double displacement) =>
      (this as BonfireCamera).moveUp(displacement);
}
