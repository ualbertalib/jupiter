

The general design principle behind Jupiter is to try and contain as much of the "library weirness" as possible in jupiter_core, such that the rest
of the application (models, controller, and especially views) can be as close to "Rails-normal" as possible. There are several motivations for doing this:

- Ease of hiring people in the future. Outside of a very small pool of library-experienced developers, NOBODY understands Fedora/ActiveFedora, and this problem
if only going to increase as the community moves on. This costs MONTHS of increased onboarding time
-  Increasing productivity. The Rails environment has shown itself to be a productive one for developers. The Sufia/Hyrax development patterns have shown themselves
to be supremely unproductive. We should take the hint and follow the patterns that get things done. Additionally, MOST of the open source libraries out there
assume the presence of a "normal" Rails app setup and a "normal" RDBMS. Deliberately flouting these conventions leads to long periods of time just reinventing the wheel because
we've made it impossible to leverage what's already out there.
- "Knowledge containment" is one of the most important features of a maintainable code-base. The more any given part of a codebase needs to know about other "far away" parts of the codebase,
the harder the codebase becomes to modify and maintain. Hyrax suffers from *extremely* poor knowledge containment, and the basic design of ActiveFedora encourages knowledge about
how Fedora and Solr work to "leak" into controllers and views, making porting an existing Hyrax deployment to even a new version of Hyrax an incredibly time-consuming activity. We aim to
avoid repeating this mistake by containing as much solr- and fedora- specific knowledge as possible within jupiter_core and in ~clearly delimited~ "unlock" blocks

Jupiter Core
-------------

We can broadly split the responsibilities of Jupiter Core up along the following lines:

Utility Glue to Make Things Work™

active_storage_macros.rb -- duplicates the ActiveStorage DSL but uses attachment shims to bridge ActiveFedora objects with ActiveRecord ActiveStorage models
attachment_shim.rb -- a placeholder object that "owns" the ActiveStorage attachment data and can be looked up by the ID of the associated ActiveFedora object
indexer.rb -- ActiveFedora uses "indexer" classes for each class inheriting from ActiveFedora::Base that control which properties from activefedora appear in solr.
since creating these was a lot of busywork & forgetting to update these classes was a rich source of bugs, we just use one class shared among everything inheriting
from LockedLDPObject, which indexes everything and adds hooks for adding additional indexes.


Search Machinery. This the core Solr Encapsulation that keeps the rest of the app from having to know about the particulars of solr index name mangling or ActiveFedora's
slow/broken query mechanisms.

search.rb -- Basic interface to Solr through which all queries ultimately pass. Provides the public API for running any kind of search against solr. Has
responsibility for enforcing visibility restrictions.

deferered_faceted_solr_query.rb -- object representing a not-yet-complete Solr query which will return facets
deferred simple solr query -- object representing a not-yet-complete Solr query which attempts to provide enough of a basic ActiveRecord-like API
that most of the app can use it as a drop-in replacement for ActiveRecord (without trying to go overboard and cover ALL of ActiveRecord. This is like the 5% we can limp by on)

facet result -- encapsulates a facet result "category" and any facet hits underneath it. maps the mangled solr index name to a human-readable name and provides iteration of facet hits

range facet result -- encapsulates a facet result "category" containing a simple range. maps the mangled solr index name to a human-readable name.


The Core Abstraction over ActiveFedora. A Base Class for the rest of the models:
locked_ldp_object -- provides class methods that mimic basic ActiveRecord class-level query APIs (Item.first, .last, .where etc).
Provides mechanisms for converting mangled solr index names to attribute names, and vice versa.

NOTE: there's one unfortunate incompatibiltiy that crept in here, which is that find_by doesn't take an attribute argument, just an ID.
this will need refactoring when switching to ActiveFedora.

Every instance of a locked_ldp_object is at heart a solr document (in the form of a parsed hash) mapping solr_mangled_name properties to values.
It may also OPTIONALLY contain have a loaded "ldp_object", an instance of an ActiveFedora object loaded via ActiveFedora. This will only be loaded when `unlock_and_fetch_ldp_object` is run.
solr documents are READ-ONLY. ldp_objects are READ-WRITE. Because ldp_objects are not normally loaded,
interacting with a subclass of locked_ldp_object only involves querying Solr, which is fast, and bypasses talking to ActiveFedora or raw Fedora entirely


Overview of how LockedLDPObject does what it does
==================================================

When you declare a class inheriting from LockedLDPObject, eg)

```ruby
class Item < JupiterCore::LockedLdpObject
end
```

several things happen. As this item subclass is being created in memory (ie, during the early part of the web server booting up)
LockedLdpObject#inherited runs, which does the following in the new subclass:

