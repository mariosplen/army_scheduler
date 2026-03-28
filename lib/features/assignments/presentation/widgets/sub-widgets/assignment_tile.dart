import 'package:flutter/material.dart';
import 'package:ls_ypiresies/features/assignments/presentation/widgets/sub-widgets/assignment_tile_data.dart';
import 'package:ls_ypiresies/features/assignments/presentation/widgets/sub-widgets/assignment_tile_widget.dart';

class AssignmentTile extends StatelessWidget {
  const AssignmentTile(this.data, {Key? key}) : super(key: key);

  final AssignmentTileData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: AssignmentTileWidget(
        data.soldiers,
        title: data.title,
        reserveText: data.reserveText,
        leading: data.leading,
        onAutoFill: data.onAutoFill,
        onAddReserve: data.onAddReserve,
        onDelete: data.onDelete,
        onAccept: data.onAccept,
        onDeleteAll: data.onDeleteAll,
        onDeleteReserve: data.onDeleteReserve,
        isEditable: data.isEditable,
      ),
    );
  }
}
