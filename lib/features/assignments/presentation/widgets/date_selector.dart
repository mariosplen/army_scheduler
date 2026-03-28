import 'package:flutter/material.dart';
import 'package:ls_ypiresies/core/entities/date.dart';
import 'package:ls_ypiresies/core/theme/app_colors.dart';

class DateSelector extends StatelessWidget {
  final Date date;
  final bool isSigned;
  final bool hasChanges;
  final bool isHoliday;
  final bool isMarketClosed;
  final VoidCallback? onPressedPrevDay;
  final VoidCallback? onPressedNextDay;
  final VoidCallback? onSignDay;
  final VoidCallback? onSaveDaily;
  final VoidCallback? onCreateDocument;
  final Function(Date date)? onNewDatePicked;
  final Date? minDate;
  final Date? maxDate;

  const DateSelector({
    required this.date,
    required this.isSigned,
    required this.hasChanges,
    this.isHoliday = false,
    this.isMarketClosed = false,
    this.onPressedNextDay,
    this.onPressedPrevDay,
    this.onCreateDocument,
    this.onSaveDaily,
    this.onSignDay,
    this.onNewDatePicked,
    this.minDate,
    this.maxDate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            TooltipVisibility(
              visible: isMarketClosed,
              child: Tooltip(
                message: 'Ρυθμίζεται από το excel, στο φύλλο "ΠΡΑΤΗΡΙΟ"',
                child: Text(
                  'ΠΡΑΤΗΡΙΟ ΚΛΕΙΣΤΟ',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isMarketClosed ? Colors.deepOrange : Colors.transparent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            TooltipVisibility(
              visible: isHoliday,
              child: Tooltip(
                message: 'Ρυθμίζεται από το excel, στο φύλλο "ΑΡΓΙΕΣ"',
                child: Text(
                  'ΑΡΓΙΑ',
                  style: TextStyle(
                    fontSize: 13,
                    color: isHoliday ? AppColors.red : Colors.transparent,
                    fontWeight: FontWeight.bold,
                    decoration: isHoliday ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ),
            TooltipVisibility(
              visible: onNewDatePicked != null,
              child: Tooltip(
                message: 'Επιλέξτε Ημερομηνία',
                child: TextButton(
                  onPressed: _onTap(context),
                  child: Text(
                    date.toGreekString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            TooltipVisibility(
              visible: isSigned,
              child: Tooltip(
                message: 'Εχει υπογραφεί από τον ΔΚΤΗ',
                verticalOffset: 10,
                child: Text(
                  'Υπογεγραμμένο',
                  style: TextStyle(
                    fontSize: 13,
                    color: isSigned ? AppColors.blue : Colors.transparent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // placeholder toalign the other rows
            const Text(
              '',
              style: TextStyle(
                fontSize: 13,
                color: Colors.transparent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  child: Image.asset('assets/logo.jpg', height: 80),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onPressedPrevDay,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Προηγούμενη ημέρα',
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onPressedNextDay,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  tooltip: 'Επόμενη ημέρα',
                ),
                const SizedBox(width: 8),
                IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Tooltip(
                        message: hasChanges
                            ? 'Αποθηκεύστε τις αλλαγές στο excel'
                            : 'Δεν υπάρχουν αλλαγές για αποθήκευση στο excel',
                        child: ElevatedButton.icon(
                          onPressed: hasChanges ? onSaveDaily : null,
                          icon: const Icon(Icons.save_rounded),
                          label: const Text(
                            'ΑΠΟΘΗΚΕΥΣΗ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: hasChanges
                                ? AppColors.green
                                : Colors.grey.shade400,
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Tooltip(
                        message:
                            'Αποθήκευση Εντύπων στα Δεδομένα του υπολογιστή',
                        child: ElevatedButton.icon(
                          onPressed: onCreateDocument,
                          icon: const Icon(Icons.document_scanner),
                          label: const Text(
                            'ΕΞΑΓΩΓΗ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: AppColors.blue,
                            alignment: Alignment.centerLeft,
                          ),
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
    );
  }

  Future<void> Function()? _onTap(BuildContext context) {
    return onNewDatePicked != null
        ? () async {
            // Determine range from stored data or fallback to defaults
            DateTime firstDate = minDate?.toDateTime() ?? DateTime(2026);
            DateTime lastDate = maxDate?.toDateTime() ?? DateTime(2040);

            // The current selection (initialDate) must be within [firstDate, lastDate].
            // If the current date is outside the stored range, we extend the range
            // locally for this picker session to prevent a crash.
            final DateTime initialDate = date.toDateTime();

            if (initialDate.isBefore(firstDate)) {
              firstDate = initialDate;
            }
            if (initialDate.isAfter(lastDate)) {
              lastDate = initialDate;
            }

            final pickedDate = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
              locale: const Locale('el', 'GR'),
            );
            if (pickedDate != null) {
              onNewDatePicked!(
                Date.fromDateTime(pickedDate),
              );
            }
          }
        : null;
  }
}
