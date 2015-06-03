Router.configure({
	layoutTemplate: 'layout'
	loadingTemplate: 'loading'
	notFoundTemplate: 'notFound'
	waitOn: ->
		return [
			Meteor.subscribe('activities')
			Meteor.subscribe('clients')
			Meteor.subscribe('payments')
			Meteor.subscribe('invoices')
		]
})

Router.route('/', {name: 'activitiesList'})








