class Utilities.ReactiveDependency
	constructor: (initialValue) ->
		@dependency = new Deps.Dependency
		@value = initialValue
	
	set: (value) =>
		@value = value
		@dependency.changed()
		return
	
	get: =>
		@dependency.depend()
		return @value
	
@selectedWeekNumber = new Utilities.ReactiveDependency(moment().format('w'))
@selectedClientId = new Utilities.ReactiveDependency()
