@Payments = new Mongo.Collection('payments')

@Payments.attachSchema(new SimpleSchema({
	paymentDate:
		type: Date
	amount:
		type: Number
	paymentInvoiceId:
		type: SimpleSchema.RegEx.Id
	printInvoiceId:
		type: SimpleSchema.RegEx.Id
		optional: true
	dates:
		type: Schemas.DateSchema

}))

@Payments.allow({
	insert: (userId, doc) ->
		return true
	update: (userId, doc) ->
		return true
	remove: (userId, doc) ->
		return true
})
