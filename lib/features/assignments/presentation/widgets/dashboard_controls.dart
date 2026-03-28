// import 'package:flutter/material.dart';
//
// class DashboardControls extends StatelessWidget {
//   final List<String> warnings;
//   final VoidCallback? onPrintFree;
//   final VoidCallback? onAutoFill;
//
//   const DashboardControls({
//     super.key,
//     this.warnings = const [],
//     this.onPrintFree,
//     this.onAutoFill,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         // 1. Warnings
//         if (warnings.isNotEmpty)
//           Container(
//             color: Colors.red.shade50,
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(children: [
//                   Icon(Icons.warning_amber_rounded,
//                       color: Colors.red.shade700, size: 20,),
//                   const SizedBox(width: 8),
//                   Text('Detected Conflicts (${warnings.length})',
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.red.shade900,
//                           fontSize: 13,),),
//                 ],),
//                 ...warnings.map((w) => Padding(
//                       padding: const EdgeInsets.only(left: 28.0, top: 4),
//                       child: Text('• $w',
//                           style: TextStyle(
//                               color: Colors.red.shade800, fontSize: 12,),),
//                     ),),
//               ],
//             ),
//           ),
//
//         // 2. Toolbar
//         Container(
//           color: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 _ActionButton(Icons.print, 'Print Eksodouxoi', Colors.blueGrey,
//                     onPrintFree,),
//                 const SizedBox(width: 8),
//                 const _ActionButton(Icons.people_outline, 'Check Availability',
//                     Colors.teal, null,),
//                 const SizedBox(width: 8),
//                 _ActionButton(Icons.auto_fix_high, 'Auto-Fill Empty',
//                     Colors.orange, onAutoFill,),
//               ],
//             ),
//           ),
//         ),
//         const Divider(height: 1, thickness: 1),
//       ],
//     );
//   }
// }
//
// class _ActionButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback? onTap;
//
//   const _ActionButton(this.icon, this.label, this.color, this.onTap);
//
//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton.icon(
//       onPressed: onTap,
//       icon: Icon(icon, size: 16),
//       label: Text(label,
//           style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.white,
//         foregroundColor: color,
//         elevation: 0,
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         side: BorderSide(color: color.withOpacity(0.3)),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       ),
//     );
//   }
// }
