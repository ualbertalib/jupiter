The Path Forward
================

 There are fundamental problems with Fedora that are never going to make it an appropriate datastore for a web application (https://groups.google.com/d/msg/samvera-tech/47pFj9lzkkQ/S1oUQs1CAwAJ) ActiveFedora seems to be falling out of support with many of the major contributors now working on Valkyrie.

The writing is on the wall: Fedora is dead, and transitioning sooner rather than later seems smarter. The more data
gets thrown in Fedora, the more painful the inevitable switch is going to be down the road. In its current state
I would anticipate being forced off of Fedora in less than 5 years (I think Geoff once said something about all of these
systems having a very short lifespan, but respectfully, I completely disagree -- there's no reason the libraries shouldn't
be aiming to get 10-20 years out of a single well-maintained DAMs project. The failure of all systems thus far to
survive even half that long is the direct and inevitable consequence of the technical immaturity of most of the library-specific open-source ecosystem, and a lack of experience with the underlying language/frameworks/datastores
factoring into some of the decision making)

I think the temptation, especially with me gone, will be to look heavily towards Valkyrie as an "easy" path on
to Postgresql. My advice is to resist this temptation at all costs. It will not make the transition any easier
(everything that needs to be rewritten in this plan would need to be rewritten for Valkyrie anyways), and Valkyrie
has almost all of the same downsides as ActiveFedora -- you cannot hire anyone who knows it, it will seem completely
alien to anyone you do hire, and it locks you out of a huge chunk of the Rails and Ruby ecosystem.

In short, it simply solves no problems that you actually _have_. It is another example of the community over-engineering something bespoke and specific to libraries when they should be looking to get out of that trap.

In its current state, everything in `jupiter_core` is intended to work such that there are only a few places in the application
that interact directly with ActiveFedora:

  - Inside `LockedLdpObject` itself.
  - Inside `unlocked do ... end` blocks in models
  - Inside `unlock_and_fetch_ldp_object` blocks generally

We need not worry about the first case as all, as it only exists to paper over deficiencies in ActiveFedora.
If we're moving to ActiveRecord, we should remove LockedLdpObject entirely.

Prior to transitioning, the later two should be audited for anything particular dependent on ActiveFedora semantics.
A lot of what's in them should be completely compatible with ActiveRecord eg) validations and other supporting logic. Most
of the rest, eg) manipulating ordered_members to get the PCDM to generate the "right" RDF representation, can be
removed entirely, as this is something that should be solved in a serialization project, not in Jupiter (see below).

The main thrust of work will actually be in creating new ways of representing attribute-predicate relationships,
in altering the models to fit these new patterns, and in migrating the data itself into a new RDBMS.

The key to moving forward is to get away from the idea that the way data is stored for the web application needs to
look anything like the way it is represented for metadata purposes, or for distribution to other institutions, or for
distribution over the world wide web. If I have seen one common theme mistake being made both in the Samvera community and elsewhere it is that, while tempting, STORING DATA IN EXPORT FORMATS IS ALWAYS, _ALWAYS_ A MISTAKE. Storing metadata at rest as RDF for the webapp was never going to work out.

My suggestion is that data for Jupiter in a way that makes sense for web applications. Follow the Pushmi-Pullyu model and create
different, single-purpose projects to move and transform this data to other systems. PMPY should continue to
transform the data and move it into preservation; a separate new project should be created to transform and move
data to a triplestore for metadata consumption, and yet another separate new project should be created to
transform and distribute the data for OAI. These serialization projects can worry about the specifics of how to generate
a suitable RDF or other linked-data representation from the web application's data.

Avoid creating swiss-army knife projects, like datastores that are also
webservers that also handle OAI that also etc. This is very fragile and will not adapt well to changes over time.

How I think Data Should Be stored in Postgresql
===============================================

