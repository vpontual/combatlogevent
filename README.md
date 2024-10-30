# Combat Log Event Counter WoW Addon

## Description

Combat Log Event Counter (CLE) is a lightweight World of Warcraft addon that tracks various game messages and events. Initially created to count "out of range" messages during gameplay, it has been designed to be easily expandable for tracking additional message types and combat log events.

Currently tracks:

- Out of range messages
- Line of sight issues
- Distance-related errors
- Spell interrupts (including Counterspell)
- Spell cast failures

## Features

- Counts different types of range/distance related messages and combat log events
- Configurable thresholds for notifications
- Persistent counting between sessions
- Easy to expand for additional message types
- Simple slash commands for interaction
- Debug mode for detailed logging

## Installation

1. Download the addon
2. Extract the folder into your WoW addons directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\
   ```
3. Make sure the folder is named "CombatLogEvent"
4. The folder should contain:
   - combatlogevent.lua
   - CombatLogEvent.toc

## Usage

The addon responds to the following slash commands:

- `/cle` - Shows current counts for all tracked message types
- `/cle reset` - Resets all counters to zero
- `/cle debug` - Toggles debug mode for more detailed logging

## Configuration

Current thresholds and settings can be adjusted by modifying the values in the `addon.messageTypes` table in `combatlogevent.lua`.

## Expanding the Addon

The addon is designed to be easily expandable. Instructions for adding new message types are provided in the README.

## File Structure

- `CombatLogEvent.toc` - Addon manifest file
- `combatlogevent.lua` - Main addon code
- `README.md` - This documentation file

## Saved Variables

The addon uses the following saved variables structure:

```lua
ConditionCounterDB = {
    conditionTypes = {},
    settings = {
        enableSound = true,
        enableWarnings = true,
    }
}
```

## Future Enhancements

Planned improvements:

- [ ] Configuration panel for settings
- [ ] More detailed event logging
- [ ] Export/import of statistics
- [ ] Visual displays for tracked events
- [ ] Integration with other addons
- [ ] Additional combat log event tracking options

## Version History

- 1.0.0: Initial release
  - Basic range message tracking
  - Combat log framework with interrupt and failure tracking
  - Basic slash commands
  - Persistent storage of counters
  - Threshold notifications
- 1.0.1: Bugfix update
  - Fixed an issue with saved variables initialization
  - Added support for spell cast failure events

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License

Copyright (c) 2024 VeePee

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Credits

Created by VeePee
