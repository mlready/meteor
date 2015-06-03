Meteor.startup(->
	currentClient = Clients.findOne({name: "Practichem"})
	selectedClientId.set(currentClient._id)
)
	