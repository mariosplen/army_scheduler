import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:ls_ypiresies/features/assignments/domain/repository/assignments_repository.dart';
import 'package:ls_ypiresies/features/assignments/domain/usecases/get_stored_data.dart';
import 'package:ls_ypiresies/features/assignments/domain/usecases/save_daily.dart';
import 'package:ls_ypiresies/features/assignments/domain/usecases/sign_date.dart';
import 'package:ls_ypiresies/features/assignments/presentation/cubit/assignments_cubit.dart';
import 'package:ls_ypiresies/features/assignments/presentation/cubit/warnings_cubit.dart';
import 'package:ls_ypiresies/features/assignments/presentation/widgets/date_selector.dart';
import 'package:ls_ypiresies/features/assignments/presentation/widgets/services_list.dart';
import 'package:ls_ypiresies/features/assignments/presentation/widgets/soldiers_list.dart';

class AssignmentsScreen extends StatelessWidget {
  const AssignmentsScreen([Key? key]) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 1. Create WarningsCubit first so it is available in the context
        BlocProvider<WarningsCubit>(
          create: (context) => WarningsCubit(),
        ),
        // 2. Create AssignmentsCubit, which depends on WarningsCubit
        BlocProvider<AssignmentsCubit>(
          create: (context) => AssignmentsCubit(
            getStoredData: GetStoredData(context.read<AssignmentsRepository>()),
            saveDaily: SaveDaily(context.read<AssignmentsRepository>()),
            signDate: SignDate(context.read<AssignmentsRepository>()),
            warningsCubit: context.read<WarningsCubit>(),
          ),
        ),
      ],
      child: const AssignmentsView(),
    );
  }
}

class AssignmentsView extends StatefulWidget {
  const AssignmentsView({Key? key}) : super(key: key);

  @override
  State<AssignmentsView> createState() => _AssignmentsViewState();
}

class _AssignmentsViewState extends State<AssignmentsView> {
  @override
  void initState() {
    super.initState();

    FlutterWindowClose.setWindowShouldCloseHandler(() async {
      final cubit = context.read<AssignmentsCubit>();
      final unsavedDates = cubit.getUnsavedDates();

      // If no unsaved changes, allow closing immediately
      if (unsavedDates.isEmpty) {
        return true;
      }

      // Show dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Μη αποθηκευμένες αλλαγές'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                    'Δεν έχετε αποθηκεύσει τις αλλαγές για αυτές τις μέρες: ${unsavedDates.map((d) => d.toReadableString()).join(", ")}',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Αν κλείσετε την εφαρμογή, δεν θα αποθηκευτούν οι αλλαγές σας.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Άκυρο
                child: const Text('Άκυρο'),
              ),
              TextButton(
                onPressed: () async {
                  // Save all and then close
                  await cubit.saveAll(unsavedDates);
                  if (context.mounted) Navigator.of(context).pop(true);
                },
                child: const Text('Αποθήκευση όλων'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                // Κλείσιμο without saving
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Κλείσιμο'),
              ),
            ],
          );
        },
      );

      return result ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AssignmentsCubit, AssignmentsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _buildDateSelector(),
              _buildWarnings(),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildSoldierList(),
                    ),
                    VerticalDivider(width: 1, color: Colors.grey.shade300),
                    Expanded(
                      flex: 7,
                      child: _buildServicesList(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    return BlocBuilder<AssignmentsCubit, AssignmentsState>(
      builder: (context, state) {
        final c = context.read<AssignmentsCubit>();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DateSelector(
            date: state.daily.date,
            isSigned: state.daily.isSigned,
            hasChanges: c.hasChanges(),
            onPressedNextDay: c.onPressedNextDay,
            onPressedPrevDay: c.onPressedPrevDay,
            onSaveDaily: c.saveChanges,
            onSignDay: c.signDay,
            onNewDatePicked: c.onNewDatePicked,
            onCreateDocument: c.printDaily,
            minDate: state.minDate,
            maxDate: state.maxDate,
            isHoliday: state.daily.isHoliday || state.daily.isWeekend,
            isMarketClosed: state.daily.isMilitaryMarketClosed ||
                state.daily.isSunday ||
                state.daily.isMonday,
          ),
        );
      },
    );
  }

  Widget _buildWarnings() {
    return BlocBuilder<WarningsCubit, WarningsState>(
      builder: (context, state) {
        if (state.warnings.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          color: Colors.orange.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: state.warnings
                .map(
                  (warning) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.deepOrange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            warning,
                            style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildSoldierList() {
    return BlocBuilder<AssignmentsCubit, AssignmentsState>(
      builder: (context, state) {
        return SoldiersList(
          daily: state.daily,
        );
      },
    );
  }

  Widget _buildServicesList() {
    return BlocBuilder<AssignmentsCubit, AssignmentsState>(
      builder: (context, state) {
        return ServicesList(
          daily: state.daily,
          previousDaily: context.read<AssignmentsCubit>().getPreviousDaily(),
          date: state.daily.date,
          flagLoweringTime:
              context.read<AssignmentsCubit>().getFlagLoweringTime(),
          onAssign: context.read<AssignmentsCubit>().onAssign,
        );
      },
    );
  }
}
