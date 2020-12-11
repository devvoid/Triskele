# Triskele
An open-source dialog tree editor made with the Godot Engine.

## Usage
See [the user guide](USAGE.md)

## Todo
- Multiple language support. It's *almost* there, but just needs a bit more work before it's ready.
  - Adding languages will be done via the Edit menu button
  - A default, "primary" language will be defined, which determines what language is used as a fallback if an invalid language is requested, as well as what language will be used for the Dialog node previews.
- Further backup support. As of right now, backups are created and stored to `user://backups/*.bck`, but there isn't a method to restore said backups in the event of a crash. This will take more UI work than I can commit to right now; for now, just copy the backups by hand if necessary.
- Saving translations to a different folder than the main TRIS file. Godot generates a lot of additional files which can clutter up a folder if you save multiple dialog trees to one location (especially if the game supports multiple languages). Saving/loading can probably handle this as-is, determining the translation filepath just needs to be split into its own variable and given its own save dialog.
- Set `selected_node` to `null` when the user left-clicks on the graph. Not possible right now due to an engine bug; 

## License
This repository is available under the MIT License. See [LICENSE](LICENSE) for more information.

### Contributing
Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you shall be licensed as above, without any additional terms or conditions.
