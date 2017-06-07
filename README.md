# snippets
This is a repo dedicated to snippets of code created to help with miscellaneous things.

## chiliproject_migrate.rb
This script is used for exporting everything related to a chiliproject project.

To use this you first must obtain the project id of the project you are trying to migrate.
The project id in the script must be replaced with the project id of the project you intend to export.
This script creates the files in a directory specified by `$dump_dir` at the top of the script.
Be sure to create this directory before running the script.

Then, run `./script/console production` in the chiliproject directory to start the Ruby REPL with production settings loaded.

Make sure that the second line of the script actually finds the project.
If it doesn't find the project it will output an error to the screen.
To make sure that it found the right project, just run ``print ${project_object}.name``.
If that fails and you can't find the project at all, make sure to check the settings in `chiliproject/config/database.yml`.

If these settings are correct, then make sure your version of Ruby is correct and that you are using the correct Gems.
[RVM](https://rvm.io/rvm/install) is a great tool fror managing Ruby versions.

So you have managed to find your project through the REPL! Now you just paste the script right into the command line.
This will export all models related to the project into json fixtures. Sure it isn't pretty, but it works!

To change the file extension of the fixture files, change the `$fileext` variable.
To change the format that it exports into, change the `$encoder` variable.
Make sure the encoder you give it exists. i.e. to export into yml, change `$encoder` to equal `to_yaml`.
