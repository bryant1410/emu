Emu.Store = Ember.Object.extend
	init: ->		
		@set("modelCollections", {}) if @get("modelCollections") == undefined
		@_adapter = @get("adapter")?.create() || Emu.RestAdapter.create()
	createRecord: (type) ->
		collection = @_getCollectionForType(type)
		collection.createRecord(isDirty: true)
	findAll: (type, options) ->
		collection = options?.collection or @_getCollectionForType(type)
		if collection.get("isLoading") or collection.get("isLoaded")
			return collection
		collection.set("isLoading", true)
		@_adapter.findAll(type, this, collection, options)
		collection	
	save: (model) ->
		if model.get("id") then @_adapter.update(this, model) else @_adapter.insert(this, model)
	didFindAll: (collection, options) ->
		collection.set("isLoaded", true)
		collection.set("isLoading", false)
		collection.get("content").forEach (item) -> item.set("isLoaded", options?.fullyLoad)
	findById: (type, id) ->
		collection = @_getCollectionForType(type)
		model = collection.find (item) -> item.get("id") == id
		if not model
			model = collection.createRecord(id: id, isLoading: true, isLoaded: false)			
			@_adapter.findById(type, this, model, 5)
		model
	didFindById: (model) ->
		model.set("isLoading", false)
		model.set("isLoaded", true)
		model.set("isFullyLoaded", true)
	_getCollectionForType: (type) ->
		@get("modelCollections")[type] || @get("modelCollections")[type] = Emu.ModelCollection.create(type: type, store: this)