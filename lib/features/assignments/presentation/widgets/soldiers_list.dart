import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ls_ypiresies/core/entities/daily.dart';
import 'package:ls_ypiresies/core/entities/soldier.dart';
import 'package:ls_ypiresies/features/assignments/presentation/cubit/assignments_cubit.dart';

class SoldiersList extends StatelessWidget {
  final Daily daily;

  const SoldiersList({required this.daily, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssignmentsCubit>();
    final freeSoldiers = daily.totalFree.toSet();

    // 1. Group soldiers by role
    final Map<String, List<Soldier>> groupedSoldiers = {};
    for (var soldier in daily.canBeAssignedToServiceOrCleaning) {
      final role = (soldier.role != null && soldier.role!.isNotEmpty)
          ? soldier.role!
          : 'No Role';
      
      if (!groupedSoldiers.containsKey(role)) {
        groupedSoldiers[role] = [];
      }
      groupedSoldiers[role]!.add(soldier);
    }

    // 2. Sort groups by size (descending)
    final sortedGroupKeys = groupedSoldiers.keys.toList()
      ..sort((a, b) => groupedSoldiers[b]!.length.compareTo(groupedSoldiers[a]!.length));

    // 3. Sort soldiers within each group by rate (ascending)
    for (var key in sortedGroupKeys) {
      groupedSoldiers[key]!.sort((a, b) {
        final rateA = cubit.getDaysSinceLastExit(a);
        final rateB = cubit.getDaysSinceLastExit(b);
        return rateA.compareTo(rateB);
      });
    }

    // 4. Build the flattened list of widgets (Headers + Soldiers)
    final List<Widget> listChildren = [];
    for (var groupName in sortedGroupKeys) {
      final soldiersInGroup = groupedSoldiers[groupName]!;
      
      // Add Group Header
      listChildren.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Text(
                groupName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${soldiersInGroup.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Add Soldiers in this group
      for (var soldier in soldiersInGroup) {
        final int exits = cubit.getTotalExitsForMonth(soldier);
        final int services = cubit.getTotalServicesForMonth(soldier);
        final int rate = cubit.getDaysSinceLastExit(soldier);
        final isAssigned = !freeSoldiers.contains(soldier);

        listChildren.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _SoldierStatTile(
              soldier: soldier,
              details: 'Αυτόν τον μήνα:  ΕΞ:$exits   ΥΠ:$services',
              rate: rate,
              isAssigned: isAssigned,
            ),
          ),
        );
      }
    }

    return Column(
      children: [
        // --- HEADER ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Text(
                'ΔΥΝΑΜΗ (${daily.manpower.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              IconButton(
                onPressed: () => _showAddSoldierDialog(context, cubit),
                icon: const Icon(Icons.person_add_alt_1, color: Colors.blue),
                tooltip: 'Add Temporary Soldier',
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // List
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 12),
              children: listChildren,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddSoldierDialog(BuildContext context, AssignmentsCubit cubit) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Temporary Soldier'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              hintText: 'e.g. PAPADOPOULOS',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  cubit.addSoldier(nameController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class _SoldierStatTile extends StatelessWidget {
  final Soldier soldier;
  final String details;
  final int rate;
  final bool isAssigned;

  const _SoldierStatTile({
    required this.soldier,
    required this.details,
    required this.rate,
    this.isAssigned = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = rate > 2.0
        ? Colors.redAccent
        : (rate > 1.0 ? Colors.orange : Colors.green);

    // The visual representation of the soldier card
    final childWidget = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade50,
            child: Text(
              soldier.name.isNotEmpty ? soldier.name[0] : '?',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        soldier.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (soldier.role != null && soldier.role!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.indigo.shade100,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          soldier.role!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              rate.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );

    // Wrap in Draggable
    return Draggable<Soldier>(
      data: soldier,
      feedback: SizedBox(
        width: 250,
        child: Opacity(opacity: 0.9, child: childWidget),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: childWidget),
      child:
          isAssigned ? Opacity(opacity: 0.5, child: childWidget) : childWidget,
    );
  }
}