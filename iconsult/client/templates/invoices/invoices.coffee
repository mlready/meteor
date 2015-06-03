startingBalanceAmount = new Utilities.ReactiveDependency()
endingBalanceAmount = new Utilities.ReactiveDependency()
selectedPrintInvoice = new Utilities.ReactiveDependency()


Template.invoiceSubmitModal.events = {
	"click .close-modal": (event) ->
		event.preventDefault()
		$("#invoiceSubmitModal").modal("hide")
		
	"change .customer": (event) ->
		event.preventDefault()
		selectedClientId.set($(event.target).val())
		updateEndingBalance()
		
	"change .week-number": (event) ->
		event.preventDefault()
		selectedWeekNumber.set($(event.target).val())
		updateEndingBalance()
		
	"change .starting-balance": (event) ->
		event.preventDefault()
		startingBalanceAmount.set(parseInt($(event.target).val()))
		updateEndingBalance()
}

updateEndingBalance = ->
	startingBalanceAmount.set(0)
	lastInvoice = Invoices.find({week: selectedWeekNumber.get() - 1},{sort: {week: -1}, limit: 1}).forEach((invoice) ->
		startingBalanceAmount.set(invoice.endingBalance)
	)
	
	if !selectedClientId.get()?
		endingBalanceAmount.set(0)
	else
		startingBalance = startingBalanceAmount.get()
		client = Clients.findOne(selectedClientId.get())
	
		totalActivities = 0
		totalPayments = 0
		Payments.find({paymentDate: {$gt: moment(selectedWeekNumber.get(), 'w').toDate()}}).forEach((payment)->
			totalPayments += payment.amount
		)
		Activities.find({activityDate: {$gt: moment(selectedWeekNumber.get(), 'w').toDate()}}).forEach((activity) ->
			totalActivityAmount = activity.hours * client.billRate
			totalActivities += totalActivityAmount
		)
		endingBalance = startingBalance + totalActivities - totalPayments
		endingBalanceAmount.set(endingBalance)

Template.invoicesList.events = {
	
	"click .delete-invoice": (event) ->
		event.preventDefault()
		if confirm("Are you sure you want to remove #{@_id}")
			console?.log "Deleting", @
			Invoices.remove(@._id)
			
	"click .print-invoice": (event) ->
		event.preventDefault()
		invoice = Invoices.findOne(@._id)
		selectedPrintInvoice.set(invoice)
		$("#invoicePrintModal").modal("show")
}

Template.invoicesList.helpers({
	
	clients: ->
		options = []
		Clients.find({}, {sort: {name: 1}}).forEach((client) ->
			options.push(
				id: client._id
				name: client.name
			)
		)
		options
		
	currentWeek: ->
		selectedWeekNumber.get()
		
	isCurrentWeek: (weekNumber) ->
		weekNumber == selectedWeekNumber.get()
		
	invoices: () ->
		Invoices.find({client: selectedClientId.get()}, {sort: {invoiceDate: -1}})
})

Template.invoiceItem.helpers({
	
	totalActivities: ->
		totalActivityAmount = 0
		billRate = Clients.findOne(@.client).billRate
		Activities.find({invoiceId: @._id}).forEach((activity) ->
			activityHours = activity.hours
			totalActivityAmount += billRate * activityHours	
		)
		totalActivityAmount
		
	totalPayments: ->
		totalPaymentAmount = 0
		Payments.find({printInvoiceId: @._id}).forEach((payment) ->
			totalPaymentAmount += payment.amount
		)
		totalPaymentAmount
		
})

Template.invoicePrintModal.events = {
			
	"click .print-invoice": (event) ->
		$("#invoicePrintModal").modal("hide")
		newTab = window.open(event.target.href)
		newTab.focus()
		
	"click .close-modal": (event) ->
		event.preventDefault()
		$("#invoicePrintModal").modal("hide")
}

Template.printInvoicePrintPage.rendered = ->
	afterPrint = ->
		window.close()
		Router.go('/invoices')
		$(".modal-backdrop").remove()
		
	Q(window.print()).then(afterPrint)

Template.printInvoiceContent.helpers({
	getInvoiceDateRange: ->
		moment(selectedWeekNumber.get(), 'w').format("MM/DD/YYYY") + " - " + moment(selectedWeekNumber.get(), 'w').add(7, 'days').format("MM/DD/YYYY")
	
	invoiceWeek: ->
		selectedPrintInvoice.get()?.week
	
	activityItems: ->
		Activities.find({invoiceId: selectedPrintInvoice.get()?._id}, {sort: {activityDate: 1}})
		
	paymentItems: ->
		Payments.find({printInvoiceId: selectedPrintInvoice.get()?._id}, {sort: {paymentDate: 1}})
		
	endingBalance: ->
		selectedPrintInvoice.get()?.endingBalance	
		
	startingBalance: ->
		selectedPrintInvoice.get()?.startingBalance
		
	invoiceNumber: ->
		selectedPrintInvoice.get()?.invoiceNumber
	
	client: ->
		client = Clients.findOne(selectedPrintInvoice.get()?.client)
		client
	
	totalActivitiesAmount: ->
		totalActivityAmount = 0
		client = Clients.findOne(selectedPrintInvoice.get()?.client)
		billRate = client?.billRate
		Activities.find({invoiceId: selectedPrintInvoice.get()?._id}).forEach((activity) ->
			activityHours = activity.hours
			totalActivityAmount += billRate * activityHours
		)
		totalActivityAmount
		
		
	totalPaymentsAmount: ->
		totalPaymentAmount = 0
		Payments.find({invoiceId: selectedPrintInvoice.get()?._id}).forEach((payment) ->
			totalPaymentAmount += payment.amount
		)
		totalPaymentAmount
		
})

