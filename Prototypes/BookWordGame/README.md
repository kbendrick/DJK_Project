# Book Word Game Prototype

This folder is self-contained. It does not replace the project's main scene or modify any pre-existing scripts.

## Run it

Open `book_word_game.tscn` in Godot and use **Run Current Scene** (F6). The scene begins with a three-frame `AnimatedSprite2D` book-opening placeholder, then reveals the playable two-page interface.

## Current rules

- The page is an 8×8 nested array of uppercase letters.
- The three default targets are `BOOK`, `MIND`, and `PAGE`.
- Words count left-to-right or top-to-bottom.
- The player receives 3 action points each turn.
- Substitution: 2 AP, 1 Savvy, 1 Insight. Replaces a letter randomly.
- Deletion: 1 AP, 1 Insight. Removes a letter, shifts later letters toward index 0, and adds a random final letter.
- Transposition: 2 AP, 1 Savvy. Swaps two orthogonally adjacent letters.
- Insertion: 1 AP, 2 Savvy, 2 Insight. Opens a mouse-only A–Z picker, inserts the chosen letter, shifts later letters toward index 63, and discards the final letter.
- The turn ends automatically at 0 AP or manually with **End Turn**.
- The default book condition forbids horizontally or vertically adjacent vowels.
- If the condition has at least one match at the beginning of the book turn, the player loses 1 Savvy. The affected resource and amount are exported properties on the rule.
- The book performs two actions per turn from an editable action cycle to create more adjacent-vowel matches.
- Completing all three words grants 25 gold, optionally saves a copy of the nested page array, and offers one of three upgrades.

All starting totals, target words, rewards, and the active rule are exported on the scene root.

## Add a different book rule

1. Create a script extending `BookRule`.
2. Implement `count_matches(model)` and `take_book_turn(model, rng)`.
3. Create a `.tres` resource that uses the new script.
4. Assign that resource to `book_rule` on the scene root.

`AdjacentVowelsRule` is the working example. Each encounter can point to a different rule resource, so rules do not need to be added to the controller.

## Add another player ability

1. Create a script extending `BookAbility`.
2. Set its display name, description, AP/Savvy/Insight costs, target count, and whether it needs the letter picker.
3. Implement `apply(model, targets, letter_choice, rng)`.
4. Create a resource using that script and add it to the root's `extra_abilities` array.

The right page creates its buttons from the ability array at runtime. No interface edit is required for additional abilities.

## Replace the placeholder book art

Replace the textures in the `BookOpening` node's `SpriteFrames` resource. The gameplay interface appears when the `open` animation finishes, so the animation may contain any number of frames.
