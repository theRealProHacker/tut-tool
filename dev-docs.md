# Developer Dokumentation

> Note: You can build nice formatted documentation with `dart format .`.

But this gives a more over-all understanding of the project. 


## I/O

What IO is done?

1. shared_preferences: Saves paths to projects globally in `%AppData%`
2. Reading submissions: For the auto grouping feature and to display them. Importantly, we must never write to submissions!
3. Reading/Writing to `comments.txt`. When you enter a `GroupPage`, comments are loaded from a random group member (the tool assumes there is no manual editing of comments files) and then saved, when leaving the group page. There is no warranty that it will be saved, if you just exit the app. However, this leads me to the conclusion that we should add a save button to the app bar actions.
4. Reading/Writing to `grades.csv`. When you "submit" the project, the grades are entered for all groups and all students. This involves reading and writing to the csv file. This is probably the only dangerous part, especially because we implement the parsing and serializing ourselves and during testing I have had empty csv-files. I assume this happens when the app crashes while writing to the file. 