Create more-or-less completely standard Rails models for all of the existing things: Items, Theses, Collections, Communities.
Good news! We've secretly already been doing this with DraftItem and DraftThesis -- you should be able to rename these to Item and Thesis and simply add a column to indicate Draft state.

The one thing that databases aren't necessarily great at is representing arrays of values for a given column, but we've solved that in DraftItems with json columns to represent arrays of values. This seems flexible enough to cover most cases.

create a separate mechanism for tracking predicate information IN Postgresql. My proposal is a Predicates table
consisting simply of:

```
id | predicate URI
===================
1  | http://purl.org/dc/terms/title
2  | ....
```

etc (with each URI appearing only once) and a separate Predicate-Class join table

```
id | table_name | column_name | predicate_id
=============================================
1  | items      | title       | 1
2  | ... etc
```

This provides enough information to construct triples for export to a suitable format, stores predicate information
in the same place as the data itself, while retaining compatibility with normal ActiveRecord.

To integrate this with Rails, I envision the following:

Create a DSL for declaring predicates _in migrations_ rather than in models (this has always been an odd and unrails-y
place to put them, as it implies they're dynamically redeclarable, which they're not). I'm picturing something like:

```ruby
class CreateItemsTable < ActiveRecord::Migration[5.1]

  def change
    create_table :items do |t|
      t.string :uuid

      t.integer :status, default: 0, null: false
      t.integer :wizard_step, default: 0, null: false

      t.integer :thumbnail_id

      t.string :title, predicate: ::RDF::Vocab::DC.title
      t.string :alternate_title, predicate: ::RDF::Vocab::DC.alternative
      t.date :date_created, predicate: ::RDF::Vocab::DC.created
      t.text :description, predicate: ::RDF::Vocab::DC.description
      t.json :contributors, array: true, predicate: ::RDF::Vocab::DC11.contributor

      # ... etc

      t.timestamps
    end
  end
end
```

Note that this doesn't require an enormous facility with metaprogramming to accomplish -- the same thing could
be very straightforwardly done simply by creating taking advantage of the fact that migrations are just a Class,
and creating a simple `annotate_predicates` method that takes a hash of column->URI mappings
in a module somewhere eg)

```ruby
class CreateItemsTable < ActiveRecord::Migration[5.1]
  include Predicatable
  def change
    create_table :items do |t|
      t.string :uuid

      t.integer :status, default: 0, null: false
      t.integer :wizard_step, default: 0, null: false

      t.integer :thumbnail_id

      t.string :title
      t.string :alternate_title
      t.date :date_created
      t.text :description
      t.json :contributors, array: true

      # ... etc
      t.timestamps
    end

    annotate_predicates :items, {
      title: ::RDF::Vocab::DC.title,
      alternate_title: ::RDF::Vocab::DC.alternative,
      date_created: ::RDF::Vocab::DC.created,
      description: ::RDF::Vocab::DC.description,
      contributors: ::RDF::Vocab::DC11.contributor
    }
  end
end
```

With that method handling the insertions into the Predicates, and Predicate-Class tables

Doing it this way has a few advantages:
- it correctly represents the fact that predicate changes require data change, and are not changeable on the fly.
- by storing them in a join table, it actually makes changing predicates much easier.
`update Predicates set predicate_URI = 'http://some.other/url/title' where id = 1;` will instantly change the URI
of all objects with an attribute using that URI throughout the system -- contrast with Fedora, where this would involve
individually updating each object, potentially taking hours (currently) or even days (with millions of digitized records).
Mistakes can easily become to expensive to fix in the Fedora model, and we have _already_ made several URI mistakes &
changes over time.

Representing membership
========================

