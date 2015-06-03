Router.route('/payments/:_id', {
	name: 'paymentPage'
	waitOn: ->
			return Meteor.subscribe('payments')
	data: ->
		payment = Payments.findOne(@params._id)
		console.log "selected payment ", payment
		return {payment}
})

Router.route('/payments',
	name: 'paymentsList'
	waitOn: ->
			return Meteor.subscribe('payments')
)
