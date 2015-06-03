Template.paymentSubmitModal.events = {
	"click .close-modal": (event) ->
		event.preventDefault()
		$("#paymentSubmitModal").modal("hide")
}

Template.paymentsList.events = {
	"change .date-picker": (event) ->
		event.preventDefault()
		selectedWeekNumber.set($(event.target).val())
		
	"click .delete-payment": (event) ->
		event.preventDefault()
		if confirm("Are you sure you want to remove #{@_id}")
			console?.log "Deleting", @
			Payments.remove(@._id)
		
}

Template.paymentsList.helpers({
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
		
	payments: () ->
		nextWeekNumber = parseInt(selectedWeekNumber.get()) + 1
		return Payments.find({paymentDate: {$gt: moment(selectedWeekNumber.get(), 'w').toDate(), $lt: moment(nextWeekNumber, 'w').toDate()}}, {sort: {paymentDate: -1}})
})

Template.paymentItem.helpers({
	
	invoiceNumber: ->
		Invoices.findOne({_id: @.paymentInvoiceId}, (error, invoice) ->
			if error
				console.log "error ", error
			else
				invoice.invoiceNumber
		)
})

Template.paymentSubmitModal.helpers({
	
	invoices: ->
		options = []
		Invoices.find({}, {sort: {invoiceDate: -1}}).forEach((invoice) ->
			options.push(
				label: invoice.invoiceNumber
				value: invoice._id
			)
		)
		options
})

AutoForm.hooks(
	paymentSubmitModalForm:
		onError: (type, error) ->
			console?.log error
		onSuccess: (operation, result, template) ->
			console.log operation, result, template
			$("#paymentSubmitModal").modal("hide")
			
	paymentEditForm:
		onError: (type, error) ->
			console?.log error
		onSuccess: (operation, result, template) ->
			console.log result
			Router.go("paymentsList")
)


