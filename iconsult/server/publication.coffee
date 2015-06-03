Meteor.publish('activities', ->
	return Activities.find()	
)
Meteor.publish('clients', ->
	return Clients.find()
)
Meteor.publish('payments', ->
	return Payments.find()
)
Meteor.publish('invoices', ->
	return Invoices.find()
)