Template.printInvoiceActivityItem.helpers({
	
	billRate: ->
		client = Clients.findOne(selectedPrintInvoice.get().client)
		client?.billRate
		
	activityTotal: ->
		client = Clients.findOne(selectedPrintInvoice.get().client)
		@.hours * client?.billRate

})

Template.invoiceSubmitModal.helpers({
	
	getWeek: ->
		updateEndingBalance()
		selectedWeekNumber.get()
			
	activities: ->
		options = []
		Activities.find({activityDate: {$gt: moment(selectedWeekNumber.get(), 'w').toDate(), $lt: moment(selectedWeekNumber.get(), 'w').add(7, 'days').toDate()}}).forEach((activity) ->
			options.push({value: activity._id, label: activity.activityDate})	
		)
		options
		
	selectedActivities: ->
		options = []
		Activities.find({activityDate: {$gt: moment(selectedWeekNumber.get(), 'w').toDate(), $lt: moment(selectedWeekNumber.get(), 'w').add(7, 'days').toDate()}}).forEach((activity) ->
			options.push(activity._id)	
		)
		options
		
	activityItems: ->
		Activities.find({activityDate: {$gt: moment(selectedWeekNumber.get(), 'w').toDate(), $lt: moment(selectedWeekNumber.get(), 'w').add(7, 'days').toDate()}}, {sort: {activityDate: 1}})
		
	paymentItems: ->
		Payments.find({paymentDate: {$gt: moment(selectedWeekNumber.get(), 'w').toDate(), $lt: moment(selectedWeekNumber.get(), 'w').add(7, 'days').toDate()}}, {sort: {paymentDate: 1}})
		
	payments: ->
		options = []
		Payments.find({paymentDate: {$gt: moment(selectedWeekNumber.get(), 'w').toDate(), $lt: moment(selectedWeekNumber.get(), 'w').add(7, 'days').toDate()}}).forEach((payment) ->
			options.push({value: payment._id, label: payment.paymentDate})	
		)
		options
		
	selectedPayments: ->
		options = []
		Payments.find({paymentDate: {$gt: moment(selectedWeekNumber.get(), 'w').toDate(), $lt: moment(selectedWeekNumber.get(), 'w').add(7, 'days').toDate()}}).forEach((payment) ->
			options.push(payment._id)	
		)
		options

		
	endingBalance: ->
		endingBalanceAmount.get()		
		
	weeks: ->
		weekNumber = moment().format('w')
		weekOptions = []
		for i in [weekNumber..1]
			weekOptions.push({value: i, label: 'Week ' + i})
		weekOptions
		
	startingBalance: ->
		startingBalanceAmount.get()
		
	nextInvoiceNumber: ->
		lastInvoiceNumber = 0
		Invoices.find({week: selectedWeekNumber.get() - 1},{limit: 1}).forEach((invoice) ->
			lastInvoiceNumber = invoice.invoiceNumber + 1	
		)
		lastInvoiceNumber
	
	selectedClient: ->
		selectedClientId.get()
		
	clients: ->
		options = []
		Clients.find({endDate: null}).forEach((client) ->
			options.push({value: client._id, label: client.name})
		)
		selectedClientId.set(options[0]?.value)
		options
})

AutoForm.hooks(
	invoiceSubmitModalForm:
		onError: (type, error) ->
			console?.log "error ", error
		onSuccess: (operation, invoiceId, template) ->
			Activities.find({activityDate: {$gt: moment(selectedWeekNumber.get(), 'w').toDate(), $lt: moment(selectedWeekNumber.get(), 'w').add(7, 'days').toDate()}}).forEach((activity) ->
				console.log activity
				Activities.update({_id: activity._id},
					$set:
						invoiceId: invoiceId
				)
			)
			Payments.find({paymentDate: {$gt: moment(selectedWeekNumber.get(), 'w').toDate(), $lt: moment(selectedWeekNumber.get(), 'w').add(7, 'days').toDate()}}).forEach((payment) ->
				Payments.update({_id: payment._id},
					$set:
						printInvoiceId: invoiceId
				)
			)
			$("#invoiceSubmitModal").modal("hide")
			Router.go('invoicesList')
)


