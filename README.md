# snippets
This is a repo dedicated to snippets of code created to help with miscellaneous things.

## chiliproject_migrate.rb
This script is used for exporting everything related to a chiliproject project.
To use this you first must from the project id of the project you are trying to migrate.
The project id in the script must be replaced with the project id of the project you intend to export.
This script creates the files in a directory specified by `$dump_dir` at the top of the script.
Be sure to create this directory before running the script.
Then, run `./script/console production` in the chiliproject root directory to gain access to the ORM console.
Once you have access, you paste the script in. Sure, it isn't pretty, but it works.
This will export all models related to the project into json fixtures.
`$fileext` is the file extensions appended to the file names.
`$encoder` is the function that is sent to the model to create the files.
To get yml formatting, set this variable to `to_yaml`.
