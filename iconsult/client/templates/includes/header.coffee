Template.registerHelper("formatDate", (dateString) ->
	return moment.utc(new Date(dateString)).format("MM/DD/YYYY")							
)
Template.registerHelper("currentDate", (formatString) ->
	formatString ?= "YYYY-MM-DD"
	return moment().format(formatString)	
)
Template.registerHelper("formatCurrency", (amount) ->
	return numeral(amount).format("$0,0.00")	
)