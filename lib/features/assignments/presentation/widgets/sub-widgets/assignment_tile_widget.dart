import 'package:flutter/material.dart';
import 'package:ls_ypiresies/core/entities/soldier.dart';
import 'package:ls_ypiresies/core/theme/app_colors.dart';
import 'package:ls_ypiresies/features/assignments/presentation/widgets/sub-widgets/soldier_chip.dart';

class AssignmentTileWidget extends StatelessWidget {
  final List<Soldier> soldiers;
  final String? title;
  final String? reserveText;
  final Widget? leading;
  final bool isEditable;
  final VoidCallback? onAutoFill;
  final VoidCallback? onAddReserve;
  final VoidCallback? onDeleteReserve;
  final VoidCallback? onDeleteAll;
  final ValueChanged<Soldier>? onAccept;
  final void Function({Soldier? soldier})? onDelete;

  const AssignmentTileWidget(
    this.soldiers, {
    Key? key,
    this.title,
    this.reserveText,
    this.leading,
    this.onAutoFill,
    this.onAddReserve,
    this.onDeleteReserve,
    this.onDeleteAll,
    this.onAccept,
    this.onDelete,
    this.isEditable = true,
  }) : super(key: key);

  bool get _shouldShowDeleteAll =>
      onDeleteAll != null &&
      (soldiers.length == 1 || soldiers.length >= 3) &&
      isEditable;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Soldier>(
      onWillAccept: (_) => isEditable,
      onAccept: onAccept,
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHovered ? AppColors.blue.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHovered ? AppColors.blue : Colors.grey.shade300,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _buildSoldierContent()),
                  if (_shouldShowDeleteAll)
                    _buildActionIcon(
                      icon: Icons.close,
                      tooltip: 'Αφαίρεση',
                      size: 16,
                      onTap: onDeleteAll,
                    ),
                ],
              ),
              if (reserveText != null) _buildReserveFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              if (title != null)
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Actions Section
        Row(
          children: [
            if (onAutoFill != null)
              _buildActionIcon(
                icon: Icons.auto_fix_high,
                tooltip: 'Έξυπνη συμπλήρωση',
                color: AppColors.blue.withOpacity(0.7),
                onTap: onAutoFill,
              ),
            if (onAddReserve != null) ...[
              const SizedBox(width: 4),
              _buildActionIcon(
                icon: Icons.shield_outlined,
                tooltip: 'Προσθήκη κωλυόμενου',
                color: AppColors.orange,
                onTap: onAddReserve,
              ),
            ],
            if (soldiers.length >= 5)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.blue.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  soldiers.length.toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSoldierContent() {
    if (soldiers.length >= 2) {
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        children: soldiers
            .map(
              (s) => SoldierChip(
                text: s.name,
                onDelete: isEditable ? () => onDelete?.call(soldier: s) : null,
              ),
            )
            .toList(),
      );
    }

    return Text(
      soldiers.firstOrNull?.name ?? '-',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildReserveFooter() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.only(top: 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, size: 12, color: AppColors.orange),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              reserveText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          if (onDeleteReserve != null)
            _buildActionIcon(
              icon: Icons.close,
              tooltip: 'Αφαίρεση κωλυόμενου',
              onTap: onDeleteReserve,
            ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    Color color = Colors.grey,
    double size = 14,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}
