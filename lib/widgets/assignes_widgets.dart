import 'package:flutter/material.dart';
import 'package:sync_layer/logger/logger.dart';
import 'package:todo_app/sync/dao.dart';

class AssigneIconDrag extends StatelessWidget {
  const AssigneIconDrag({
    Key key,
    @required this.item,
  }) : super(key: key);

  final Assignee item;

  @override
  Widget build(BuildContext context) {
    return Draggable<Assignee>(
      data: item,
      child: Icon(Icons.people, color: Colors.deepOrange, size: 40,),
      feedback: Icon(Icons.people, color: Colors.pink),
      childWhenDragging: Icon(Icons.people),
    );
  }
}

class DragZoneAssignee extends StatelessWidget {
  const DragZoneAssignee({Key key, this.item}) : super(key: key);
  final Assignee item;
  @override
  Widget build(BuildContext context) {
    return DragTarget<Todo>(
      builder: (BuildContext context, List<Todo> incoming, List rejected) {
        return Container(
          child: AssigneIconDrag(item: item),
          width: 50,
          height: 50,
          // margin: EdgeInsets.all(100.0),
          // color: Colors.blueAccent,
          // decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
        );
      },
      onWillAccept: (data) {
        return true;
      },
      onAccept: (data) {
        logger.info(data.toString());
        item.todo = data;
      },
    );
  }
}
