import 'package:flutter/material.dart';
import 'package:sync_layer/logger/logger.dart';
import 'package:todo_app/sync/dao.dart';

class DragZoneTodo extends StatelessWidget {
  const DragZoneTodo({Key key, this.item}) : super(key: key);
  final Todo item;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Assignee>(
      builder: (BuildContext context, List<Assignee> incoming, List rejected) {
        return Container(
          child: TodoIconDrag(item: item),
          width: 50,
          height: 50,
          // margin: EdgeInsets.all(100.0),
          color: Colors.black,
          // decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
        );
      },
      onWillAccept: (data) {
        // print(data);
        return true;
      },
      onAccept: (data) {
        logger.info(data.toString());
        item.assignee = data;
      },
    );
  }
}

class TodoIconDrag extends StatelessWidget {
  const TodoIconDrag({
    Key key,
    @required this.item,
  }) : super(key: key);

  final Todo item;

  @override
  Widget build(BuildContext context) {
    return Draggable<Todo>(
      data: item,
      child: Icon(Icons.work, color: Colors.green),
      feedback: Icon(Icons.work, color: Colors.pink),
      childWhenDragging: Icon(Icons.work),
    );
  }
}
