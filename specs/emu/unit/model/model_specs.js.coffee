describe "Emu.Model", ->
  Person = Emu.Model.extend
    name: Emu.field("string")
    address: Emu.field("App.Address")
    orders: Emu.field("App.Order", {collection:true})
    oldOrders: Emu.field("App.Order", {collection: true, paged: true})

  it "should have a flag to indicate the type is an Emu model", ->
    expect(Person.isEmuModel).toBeTruthy()

  describe "create", ->

    describe "no values", ->
      beforeEach ->
        @stateTracker = Emu.StateTracker.create()
        spyOn(@stateTracker, "track")
        spyOn(Emu.StateTracker, "create").andReturn(@stateTracker)
        @person = Person.create()

      it "should have hasValue false", ->
        expect(@person.get("hasValue")).toBeFalsy()

      it "should have isDirty true", ->
        expect(@person.get("isDirty")).toBeTruthy()

      it "should be tracked with a StateTracker", ->
        expect(@stateTracker.track).toHaveBeenCalledWith(@person)

    describe "multiple primary keys specified", ->
      beforeEach ->
        @Foo = Emu.Model.extend
          fooId: Emu.field("string", {primaryKey: true})
          barId: Emu.field("string", {primaryKey: true})
        try
          @foo = @Foo.create()
        catch exception
          @exception = exception

      it "should throw an exception", ->
        expect(@exception.message).toContain("You can only mark one field as a primary key")

  describe "primaryKey", ->

    describe "no primary key specified", ->
      beforeEach ->
        Foo = Emu.Model.extend()
        @foo = Foo.create(id:"10")

      it "should have primaryKey as 'id'", ->
        expect(@foo.primaryKey()).toEqual("id")

    describe "primary key specified", ->
      beforeEach ->
        Foo = Emu.Model.extend
          fooId: Emu.field("string", {primaryKey: true})
        @foo = Foo.create()

      it "should have primaryKey as 'fooId'", ->
        expect(@foo.primaryKey()).toEqual("fooId")

  describe "primaryKeyValue", ->

    describe "get", ->
      beforeEach ->
        Foo = Emu.Model.extend
          fooId: Emu.field("string", {primaryKey: true})
        @foo = Foo.create(fooId:"10")

      it "should have primaryKeyValue as '10'", ->
        expect(@foo.primaryKeyValue()).toEqual("10")

  describe "createRecord", ->
    beforeEach ->
        Ember.set(Emu, "defaultStore", undefined)
        @store = Emu.Store.create()
        spyOn(@store, "createRecord")
        @model = Person.createRecord()

      it "should proxy the call to the default store", ->
        expect(@store.createRecord).toHaveBeenCalledWith(Person)

  describe "find", ->
    beforeEach ->
      Ember.set(Emu, "defaultStore", undefined)
      @store = Emu.Store.create()
      spyOn(@store, "find")
      @model = Person.find(5)

    it "should proxy the call to the default store", ->
      expect(@store.find).toHaveBeenCalledWith(Person, 5)

  describe "findPaged", ->
    beforeEach ->
      Ember.set(Emu, "defaultStore", undefined)
      @store = Emu.Store.create()
      spyOn(@store, "findPaged")
      @model = Person.findPaged(5, 100)

    it "should proxy the call to the default store", ->
      expect(@store.findPaged).toHaveBeenCalledWith(Person, 5, 100)

  describe "save", ->

    describe "no store specified", ->
      beforeEach ->
        Ember.set(Emu, "defaultStore", undefined)
        @store = Emu.Store.create()
        spyOn(@store, "save")
        @model = Person.createRecord()
        @model.save()

      it "should proxy the call to the store", ->
        expect(@store.save).toHaveBeenCalledWith(@model)

    describe "passing a store", ->
      beforeEach ->
        Ember.set(Emu, "defaultStore", undefined)
        @defaultStore = Emu.Store.create()
        @newStore = Emu.Store.create()
        spyOn(@defaultStore, "save")
        spyOn(@newStore, "save")
        @model = Person.create(store: @newStore)
        @model.save()

      it "should proxy the call to the specified store", ->
        expect(@newStore.save).toHaveBeenCalledWith(@model)

      it "should not proxy the call to the default store", ->
        expect(@defaultStore.save).not.toHaveBeenCalled()

    describe "model field", ->
      beforeEach ->
        @model = App.Person.create()
        @model.set("address.town", "Bath")

      it "should have isDirty true", ->
        expect(@model.get("isDirty")).toBeTruthy()

  describe "getAttr", ->

    describe "collection", ->

      describe "not set", ->

        describe "get once", ->
          beforeEach ->
            spyOn(Emu.ModelCollection, "create").andCallThrough()
            @store = {}
            @model = Person.create(store: @store)
            @result = Emu.Model.getAttr(@model, "orders")

          it "should create an empty collection", ->
            expect(Emu.ModelCollection.create).toHaveBeenCalled()

          it "should have the model as the parent", ->
            expect(@result.get("parent")).toBe(@model)

          it "should be of the type specified in the meta data for the field", ->
            expect(@result.get("type")).toBe(App.Order)

          it "should pass the store reference", ->
            expect(@result.get("store")).toBe(@store)

        describe "get twice", ->
          beforeEach ->
            spyOn(Emu.ModelCollection, "create").andCallThrough()
            @model = Person.create()
            @result1 = Emu.Model.getAttr(@model, "orders")
            @result2 = Emu.Model.getAttr(@model, "orders")

          it "should return the same collection", ->
            expect(@result1).toBe(@result2)

        describe "updatable collection", ->
          beforeEach ->
            Foo = Emu.Model.extend
              people: Emu.field("App.Person", {collection: true, updatable: true})
            @collection = Emu.ModelCollection.create()
            spyOn(Emu.ModelCollection, "create").andReturn(@collection)
            spyOn(@collection, "subscribeToUpdates")
            @model = Foo.create()
            Emu.Model.getAttr(@model, "people")

          it "should create an empty collection", ->
            expect(@collection.subscribeToUpdates).toHaveBeenCalled()

        describe "lazy collection", ->
          beforeEach ->
            Foo = Emu.Model.extend
              people: Emu.field("App.Person", {collection: true, lazy: true})
            @model = Foo.create()
            @result = Emu.Model.getAttr(@model, "people")

          it "should create an empty collection", ->
            expect(@result.get("lazy")).toBeTruthy()

      describe "paged", ->
        beforeEach ->
          spyOn(Emu.PagedModelCollection, "create").andCallThrough()
          @store = {}
          @model = Person.create(store: @store)
          @result = Emu.Model.getAttr(@model, "oldOrders")

        it "should create an empty collection", ->
            expect(Emu.PagedModelCollection.create).toHaveBeenCalled()

        it "should have the model as the parent", ->
          expect(@result.get("parent")).toBe(@model)

        it "should be of the type specified in the meta data for the field", ->
          expect(@result.get("type")).toBe(App.Order)

        it "should pass the store reference", ->
          expect(@result.get("store")).toBe(@store)

    describe "model", ->

      describe "not set", ->

        describe "get once", ->
          beforeEach ->
            @address = App.Address.create()
            spyOn(@address, "subscribeToUpdates")
            spyOn(App.Address, "create").andReturn(@address)
            @model = Person.create()
            @result = Emu.Model.getAttr(@model, "address")

          it "should create an empty model", ->
            expect(App.Address.create).toHaveBeenCalledWith(parent: @model)

          it "should not subscribe to updates", ->
            expect(@address.subscribeToUpdates).not.toHaveBeenCalled()

        describe "get updatable", ->
          beforeEach ->
            @address = App.Address.create()
            spyOn(@address, "subscribeToUpdates")
            spyOn(App.Address, "create").andReturn(@address)
            @model = App.UpdatingPerson.create()
            @result = Emu.Model.getAttr(@model, "updatableAddress")

          it "should create an empty model", ->
            expect(App.Address.create).toHaveBeenCalledWith(parent: @model)

          it "should subscribe to updates", ->
            expect(@address.subscribeToUpdates).toHaveBeenCalled()

        describe "get lazy", ->
          beforeEach ->
            @address = App.Address.create()
            spyOn(App.Address, "create").andReturn(@address)
            @model = App.LazyPerson.create()
            @result = Emu.Model.getAttr(@model, "lazyAddress")

          it "should create an empty model", ->
            expect(App.Address.create).toHaveBeenCalledWith(parent: @model, lazy: true)

    describe "subscribeToUpdates", ->
      beforeEach ->
        Ember.set(Emu, "defaultStore", undefined)
        @store = Emu.Store.create()
        spyOn(@store, "subscribeToUpdates")
        @model = Person.createRecord()
        @model.subscribeToUpdates()

      it "should proxy the call to the store", ->
        expect(@store.subscribeToUpdates).toHaveBeenCalledWith(@model)

    describe "clear", ->
      beforeEach ->
        @model = Person.create()
        @model.set("name", "Bertie")
        @model.set("address.town", "Dartmouth")
        @model.get("orders").pushObject(App.Order.create(orderCode: "1234"))
        spyOn(@model.get("address"), "clear")
        spyOn(@model.get("orders"), "clear")
        @model.clear()

      it "should clear the simple field", ->
        expect(@model.get("name")).toBeUndefined()

      it "should call clear on the model field", ->
        expect(@model.get("address").clear).toHaveBeenCalled()

      it "should call clear on the collection field", ->
        expect(@model.get("orders").clear).toHaveBeenCalled()

      it "should have hasValue false", ->
        expect(@model.get("hasValue")).toBeFalsy()

  describe "setAttr", ->
    beforeEach ->
      @model = Person.create()
      Emu.Model.setAttr @model, "name", "charlie"

    it "should have hasValue true", ->
      expect(@model.get("hasValue")).toBeTruthy()

  describe "primaryKeyValue", ->

    describe "with existing value", ->

      beforeEach ->
        Foo = Emu.Model.extend
          fooId: Emu.field("string", {primaryKey: true})
        @foo = Foo.create(fooId:"10")
        @foo.primaryKeyValue("20")

      it "should have primaryKeyValue as '20'", ->
        expect(@foo.primaryKeyValue()).toEqual("20")

      it "should have hasValue true", ->
        expect(@foo.get("hasValue")).toBeTruthy()

    describe "without existing value", ->

      beforeEach ->
        Foo = Emu.Model.extend
          fooId: Emu.field("string", {primaryKey: true})
        @foo = Foo.create()
        @foo.primaryKeyValue("20")

      it "should have primaryKeyValue as '20'", ->
        expect(@foo.primaryKeyValue()).toEqual("20")

      it "should have hasValue true", ->
        expect(@foo.get("hasValue")).toBeTruthy()

  describe "modifying state", ->

    describe "field in child object", ->
      beforeEach ->
        model = App.Person.create()
        model.on "didStateChange", => @didStateChange = true
        address = model.set("address.town", "London")

      it "should have fired the didStateChange event", ->
        expect(@didStateChange).toBeTruthy()

    describe "adding item to collection field", ->

      describe "not lazy", ->
        beforeEach ->
          model = App.Customer.create()
          model.on "didStateChange", => @didStateChange = true
          addresses = model.get("addresses")
          addresses.pushObject(App.Address.create(town: "London"))

        it "should have fired the didStateChange event", ->
          expect(@didStateChange).toBeTruthy()

      describe "lazy", ->
        beforeEach ->
          model = App.Customer.create()
          model.on "didStateChange", => @didStateChange = true
          addresses = model.get("orders").createRecord()

        it "should not have fired the didStateChange event", ->
          expect(@didStateChange).toBeFalsy()