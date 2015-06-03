@Activities = new Mongo.Collection('activities')

@Activities.attachSchema(new SimpleSchema({
	activityDate:
		type: Date
	hours:
		type: Number
		defaultValue: 8
	description:
		type: String
		autoform:
			rows: 5
	invoiceId:
		type: SimpleSchema.RegEx.Id
		optional: true
	isInOffice:
		type: Boolean
		label: "At the client site?"
		defaultValue: true
	clientId:
		type: SimpleSchema.RegEx.Id
	dates:
		type: Schemas.DateSchema

}))

@Activities.allow({
	insert: (userId, doc) ->
		return true
	update: (userId, doc) ->
		return true
	remove: (userId, doc) ->
		return true
})
