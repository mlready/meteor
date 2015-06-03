Router.route('/invoices',
	name: 'invoicesList'
)

Router.route('/invoices/:_id', {
	name: 'invoicePage'
	data: ->
		invoice = Invoices.findOne(@params._id)
		return {invoice}
})

Router.route( '/print-invoice'
	name: 'printInvoicePrintPage'
	title: "MReadyLLC IConsult"
	layoutTemplate: "print"
)


