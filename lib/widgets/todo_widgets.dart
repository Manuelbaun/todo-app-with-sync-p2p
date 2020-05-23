import 'package:flutter/material.dart';
import 'package:sync_layer/logger/logger.dart';
import 'package:todo_app/sync/dao.dart';
import 'package:todo_app/widgets/simple_text_editor_widget.dart';

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
  const TodoIconDrag({Key key, @required this.item}) : super(key: key);

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

class TodoWidget extends StatelessWidget {
  const TodoWidget({
    Key key,
    @required this.todos,
    @required this.connected,
  }) : super(key: key);

  final List<Todo> todos;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
        key: Key("${todos.length}"),
        // height: 300,
        // width: 600,
        constraints: BoxConstraints.tight(Size(600, 300)),
        child: ListView.builder(
          itemCount: todos.length,
          itemBuilder: (ctx, index) {
            final todo = todos[todos.length - 1 - index];

            return ListTile(
                key: Key(todo.id),
                leading: DragZoneTodo(item: todo),
                title: SimpleSyncableTextField(id: '00', text: todo.title),
                subtitle: Container(
                  width: 120,
                  child: (todo.assignee != null && todo.assignee.tombstone == false)
                      ? StreamBuilder<Object>(
                          stream: todo.assignee.onChange,
                          builder: (context, snapshot) {
                            return Text(todo.assignee.firstName);
                          })
                      : Text('no assignee yet'),
                ),
                trailing: Container(
                  constraints: BoxConstraints.expand(width: 110),
                  child: ButtonBar(
                    alignment: MainAxisAlignment.start,
                    layoutBehavior: ButtonBarLayoutBehavior.padded,
                    mainAxisSize: MainAxisSize.max,
                    buttonAlignedDropdown: connected,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle),
                        color: todo.status ? Colors.green : Colors.grey,
                        onPressed: () => todo.status = !todo.status,
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel),
                        color: Colors.red,
                        onPressed: () => todo.delete(),
                      ),
                    ],
                  ),
                )
                // onTap: () => todo.status = !todo.status,
                );
          },
        ));
  }
}
