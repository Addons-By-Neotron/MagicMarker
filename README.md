# MagicMarker

**Your best friend for raid marking**

**Author:** David Hedbor <neotron@gmail.com>
**Supported Versions:** All classic WoW iterations. Retail not supported as of Midnight.

---

## Description

MagicMarker lets you easily classify and mark mobs simply by moving the mouse over them. This allows incredibly fast marking of trash groups. Although not necessary for the addon to function, you can configure the priority and crowd control methods you wish to use on a per mob basis. You can also customize the marks to use for tank targets and each crowd control method.

This allows for consistent marking of targets to tank and crowd control.

## Todo

No further plans of development. 

## Contact

For suggestions and bug reports: https://github.com/Addons-By-Neotron/MagicMarker/issues

---

## Usage

First bind keys to the three addon functions in the normal key binding UI. To mark a target, hold in the ALT button while mousing over it. New mobs will automatically be added to the configuration UI. You open the config UI with the `/magic` command or via the `/ace3` command.

These are the functions:

- **Reset raid targets:** Clears the list of recorded markings, and resets all raid targets.
- **Mark selected target:** Mark a single target using the normal rules.
- **Unmark selected target:** Unmark your target and remove from the list of marks.

---

## Raid Target Prioritization

- The priority (high, medium, low) is the primary weight.
- A mob of category Tank weighs higher than an equal priority target in the Crowd Control category.
- For crowd control targets, the targets for each specified CC method will be iterated in order.
- If no CC method target was available, the tank list will be used.
- **IT IS ESSENTIAL THAT THE TANK LIST INCLUDES ALL TARGET ICONS IN YOUR PREFERRED ORDER OR THE ADDON WILL BE UNABLE TO USE ALL 8 TARGETS.**