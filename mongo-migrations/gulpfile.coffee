try
	gulp = require('gulp')
	glob             = require("glob")
	removeRecursively= require("rimraf")
	{
		util                  # Gulp utilities
		rename                # Rename jade to html
		print                 # Pipe to it to log out all filenames passing through, useful for debugging
		plumber               # Insert before coffee and other plugins that can fail, so that further compilation isn't halted
		coffee                # Compile coffeescript
		template              # Arbitrary interpolation in a file (used to loop over less files to include)
		less                  # Compile less
		jade                  # Compile jade
		concat                # Concatenate files
	} = require('gulp-load-plugins')()
catch error
	console.log(error)
	console.log("""

		Looks like theres been some updates!  Run this and try again:

		    npm install

	""")
	process.exit(1)

state = {
	# Should coffeescript files use sourcemaps
	useSourceMaps: false
	# Is this gulp process still in its early phase of booting up.
	# We don't honor shouldReload or exitOnChange until after a timeout
	isBootedUp: false
}

paths =
	# Scripts that have to come first when concatenating.  Over time this should shrink
	"coffee-migrations" : "scripts/**/*.coffee"
	"migrations-assets" : "assets/**/*.{txt,xml,json}"

	"build.coffee-migrations"	: "migrations"

	"gulpconfig"			: ["./gulpfile.coffee", "./package.json"]
	
{log} = util
{red, green} = util.colors
task = gulp.task.bind(gulp)

getPath = (pathId) ->
	paths[pathId] ? throw Error("\nNo path with id `#{pathId}`")

src = (pathId) ->
	gulp.src(getPath(pathId))

dest = (pathId) ->
	gulp.dest(getPath(pathId))

watch = (pathId, tasks) ->
	gulp.watch(getPath(pathId), tasks)

removeAll = (pathId) ->
	console.log "Removing: ", getPath(pathId)
	allPaths = glob.sync(getPath(pathId))
	for path in allPaths
		removeRecursively.sync(path)

# Adds an error handler to the given stream
logErrors = (stream) ->
	stream.on( 'error', (error) ->
		log(red("ERROR: #{error}"))
	)

compileCoffee = ->
	logErrors(coffee(sourceMap: state.useSourceMaps))

updateCoffeeMigrationPath = (path) ->
	if path.dirname.indexOf('version-') == 0
		path.dirname = ""
	return

task "scripts-migrations", ->
	removeAll("build.coffee-migrations")
	src("coffee-migrations")
		.pipe(plumber())
		.pipe(compileCoffee())
		.pipe(rename(updateCoffeeMigrationPath))
		.pipe(dest("build.coffee-migrations"))

task 'build', ['scripts-migrations']
	
task 'watch', ->
	watch('coffee-migrations', ['scripts-migrations'])
	watch('migrations-assets', ['scripts-migrations'])
	setTimeout(->
		log("watching config files")
		watch('gulpconfig', ['exit-gulp'])
	, 6 * 1000)

task 'exit-gulp', () ->
	src('gulpconfig').pipe(print())
	log 'exit'
	return unless state.isBootedUp
	log(red("The gulpfile has changed, exiting!  You'll have to re-run `gulp`"))
	process.exit(1)

# Remove all files in build
task 'clean', ->
	removeAll("build.coffee-migrations")
	
task 'development', ->
	setTimeout(->
		log "done booting up"
		state.isBootedUp = true
	, 6 * 1000)

	gulp.start(
		'clean'
		'build'
		'watch'
	)

task 'default', ['development']