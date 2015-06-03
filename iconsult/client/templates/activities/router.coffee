Router.route('/activities/:_id', {
	name: 'activityPage'
				
	data: ->
		activity = Activities.findOne(@params._id)
		return {activity}
})