We currently do this in a hybrid way. Fedora has supported for nesting arbitrary documents, but in practice we
use this only indirectly through Hydra's PCDM implementation. Fedora's way of nesting items mostly creates
problems for us, as retrieving a parent object _requires_ Fedora to load every child of said object, ie. all
items in the collection, with terrible performance implications (https://groups.google.com/d/msg/samvera-tech/47pFj9lzkkQ/S1oUQs1CAwAJ)

In practice we treat this nesting as write-only, otherwise ignoring Fedora's capabilities and currently use paths stored on solr documents in order to express membership of items in collections and communities. This model can equally be used to arbitrarily represent anything with an id by a child of some other thing with an id, recursively, and be efficiently queried.

Leveraging Solr for this could theoretically continue indefinitely, although I think there are downsides in terms of
critical membership information not being stored in the primary RDBMS and therefor running the risk of getting out of
sync due to a lack of shared transations between Postgres and Solr updates.

Fortunately there are options available for implementing the same basic idea in Postgresql
(represent membership trees as paths on objects). Either of https://github.com/ClosureTree/closure_tree
(which I think is database agnostic) or https://github.com/sjke/pg_ltree (which relies on Postgres's ltree extension)
should work for this purpose. Note that the ltree implementation is more general than closure tree, and can
directly represent a node having more than one path (ie, an item being in more than one collection), whereas
some workarounds would be necessary in the closure_tree implementation (you could create an intermediate "proxy" model such that every instance of the proxy had a single parent but an item can be pointed at by more than one proxy. There are inefficiencies implied in loading or modifying this, though. My off-the-cough suggestion is that pg_ltree is probably
all you'll need).


Exporting linked data formats
==============================

Once the predicate and nesting information is stored in the database, exporting triples should be fairly straightforward. I'd
suggest leveraging the JSON-LD gem (https://github.com/ruby-rdf/json-ld) -- essentially just use rails built-in
support for json serialization to turn the activerecord object in json, and then use the predicate table to add
the @context specifier. The predicate table queries should be quite straightforward. Using DraftItem as an example
ActiveRecord class:

```ruby
> DraftItem.table_name
 => "draft_items"

 > DraftItem.column_names
 => ["id", "uuid", "status", "wizard_step", "thumbnail_id", "title", "alternate_title", "date_created", "description", "source", "related_item", "license", "license_text_area", "visibility", "embargo_end_date", "visibility_after_embargo", "type_id", "user_id", "creators", "subjects", "member_of_paths", "contributors", "places", "time_periods", "citations", "created_at", "updated_at"]
```

querying the predicate table to build up the @context specifer then is as simple as a method in application_record:

```ruby
   def generate_context_statements
     context = {}
     table_name = self.class.table_name
     self.class.column_names.each do |column|
       predicate = PredicateClass.find_by(table_name: table_name, column_name: column).predicate.uri
       context[column] = predicate
     end
     return context
   end
```

(although serializing every single column probably isn't desired, you probably just want to customize as_json to only
serialize some columns into the JSON-LD, like we do here https://github.com/ualbertalib/jupiter/blob/master/app/models/collection.rb#L49, and then only include those same
columns in the context statment)


Once you've done that, you should be able to either import the generated JSON-LD into
external applications like a triplestore directly, or use the RDF gem to convert the JSON-LD into RDF etc as described
in that repository. This should be easy to wrap up in an instance method in application_record.rb or some other
common super-class of all "Predicatable" classes.

Solrization
============

When removing Fedora we will still presumably want to leverage solr for search (although if elastic-search is ever
going to be on the table, now would be the time to switch). The major functionality that will need to be replaced
in a hand-rolled solution is getting information about documents into the Solr indexes.

In general I'd suggest abandoning the "name-mangling"/dynamic schema concept from Hydra and just spelling out index
types by-hand in schema.xml, at least initially. I'm not convinced that all of the added complexity of Solrizer really
saved any effort vs doing it by hand, and it certainly seemed to be more confusing/opaque for most people in practice.

In general I don't think this has to be very complicated. Each model could define a hash of attributes and the names of
the solr indexes they should be placed in. Given a schema.xml containing something like:

```xml
<field name="title_search" type="string" stored="true" indexed="true" multiValued="true"/>
<field name="title_sort" type="alphaSort" stored="true" indexed="true" multiValued="false"/>
<field name="subject_facet" type="string" stored="false" indexed="true" multiValued="true"/>
```

a model might declare solr attributes:

```ruby
   def solr_attrs
     {
       title: [:title_search, :title_sort],
       subject: [:subject_facet],
       temporal_subjects: [:subject_facet],
       spacial_subjects: [:subject_facet]
     }
   end
```

and by leveraging an `after_save` hook in application_record or some other superclass of solrizable classes:

```ruby
after_save :update_solr

def update_solr
  solr_doc = {}
  self.solr_attrs.each do |attribute_name, indexes|
    value = self.send(attribute_name)
    indexes.each do |index_name|
      solr_doc[index_name] = value
    end
  end

  solr_connection.add solr_doc
end
```

(assuming you've set up a method some where to return the current RSolr::Client connection. https://github.com/rsolr/rsolr explains how. Error handling and empty/nil values will need to be taken into account, too, but this should generally
work for most things)

The Rest of the DAMS
====================

Discovery
---------

I'd look at splitting the search-related files out of Jupiter and into their own gem. along with some of the
views for /search, and start a separate Rails app using that gem (resist any urges to make one Rails app do EVERYTHING.
Building out separate apps with some shared infrastructure will scale better). This is honestly a very small application,
and once good requirements are fleshed out this should not take very long at all to build out -- almost everything it needs
is literally already done in Jupiter. Once Sean has gathered sufficient requirements, rebuilding a cleaner ingest pipeline
can be pursued together or separately with this -- ingest and web presentation should be decoupled as separate projects.
Building a DSL on top of Traject that would allow catalog librarians to exert some influence over ingest directly, without
needing to go through a developer, would probably prove very fruitful.

Avalon
-------

If there's no appetite for pursuing "Avarax", I'd suggest just adding the active-encode gem directly to jupiter and using
https://github.com/video-dev/hls.js/ or some other JS client on the front-end. To be honest, though, if the only concern
is preservation of the master file and not the derivatives, I'd _STRONGLY_ suggest people sit down and have some hard
conversations about whether it is worth the cost and effort of owning, operating, and maintaining bespoke streaming
infrastructure vs just uploading a copy of the master file to Amazon Elastic Transcode (or Zencloud, or tokbox or) and then streaming them out of cloudfront or some other CDN. This would reduce scaling difficulties and server maintenance costs
almost completely, you would still be able to restrict the content to whatever audiences are required (there are many,
many tutorials on doing so) and this functionality could be added to Jupiter NOW, in less time than it took Chris to
port Avalon 5 to 6. Going this route, I think the entire is maybe a couple of sprints of work max for someone who knows what they're doing with basic Rails and Sidekiq -- it will probably take longer to design and implement the upload forms and metadata model than make streaming work with a standard AWS setup). Running the infrastructure seems like a cost hole
that provides no benefits and significantly increases both development time/cost and hosting complexity/sysadmin burden -- offloading the encoding and distribution would save time and money.


Other random thoughts
======================

- Stick with GUIDs for primary keys on your items. Postgres handles this natively, and well. Switching to integers will
get you into trouble some years down the road as you digitize millions of records. Switching to NOIDs will slow things
down as all your primary key comparisons would require string comparisons. GUIDs are what you want.

- When it comes to big architectural or infrastructure decisions, get developers in on the process early and let them use their experience and expertise to help you make the right decisions. If there's a lack of Rails knowledge here, consider hiring consultants (particularly, non-DCE style library world consultants. Seek the advice of professionals outside the bubble!) to give you feedback on big architectural plans. A day spent sitting down and talking to someone with Rails experience to get feedback on Fedora-based solutions from people with insights outside the Library world might have saved years of pain.