1) allocates a bunch of hashes to track mappings of attribute names to solr mangled names, and vice versa, along with information
about the type of index, the type of values it will hold, etc.
2) Defines some basic attributes and their predicates for the new subclass if they're not already present.
These are visibility, owner, record_created_at, hyrdra_noid, and date_ingested.

defining any attributes in the new subclass (among other things), will cause a corresponding ActiveFedora class to be generated
(this happens the first time derived_af_class is run, as it runs generate_af_class if its not already defined). As a simple example:

```ruby
class Item < JupiterCore::LockedLdpObject
  has_attribute :title, ::RDF::Vocab::DC.title, type: :string, solrize_for: [:search, :sort, :exact_match]
end
```

causes the following to happen:
1) LockedLdpObject#inherited runs, as above.
2) LockedLdpObject#has_attribute calls derived_af_class, which on first call runs generate_af_class, which:
    - creates a new class inheriting from ActiveFedora::Base named IRItem
    - adds a method named `owning_object` to IRItem. Calling owning object on an IRItem instance will return
    the corresponding Item instance.
    - defines several basic validations, as all validation mechanism are run via ActiveFedora. This run_validations
     enforce the presence ofvisibility, an owner, record_created_at, and date_ingested. call backs are added to automatically
     populate the date_ingested and record_created_at.
    - defines methods to check whether something just transitioned to or from private visibility (needed for DOI logic)
    - defines a `convert_value` method used internally in the ActiveFedora objects. We use this to pre-convert values (or raise an error if they're the wrong type) to the type they were
    declared to be BEFORE handing them to ActiveFedora, which is extremely buggy and generally silently does bad things. An example
    here is if we did `item.unlock_and_fetch_ldp_object {|uo| uo.title = 3}`, 3 would pass through `convert_value` before being assigned to the title attribute in activefedora, and an error
    would be raised (whereas raw ActiveFedora would just silently store a 3, type declarations irrelevant, and then bad things would happen with solr later).
    Doing this ourselves bypasses multiple date conversion bugs we've hit in Fedora over time.
    - papers over an ActiveFedora bug that would otherwise lead to validations not running.
    - creates a method named `owning_class`. `IRItem.owning_class` returns `Item`
    - sets the IRItem ActiveFedora indexer to our indexer.rb class
    - adds method forwarding such that if a method is defined on an Item instance, it can transparently be called from an IRItem instance as if they were the same object
    (remember, this is safe because all methods on Item have to be read-only and only deal with the solr document which is always present;
    you can't call methods on IRItem from methods on Item outside of an unlock_and_fetch_ldp_object block, because those methods mutate the IRItem, which isn't loaded outside of unlock_and_fetch_ldp_object blocks)
3) The rest of has_attribute runs, which:
    - ensures that the arguments are correct, types are known, etc.
    - stores type tracking and name mangling information in the hashes created in `inherited`
    - uses `defined_cached_reader` to define a method named `title` on the Item object that essentially works like:
        ```ruby
        def title
          return ldp_object.title if ldp_object.present?
          coerce_value(solr_document[:title_tesim].first, :string)
        end
        ```
        Remember that ldp_object is only present if an `unlock_and_fetch_ldp_object` block has been run, meaning that the object's title may have changed
        but not yet been saved (so the data in the solr_document may be out of date). Thus if it is present we should return the ldp_object.title, and not the possibly stale solr data.
        saving the ldp_object will bring the solr data back into sync.

        Because solr docs are always multivalued but not all of our attributes are `defined_cached_reader` deals with returning single values instead of arrays
    - defines a method `title=` on Item, which simply raises an error message asking the programmer to use `unlock_and_fetch_ldp_object`. This is done to help people figure out the right way to do things
    - runs the "normal" ActiveFedora property declaration code in IRItem, eg:
        ```ruby
          property :title, predicate: ::RDF::Vocab::DC.title, multiple: false do |index|
            index.type :string
            index.as [:stored_searchable, :stored_sortable, :symbol]
          end
        ```
      Internally to ActiveFedora, running this in an IRItem causes `title` and `title=` methods to be defined on IRItem
    - In IRItem, renames `title=` to `shadowed_assign_title` and then defines a new `title=` that does the following
        - if the value being assigned is an array, and the attribute was declared to be of type :json_array, it serializes
        the array into a string. otherwise it runs `shadowed_assign_title(convert_value(title), to: :string)` to manually deal with type conversion, as mentioned above.
    - If the attribute was declared of type :json_array, in IRItem it also:
        - renames `title` to `shadowed_title` and defines a new `title` method that essentially does `Json.parse(shadowed_title)` to deserialize the serialized array stored in activefedora
