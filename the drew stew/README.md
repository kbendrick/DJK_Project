# The Drew Stew Prototype

Open `drew_stew.tscn` and run the current scene with F6.

The prototype intentionally uses one scene and one script. No external visual assets are required.

## Inspector settings

- `valid_words`: Add any uppercase five-letter words that the rows should recognize.
- `seconds_per_step`: Controls how often the columns rotate. The default is 0.5 seconds.

## Data layout

`letter_columns` contains five arrays. Each array contains ten randomly generated letters. The grid displays five consecutive values from each array, based on that column's offset.

- Columns 1, 3, and 5 subtract one from their offsets, making their displayed letters move down.
- Columns 2 and 4 add one to their offsets, making their displayed letters move up.
- `wrapi()` keeps each offset between 0 and 9, producing continuous rotation.

After every movement, the script reads each visible row from left to right and compares the resulting five-letter string against `valid_words`. Matching rows are tinted green.
