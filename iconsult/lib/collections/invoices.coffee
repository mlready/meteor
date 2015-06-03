@Invoices = new Mongo.Collection('invoices')

@Invoices.attachSchema(new SimpleSchema({
	invoiceDate:
		type: Date
		defaultValue: new Date()
	startingBalance:
		type: Number
	invoiceNumber:
		type: Number
	endingBalance:
		type: Number
	week:
		type: Number
	client:
		type: SimpleSchema.RegEx.Id
	dates:
		type: Schemas.DateSchema

}))

@Invoices.allow({
	insert: (userId, doc) ->
		return true
	update: (userId, doc) ->
		return true
	remove: (userId, doc) ->
		return true
})
