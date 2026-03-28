# Military Duty Scheduler

A Flutter desktop application for automating the creation of the daily schedule of the military
company that I served in. It provides an interface for scheduling soldiers to various posts and
duties, while enforcing rules and constraints.

## Context

In my mandatory service one of my responsibilities was creating the daily schedule for the company.
This was a
repetitive and standardized task, and it was done manually using Excel, which was time-consuming and
prone to human error.
So I decided to create this app to automate part of the process, reduce humman errors, and save time, while
still being backward-compatible with the existing Excel-based workflow.

## Features

- **Daily scheduling** — assign soldiers to guard posts (Σκοποί), dorm guards (Θαλαμοφύλακες), ΓΕΠ,
  kitchen, and all other daily duties
- **Warnings** — validation rules that flag scheduling conflicts (e.g. back-to-back 4-hour shifts,
  flag ceremony overlaps, cleaning duty restrictions)
- **Excel import/export** — reads the master duty roster from `.xlsx`, writes assignments back to
  it, and exports formatted daily sheets (`ΥΠΗΡΕΣΙΕΣ`, `ΚΑΤΑΣΤΑΣΗ`, `ΟΑΑ-ΤΑΕ`, exit passes)
- **Persistent storage** — saves per-month data in `YY_MM/excel.xlsx` + `tasks.json` under the app
  documents directory; automatically loads the latest save on startup

## Asset requirements

The app expects the following sheets in `assets/excel.xlsx`:

| Sheet                                           | Purpose                                   |
|-------------------------------------------------|-------------------------------------------|
| `ΜΑΡ26`, `ΑΠΡ26`, …                             | Monthly duty roster (one sheet per month) |
| `ΓΕΠ`, `ΜΑΓΕΙΡΑΣ`, `ΕΑΣ`, `ΑΥΔΜ ΛΣ`, `ΑΥΔΜ ΛΣΝ` | Officer rotation sheets                   |
| `ΗΣΑ1`, `ΗΣΑ2`, `ΗΣΑ3`, `ΑΡΧΙΦΥΛΑΚΑΣ`           | CCTV / gate guard rotation sheets         |
| `ΔΝ`                                            | Home-sleeper (ΔΝ) soldier list            |
| `ΑΡΓΙΕΣ`                                        | Public holiday dates                      |
| `ΠΡΑΤΗΡΙΟ`                                      | Military market closed dates              |

A `assets/template.xlsx` is also required for the export feature — it contains the pre-formatted
print templates (`ΥΠΗΡΕΣΙΕΣ`, `ΕΞΟΔΟΧΑΡΤΑ`, `ΔΝ`, `ΟΑΑ-ΤΑΕ`, `ΚΑΤΑΣΤΑΣΗ`).

## Data persistence

On every save, the app writes two files to the application documents directory:

```
<AppName>/
└── YY_MM/              ← e.g. 26_03 for March 2026
    ├── excel.xlsx      ← updated duty roster
    └── tasks.json      ← OtherTasks assignments (reserves, cleaning, flags, …)
```

On next launch the app automatically picks up the most recent `YY_MM` folder.
