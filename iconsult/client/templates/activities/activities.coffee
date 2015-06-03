Template.activitySubmitModal.events = {
	"click .close-modal": (event) ->
		event.preventDefault()
		$("#activitySubmitModal").modal("hide")
}

Template.activitiesList.events = {
		
	"change .date-picker": (event) ->
		event.preventDefault()
		selectedWeekNumber.set($(event.target).val())
		
	"click .delete-activity": (event) ->
		event.preventDefault()
		if confirm("Are you sure you want to remove #{@_id}")
			console?.log "Deleting", @
			Activities.remove(@._id)
		
}

Template.activitiesMenu.events = {
		"click .open-activity": (event) ->
			event.preventDefault()
			$("#activitySubmitModal").modal("show")
		
		"click .open-payment": (event) ->
			event.preventDefault()
			$("#paymentSubmitModal").modal("show")
		
		"click .open-invoice": (event) ->
			event.preventDefault()
			$("#invoiceSubmitModal").modal("show")
			
		"click .print-invoice": (event) ->
			event.preventDefault()
			$("#printSubmitModal").modal("show")
}

Template.activitiesList.helpers({
	weeks: ->
		weekNumber = moment().format('w')
		weekOptions = []
		for i in [weekNumber..1]
			weekOptions.push({value: i, label: 'Week ' + i})
		weekOptions
		
	currentWeek: ->
		selectedWeekNumber.get()
		
	isCurrentWeek: (weekNumber) ->
		weekNumber == selectedWeekNumber.get()
		
	activities: () ->
		nextWeekNumber = parseInt(selectedWeekNumber.get()) + 1
		return Activities.find({activityDate: {$gt: moment(selectedWeekNumber.get(), 'w').toDate(), $lt: moment(nextWeekNumber, 'w').toDate()}}, {sort: {activityDate: -1}})

})

Template.activityItem.helpers({
	
	clientName: ->
		Clients.findOne(@.clientId).name
})

Template.activitySubmitModal.helpers({
	
	clients: ->
		options = []
		Clients.find({}, {sort: {name: 1}}).forEach((client) ->
				options.push(
					label: client.name
					value: client._id
				)
			)
		options
})

AutoForm.hooks(
	activitySubmitModalForm:
		onError: (type, error) ->
			console?.log error
		onSuccess: (operation, result, template) ->
			console.log "success ", result
			$("#activitySubmitModal").modal("hide")
			
	activityEditForm:
		onError: (type, error) ->
			console?.log error
		onSuccess: (operation, result, template) ->
			Router.go("activitiesList")
)



