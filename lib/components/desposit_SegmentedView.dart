import 'package:flutter/material.dart';


  Color color= Colors.blueGrey;
    Color textColor=Colors.black;


class SegmentedWidget extends StatelessWidget {
  const SegmentedWidget({
    required this.onChanged,
    required this.index,
    required this.children,
  });

  final ValueChanged<int> onChanged;
  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    //final color = this.color ?? Theme.of(context).accentColor;
  
    final shape = RoundedRectangleBorder(
      side: BorderSide(color: color),
      borderRadius: BorderRadius.circular(8),
    );
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: Container(
        foregroundDecoration: ShapeDecoration(
          shape: shape,
        ),       
          child: Row(
            children: [..._buildChildren(context)],
          ),  
      ),
    );
  }

  Iterable<Widget> _buildChildren(BuildContext context) sync* {
    final theme = Theme.of(context);
    //final color =  Colors.blueGrey;
    //final textColor = Colors.black;
    final style1 = TextStyle(color: Colors.black);
    final style2 = TextStyle(color: Colors.white);
    final data1 = theme.iconTheme.copyWith(color: color);
    final data2 = theme.iconTheme.copyWith(color: textColor);
    final duration = kThemeAnimationDuration;

    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        yield Container(
          color: color,
          width: 1,
        );
      }
      final selected = i == index;
      yield Expanded(
        child: GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: duration,
            color: selected ? color : color.withAlpha(0),
            padding: EdgeInsets.all(4),
            alignment: Alignment.center,
            child: AnimatedTheme(
              data: theme.copyWith(
                iconTheme: selected ? data2 : data1,
              ),
              child: AnimatedDefaultTextStyle(
                duration: duration,
                style: selected ? style2 : style1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: children[i],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
