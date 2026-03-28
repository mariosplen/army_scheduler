import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Added for context.read
import 'package:ls_ypiresies/core/entities/daily.dart';
import 'package:ls_ypiresies/core/entities/date.dart';
import 'package:ls_ypiresies/core/entities/soldier.dart';
import 'package:ls_ypiresies/core/enums/slot.dart';
import 'package:ls_ypiresies/features/assignments/presentation/cubit/assignments_cubit.dart'; // Added for Cubit
import 'package:ls_ypiresies/features/assignments/presentation/widgets/sub-widgets/assignment_tile.dart';
import 'package:ls_ypiresies/features/assignments/presentation/widgets/sub-widgets/assignment_tile_data.dart';
import 'package:ls_ypiresies/features/assignments/presentation/widgets/sub-widgets/row_with_reserve.dart';
import 'package:ls_ypiresies/features/assignments/presentation/widgets/sub-widgets/section.dart';
import 'package:ls_ypiresies/features/assignments/presentation/widgets/sub-widgets/times.dart';

class ServicesList extends StatelessWidget {
  final Daily daily;
  final Date date;
  final String flagLoweringTime;
  final Daily? previousDaily;
  final void Function({
    Soldier? soldier,
    required Slot slot,
    bool isAdding,
  })? onAssign;

  const ServicesList({
    Key? key,
    required this.daily,
    this.previousDaily, // Added to constructor
    required this.date,
    required this.flagLoweringTime,
    this.onAssign,
  }) : super(key: key);

