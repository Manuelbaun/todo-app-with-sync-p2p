import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/sync/index.dart';

class TodoType extends SyncableMap<int, TodoType> {
  TodoType(AccessProxy proxy, {String id}) : super(proxy, id);

  String get name => super[0];
  set name(String v) => super[0] = v;

  int get color => super[1];
  set color(int c) => super[1] = c;
}
