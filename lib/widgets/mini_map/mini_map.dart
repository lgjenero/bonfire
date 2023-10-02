import 'dart:async' as async;

import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';

import 'mini_map_canvas.dart';

///
/// Created by
///
/// ─▄▀─▄▀
/// ──▀──▀
/// █▀▀▀▀▀█▄
/// █░░░░░█─█
/// ▀▄▄▄▄▄▀▀
///
/// Rafaelbarbosatec
/// on 12/04/22

typedef MiniMapCustomRender<T extends GameComponent> = void Function(
    Canvas canvas, T component);

class MiniMap extends StatefulWidget {
  final BonfireGame game;
  final MiniMapCustomRender<Tile>? tileRender;
  final MiniMapCustomRender? componentsRender;
  final Vector2 size;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final BoxBorder? border;
  final Color? tileCollisionColor;
  final Color? tileColor;
  final Color? playerColor;
  final Color? enemyColor;
  final Color? npcColor;
  final Color? allyColor;
  final Color? decorationColor;
  final double zoom;
  MiniMap({
    Key? key,
    required this.game,
    this.tileRender,
    this.componentsRender,
    Vector2? size,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.tileCollisionColor,
    this.tileColor,
    this.playerColor,
    this.enemyColor,
    this.npcColor,
    this.allyColor,
    this.zoom = 1.0,
    this.decorationColor,
  })  : size = size ?? Vector2(200, 200),
        super(key: key);

  @override
  State<MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<MiniMap> {
  Vector2 cameraPosition = Vector2.zero();
  Vector2 playerPosition = Vector2.zero();

  Paint tilePaint = Paint();
  Paint tileCollisionPaint = Paint();
  Paint paintComponent = Paint();

  late async.Timer timer;
  @override
  void initState() {
    _initInterval();
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.game.hasLayout) {
      return const SizedBox.shrink();
    }
    return Positioned(
      right: 0,
      child: Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: Container(
            width: widget.size.x,
            height: widget.size.y,
            decoration: BoxDecoration(
              border: widget.border,
              color: widget.backgroundColor ?? Colors.grey.withOpacity(0.5),
              borderRadius: widget.borderRadius,
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.zero,
              child: CustomPaint(
                painter: MiniMapCanvas(
                  components: widget.game.visibles(),
                  tiles: widget.game.map.getRendered(),
                  cameraPosition: cameraPosition,
                  playerPosition: playerPosition,
                  gameSize: widget.game.size,
                  componentsRender:
                      widget.componentsRender ?? componentsRenderDefault(),
                  tileRender: widget.tileRender ?? tilesRenderDefault(),
                  zoom: widget.zoom,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _initInterval() {
    timer = async.Timer.periodic(const Duration(milliseconds: 34), (timer) {
      if (!widget.game.bonfireCamera.isMounted) {
        return;
      }
      bool needSetState = false;
      if (widget.game.bonfireCamera.position != cameraPosition) {
        cameraPosition = widget.game.bonfireCamera.topleft.clone();
        needSetState = true;
      }

      if (widget.game.player?.position != playerPosition) {
        playerPosition = widget.game.player?.position.clone() ?? Vector2.zero();
        needSetState = true;
      }

      if (needSetState) {
        setState(() {});
      }
    });
  }

  MiniMapCustomRender<Tile> tilesRenderDefault() => (canvas, component) {
        var collisionList = component.children.query<ShapeHitbox>();
        if (collisionList.isEmpty && widget.tileColor != null) {
          canvas.drawRect(
            component.toRect(),
            tilePaint..color = widget.tileColor!,
          );
        } else {
          for (var element in collisionList) {
            var rect = element.toRect();
            canvas.drawRect(
              rect.translate(component.x, component.y),
              tileCollisionPaint
                ..color =
                    widget.tileCollisionColor ?? Colors.black.withOpacity(0.5),
            );
          }
        }
      };

  MiniMapCustomRender componentsRenderDefault() => (canvas, component) {
        if (component is Player) {
          canvas.drawCircle(
            component.center.toOffset(),
            component.width / 2,
            paintComponent
              ..color = widget.playerColor ?? Colors.cyan.withOpacity(0.5),
          );
          return;
        }

        if (component is Enemy) {
          canvas.drawCircle(
            component.center.toOffset(),
            component.width / 2,
            paintComponent
              ..color = widget.enemyColor ?? Colors.red.withOpacity(0.5),
          );
          return;
        }

        if (component is Ally) {
          canvas.drawCircle(
            component.center.toOffset(),
            component.width / 2,
            paintComponent
              ..color = widget.allyColor ?? Colors.yellow.withOpacity(0.5),
          );
          return;
        }

        if (component is Npc) {
          canvas.drawCircle(
            component.center.toOffset(),
            component.width / 2,
            paintComponent
              ..color = widget.npcColor ?? Colors.green.withOpacity(0.5),
          );
          return;
        }

        if (component is GameDecoration) {
          canvas.drawRect(
            component.toRect(),
            paintComponent
              ..color = widget.decorationColor ?? Colors.grey.withOpacity(0.5),
          );
        }
      };
}
