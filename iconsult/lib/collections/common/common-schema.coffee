@Schemas = {}

@Schemas.DateSchema = new SimpleSchema(
	createdAt:
		type: Date
		autoValue: ->
			if @isInsert
				return new Date()
			else if @isUpsert
				return $setOnInsert: new Date()
			else
				@unset()
	updatedAt:
		type: Date
		autoValue: ->
			if @isUpdate
				return new Date()
		denyInsert: true
		optional: true
)

@Schemas.Address = new SimpleSchema(
	street:
		type: String
		optional: true
	city:
		type: String
		optional: true
	state:
		type: String
		optional: true
	zip:
		type: String
		optional: true
	country:
		type: String
		optional: true	
)