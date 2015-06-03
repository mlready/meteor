@Clients = new Mongo.Collection('clients')

@Clients.attachSchema(new SimpleSchema({
	startDate:
		type: Date
	endDate:
		type: Date
		optional: true
		defaultValue: null
	billRate:
		type: Number
	name:
		type: String
	contactName:
		type: String
	address:
		type: Schemas.Address
	dates:
		type: Schemas.DateSchema
}))

@Clients.allow({
	insert: (userId, doc) ->
		return true
	update: (userId, doc) ->
		return true
})