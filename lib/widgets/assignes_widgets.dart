import 'package:flutter/material.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:sync_layer/logger/logger.dart';
import 'package:todo_app/sync/dao.dart';

class AssigneIconDrag extends StatelessWidget {
  const AssigneIconDrag({Key key, @required this.item, this.connected}) : super(key: key);

  final Assignee item;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Draggable<Assignee>(
      data: item,
      child: IconShadowWidget(Icon(Icons.people, color: connected ? Colors.green : Colors.red, size: 40),
          showShadow: true),
      feedback: IconShadowWidget(Icon(Icons.people, color: Colors.grey)),
      childWhenDragging: IconShadowWidget(Icon(Icons.people), showShadow: true),
    );
  }
}

class DragZoneAssignee extends StatelessWidget {
  const DragZoneAssignee({Key key, this.item, this.connected}) : super(key: key);
  final Assignee item;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Todo>(
      builder: (BuildContext context, List<Todo> incoming, List rejected) {
        return Container(
          child: AssigneIconDrag(item: item, connected: connected),
          width: 50,
          height: 50,
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

class PeopleWidget extends StatelessWidget {
  const PeopleWidget({
    Key key,
    @required this.people,
    @required this.firstName,
    @required this.connected,
  }) : super(key: key);

  final List<Assignee> people;
  final Map<String, TextEditingController> firstName;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
        key: Key("${people.length}"),
        child: ListView.builder(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemCount: people.length,
            itemBuilder: (ctx, index) {
              final p = people[people.length - 1 - index];

              if (firstName[p.id] == null) {
                firstName[p.id] = TextEditingController(text: p.firstName);
                firstName[p.id].addListener(() {
                  if (p.firstName != firstName[p.id].text) {
                    p.firstName = firstName[p.id].text;
                  }
                });
              } else {
                // copy time!! => :cry
                firstName[p.id].value =
                    firstName[p.id].value.copyWith(text: p.firstName, selection: firstName[p.id].value.selection);
              }

              return ListTile(
                  key: Key(p.id),
                  leading: DragZoneAssignee(
                    item: p,
                    connected: p.todo != null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: TextField(controller: firstName[p.id]),
                        flex: 2,
                      ),
                      Expanded(
                        child: Text(p.lastName),
                        flex: 2,
                      ),
                      Expanded(
                        child: Text(p.age.toString()),
                        flex: 1,
                      )
                    ],
                  ),
                  subtitle: Container(
                      width: 120,
                      child: (p.todo != null && p.todo.tombstone == false)
                          ? StreamBuilder<List<dynamic>>(
                              stream: p.todo.title.onChange,
                              builder: (context, snapshot) {
                                return Text(p.todo.title.value ?? '');
                              })
                          : Text('not assigned yet')),
                  trailing: Container(
                    constraints: BoxConstraints.expand(width: 110),
                    child: ButtonBar(
                      alignment: MainAxisAlignment.start,
                      layoutBehavior: ButtonBarLayoutBehavior.padded,
                      mainAxisSize: MainAxisSize.max,
                      buttonAlignedDropdown: connected,
                      children: [
                        IconButton(
                          icon: Icon(Icons.cancel),
                          color: Colors.red,
                          onPressed: () => p.delete(),
                        ),
                      ],
                    ),
                  )
                  // onTap: () => todo.status = !todo.status,
                  );
            }));
  }
}
