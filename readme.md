Emu
===

Emu is a simple data access framework for Ember.js.

How to use it
-------------

	// you need a store
	App.store = Emu.Store.create();

	// lets define some models
	App.Person = Emu.Model.extend({
		name: Emu.field("string")		
	});

	App.Club = Emu.Model.extend({
		name: Emu.field("string"),
		boardMembers: Emu.field(App.Person, {collection: true}),
		members: Emu.field(App.Person, {collection: true, lazy: true})
	});
	.
	.
	.
	//get a model
	var club = App.store.getById(App.Club, 5);  
		//GET request to: 	http://www.megaclubs.crazy/club/5
		//Response: {name: "Computer club", boardMembers: [{name: "Bernard"}, {name: "Cuthbert"}]}
	.
	.
	.
	//Get a lazy property
	var members = club.get("members") 
		//GET request to:	http://www.megaclubs.crazy/club/5/members
		//Response: [{name: "Tom"}, {name: "Barny"}]
	.
	.
	.
	//Save the model
	App.store.save(club)
		//PUT request to:	http://www.megaclubs.crazy/club/5
