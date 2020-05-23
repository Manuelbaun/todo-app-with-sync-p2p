import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:todo_app/sync/dao.dart';
import 'package:todo_app/sync/index.dart';

class SimpleSyncableTextField extends StatefulWidget {
  const SimpleSyncableTextField({Key key, this.id, this.initValue, this.text, this.maxLines = 1}) : super(key: key);

  final String id;
  final String initValue;
  final SyncString text;
  final int maxLines;

  @override
  _SimpleSyncableTextFieldState createState() => _SimpleSyncableTextFieldState();
}

class _SimpleSyncableTextFieldState extends State<SimpleSyncableTextField> {
  TextEditingController controller;
  FocusNode focusNode;

  SyncString syncableText;

  static final isChar = RegExp('[a-zA-Zäöü]');
  static final isNum = RegExp(r'\d');
  static final isSpecialChar = RegExp(r'[!@#<>?":_`~;,:[\]\\|=+)(*&^%\s-]');

  @override
  void initState() {
    final dao = SyncWrapper.instance.syncArray;
    LogicalKeyboardKey key;

    if (widget.text == null) {
      syncableText = dao.read(widget.id) ?? dao.create(widget.id);

      if (widget.initValue != null && widget.initValue.isNotEmpty && syncableText.values.join('').isEmpty) {
        /// insert
        ///
        for (var i = 0; i < widget.initValue.length; i++) {
          syncableText.push(widget.initValue[i]);
        }
      }
    } else {
      syncableText = widget.text;
    }

    controller = TextEditingController(text: syncableText.values?.join('') ?? '');

    TextSelection selection;
    controller.addListener(() {
      selection = controller.value.selection;
      // print(controller.value);
    });

    focusNode = FocusNode(onKey: (FocusNode node, RawKeyEvent event) {
      key = event.logicalKey;

      if (event is RawKeyDownEvent) {
        final index = (selection.baseOffset - 1) < 0 ? 0 : (selection.baseOffset - 1);
        final char = key?.keyLabel ?? '';

        if (key == LogicalKeyboardKey.backspace) {
          syncableText.removeAt(index);
        } else if (key == LogicalKeyboardKey.delete) {
          syncableText.removeAt(index + 1);
        } else if (key == LogicalKeyboardKey.space) {
          syncableText.insert(index, char);
        } else if (key == LogicalKeyboardKey.enter) {
          syncableText.insert(index, '\n');
        } else if (key == LogicalKeyboardKey.tab) {
          syncableText.insert(index, '\t');
        } else if (isChar.hasMatch(char) || isNum.hasMatch(char) || isSpecialChar.hasMatch(char)) {
          syncableText.insert(index, char);
        }
      }

      return true;
    });

    syncableText.onChange.listen((values) {
      final text = values?.join('') ?? '';

      controller.value = controller.value.copyWith(
        text: text,
        selection: controller.value.selection,
      );
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextField(
        focusNode: focusNode,
        showCursor: true,
        controller: controller,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          hintText: "Enter your text here",
          border: OutlineInputBorder(),
          labelText: 'Shareable Text',
        ),
      ),
    );
  }
}
