modalFormAction = new Utilities.ReactiveDependency()
selectedClientId = new Utilities.ReactiveDependency()

Template.clientSubmitModal.events = {
	"click .close-modal": (event) ->
		event.preventDefault()
		selectedClientId.set(null)
		$("#clientSubmitModal").modal("hide")
}

Template.clientsList.events = {
	
	'click .new-client': (event) ->
		event.preventDefault()
		modalFormAction.set("insert")
		selectedClientId.set(null)
		$("#clientSubmitModal").modal("show")
}

Template.clientItem.events = {
	
	'click .edit-client': (event) ->
		event.preventDefault()
		modalFormAction.set("edit")
		selectedClientId.set(@._id)
		$("#clientSubmitModal").modal("show")
}

Template.clientsList.helpers({
	clients: () ->
		return Clients.find()
})

Template.clientItem.helpers({
	
	formatDate: (dateString) ->
		if dateString?
			return moment(dateString).format("YYYY-MM-DD")
})

Template.clientSubmitModal.helpers({
	
	formAction: ->
		modalFormAction.get()
		
	mode: ->
		if modalFormAction.get() == "insert"
			return "New"
		else
			return "Edit"
	
	client: ->
		if modalFormAction.get() == "edit"
			return Clients.findOne(selectedClientId.get())
		else
			return null
	isEditMode: ->
		modalFormAction.get() == "edit"
})

AutoForm.hooks(
	clientSubmitModalForm:
		onError: (type, error) ->
			console?.log error
		onSuccess: (operation, result, template) ->
			selectedClientId.set(null)
			$("#clientSubmitModal").modal("hide")
)


