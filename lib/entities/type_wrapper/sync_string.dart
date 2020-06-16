import 'package:sync_layer/sync/abstract/acess_proxy.dart';
import 'package:sync_layer/sync/syncable_causal_tree.dart';

class SyncString extends SyncableCausalTree<String, SyncString> {
  SyncString(AccessProxy proxy, {String id}) : super(proxy, id);

  String get value => values.join('');
}