  // Logic to show dialog and assign reserve
  void _handleReserveTap(BuildContext context, Slot slot) {
    final reserveSlot = AssignmentTileData.getReserveSlot(slot);
    if (reserveSlot == null) return;

    // Get the cubit instance
    final cubit = context.read<AssignmentsCubit>();
    final availableSoldiers =
        (Slot.dormGuard3 == slot || Slot.reserveDormGuard3 == slot)
            ? cubit.getAvailableSoldiersOfTomorow()
            : cubit.getAvailableSoldiers();

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Επιλογή Κωλυόμενου'),
        children: availableSoldiers.isEmpty
            ? [
                const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Δεν υπάρχουν διαθέσιμοι οπλίτες'))
              ]
            : availableSoldiers.map((soldier) {
                // Get the reserve count for this soldier
                final reservesCount = cubit.getTotalReservesForMonth(soldier);
                final role = soldier.role ?? '-';
                final yesterdayService = _getYesterdayService(soldier);

                return SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    onAssign?.call(
                      soldier: soldier,
                      slot: reserveSlot,
                      isAdding: true,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        soldier.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$role | Χθες: $yesterdayService | Κωλ: $reservesCount',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }

  String _getYesterdayService(Soldier soldier) {
    if (previousDaily == null) return '-';
    final p = previousDaily!.program;
    final o = previousDaily!.otherTasks;

    if (p.post1 == soldier) return 'ΣΚ1';
    if (p.hiddenPost1 == soldier) return 'ΣΚ1';
    if (p.post2 == soldier) return 'ΣΚ2';
    if (p.hiddenPost2 == soldier) return 'ΣΚ2';
    if (p.post3 == soldier) return 'ΣΚ3';
    if (p.hiddenPost3 == soldier) return 'ΣΚ3';

    if (p.dormGuard1 == soldier) return 'ΘΑΛ1';
    if (p.dormGuard2 == soldier) return 'ΘΑΛ2';
    if (p.dormGuard3 == soldier) return 'ΘΑΛ3';

    if (p.dutySergeant == soldier) return 'ΛΥΛ';
    if (p.kitchen == soldier) return 'ΕΣΤ';
    if (p.gep == soldier) return 'ΓΕΠ';

    if (o.kpsm == soldier) return 'ΚΨΜ';
    if (p.dpvCanteen == soldier) return 'ΚΨΜ ΔΠΒ';
    if (p.divisionCanteen.contains(soldier)) return 'ΚΨΜ ΜΕΡ';

    if (p.onLeave.contains(soldier)) return 'Άδεια';
    if (p.detached.contains(soldier)) return 'Διάθεση';
    if (p.exempt.contains(soldier)) return 'ΕΥ';

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Section(
            title: 'ΣΚΟΠΟΙ',
            children: [
              Row(
                children: [
                  const Times(
                    '08:00 - 10:00\n14:00 - 16:00\n20:00 - 22:00\n02:00 - 04:00',
                  ),
                  Expanded(
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: AssignmentTile(
                              AssignmentTileData.factory(
                                slot: Slot.post1,
                                daily: daily,
                                onAssign: onAssign,
                                onAddReserve: (slot) =>
                                    _handleReserveTap(context, slot),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AssignmentTile(
                              AssignmentTileData.factory(
                                slot: Slot.hiddenPost1,
                                daily: daily,
                                onAssign: onAssign,
                                onAddReserve: (slot) =>
                                    _handleReserveTap(context, slot),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Times(
                    '10:00 - 12:00\n16:00 - 18:00\n22:00 - 00:00\n04:00 - 06:00',
                  ),
                  Expanded(
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: AssignmentTile(
                              AssignmentTileData.factory(
                                slot: Slot.post2,
                                daily: daily,
                                onAssign: onAssign,
                                onAddReserve: (slot) =>
                                    _handleReserveTap(context, slot),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AssignmentTile(
                              AssignmentTileData.factory(
                                slot: Slot.hiddenPost2,
                                daily: daily,
                                onAssign: onAssign,
                                onAddReserve: (slot) =>
                                    _handleReserveTap(context, slot),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Times(
                    '12:00 - 14:00\n18:00 - 20:00\n00:00 - 02:00\n06:00 - 08:00',
                  ),
                  Expanded(
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: AssignmentTile(
                              AssignmentTileData.factory(
                                slot: Slot.post3,
                                daily: daily,
                                onAssign: onAssign,
                                onAddReserve: (slot) =>
                                    _handleReserveTap(context, slot),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AssignmentTile(
                              AssignmentTileData.factory(
                                slot: Slot.hiddenPost3,
                                daily: daily,
                                onAssign: onAssign,
                                onAddReserve: (slot) =>
                                    _handleReserveTap(context, slot),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Section(
            title: 'ΘΑΛΑΜΟΦΥΛΑΚΕΣ',
            children: [
              Row(
                children: [
                  const Times('09:00 - 12:00\n18:00 - 21:00\n02:00 - 04:00'),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.dormGuard1,
                        daily: daily,
                        onAssign: onAssign,
                        onAddReserve: (slot) =>
                            _handleReserveTap(context, slot),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Times('12:00 - 15:00\n21:00 - 00:00\n04:00 - 06:00'),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.dormGuard2,
                        daily: daily,
                        onAssign: onAssign,
                        onAddReserve: (slot) =>
                            _handleReserveTap(context, slot),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Times('15:00 - 18:00\n00:00 - 02:00\n06:00 - 09:00'),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.dormGuard3,
                        daily: daily,
                        onAssign: onAssign,
                        onAddReserve: (slot) =>
                            _handleReserveTap(context, slot),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // ... The rest of the file remains unchanged as other sections don't support reserves in the current logic
          Section(
            title: 'ΣΗΜΑΙΑ',
            children: [
              AssignmentTile(
                AssignmentTileData.factory(
                  slot: Slot.flagRising,
                  daily: daily,
                  onAssign: onAssign,
                ),
              ),
              AssignmentTile(
                AssignmentTileData.factory(
                  slot: Slot.flagLowering,
                  daily: daily,
                  time: flagLoweringTime,
                  onAssign: onAssign,
                ),
              ),
            ],
          ),
          Section(
            title: 'ΚΑΘΑΡΙΟΤΗΤΕΣ ΚΑΙ ΛΟΙΠΑ',
            children: [
              RowWithReserve(
                children: [
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.cleanSupervisorArea,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.cleanDivisionArea,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                ],
              ),
              RowWithReserve(
                children: [
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.cleanBarracksArea,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.cleanToiletsArea,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.foodTransferLunch,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                ],
              ),
              RowWithReserve(
                children: [
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.cleanBinArea,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.cleanDormGuardArea,
                        previousDaily: previousDaily, // Pass it here
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.passengerForFoodDinner,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.foodTransferDinner,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                ],
              ),
              RowWithReserve(
                children: [
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.passengerForFoodLunch,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.gep,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.kitchen,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.dutySergeant,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                ],
              ),
              RowWithReserve(
                children: [
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.kpsm,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.dpvCanteen,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.divisionCanteen,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 2,
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.free,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AssignmentTile(
                      AssignmentTileData.factory(
                        slot: Slot.onLeave,
                        daily: daily,
                        onAssign: onAssign,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        AssignmentTile(
                          AssignmentTileData.factory(
                            slot: Slot.exempt,
                            daily: daily,
                            onAssign: onAssign,
                          ),
                        ),
                        AssignmentTile(
                          AssignmentTileData.factory(
                            slot: Slot.detached,
                            daily: daily,
                            onAssign: onAssign,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
