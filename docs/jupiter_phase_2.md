The Path Forward
================

 There are fundamental problems with Fedora that are never going to make it an appropriate datastore for a web application. ActiveFedora seems to be falling out of support with many of the major contributors now working on Valkyrie.

The writing is on the wall: Fedora is dead, and transitioning sooner rather than later seems smarter. The more data that gets thrown in Fedora, the more painful the inevitable switch is going to be down the road. In its current state I would anticipate being forced off of Fedora in less than 5 years. I think Geoff once said something about all of these systems having a very short lifespan, but respectfully, I completely disagree -- there's no reason the libraries shouldn't be aiming to get 10-20 years out of a single well-maintained DAMs project. The failure of all systems thus far to
survive even half that long is the direct and inevitable consequence of the technical immaturity of most of the library-specific open-source ecosystem, and a lack of experience with the underlying language/frameworks/datastores factoring into some of the decision making.

I think the temptation, especially with me gone, will be to look heavily towards Valkyrie as an "easy" path on to Postgresql. My advice is to resist this temptation at all costs. It will not make the transition any easier (everything that needs to be rewritten in this plan would need to be rewritten for Valkyrie anyways), and Valkyrie has almost all of the same downsides as ActiveFedora -- you cannot hire anyone who knows it, it will seem completely
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

The main thrust of work will actually be in creating new ways of representing attribute-predicate relationships, in altering the models to fit these new patterns, and in migrating the data itself into a new RDBMS.

The key to moving forward is to get away from the idea that the way data is stored for the web application needs to look anything like the way it is represented for metadata purposes, or for distribution to other institutions, or for distribution over the world wide web. The desire to "be PCDM compliant" shouldn't mean some kind of mandate that data _only_ be stored in a way recognizable as standard PCDM even for use-cases where such a data layout is profoundly sub-optimal. It should merely mean that, however the data does happen to be stored for the web application, we know how to _transform_ it into nice, clean PCDM on demand. If I have seen one common mistake being made both in the Samvera community and elsewhere it is that, while tempting, STORING DATA IN EXPORT FORMATS IS ALWAYS, _ALWAYS_ A MISTAKE. RDF in particular, and PCDM in general, are export formats -- they're for consumption by external parties, not for structuring the internals of an application.

My suggestion is to follow the Pushmi-Pullyu model and create different, single-purpose projects to move and transform the web application's data for consumption by external parties or other systems. PMPY should continue to transform the data and move it into preservation; a separate new project should be created to transform and move data to a triplestore for metadata consumption, and yet another separate new project should be created to transform and distribute the data for OAI. These serialization projects can worry about the specifics of how to generate a suitable RDF or other linked-data representation from the web application's data.

Avoid creating swiss army knife projects, like datastores that are also webservers that also handle OAI that also etc. This is very fragile and will not adapt well to changes over time. Done as separate projects, you unlock a lot of scalability that the linked data community seems to totally lack.

As an example, if the OAI server is separate from the web application, it can benefit from having something transforming the web-app's data directly into a stored, read-only OAI format in a separate data store. This means both that the OAI server can be extremely fast (it need not query Modeshape for data and then transform the RDF into an OAI format on every request) _and_ that crawlers hitting the OAI server have _zero_ impact on the performance of the web application or its database (and vice-versa!).

In the current setup, everything is intertwined, and an aggressive OAI crawler can cripple deposits by keeping Fedora too busy, or an aggressive downloader can prevent OAI queries from completing for the same reason. This simply is not scalable to any reasonable level.


Representing Metadata Schemas in Postgresql
===============================================

My suggestion for the metadata itself is that you create more-or-less completely standard Rails models for all of the existing things: Items, Theses, Collections, Communities. This runs counter to: the way Samvera did it traditionally, with Fedora/ActiveFedora, the way Valkyrie is doing it currently (by acting as an abstraction layer over either Fedora or using Postgresql as a schemaless JSON store), and the way Rochkind seems to plan to do it in his proposal (using Postgresql as a schemaless JSON store directly -- his proposal does have the advantage that he already wrote a gem that claims to make this transparent. No offense to him, but I still think this will turn out the same way ActiveFedora did in the sense that it's by definition a much less battle-tested approach, with a much smaller development team, and it's likely that adopters will hit sharp edges).

Call me iconoclastic, but I still do not understand the resistance to using regular ActiveRecord and regular RDBMs features here, as I've never seen a compelling argument that the following idea would not work. The one thing that databases aren't necessarily great at is representing arrays of values for a given column (normally preferring somewhat awkward join tables), but we've solved that in DraftItems & DraftTheses with json columns to represent arrays of values. This seems flexible enough to cover most any case one might encounter, and is completely suported by stock ActiveRecord.

The good news is, we've secretly already essentially battle-tested this approach with DraftItem and DraftThesis -- you should be able to rename these to Item and Thesis and simply add a column to indicate Draft state and call the modeling done for those two kinds of objects.

What will remain to be done is creating a mechanism for tracking predicate information IN Postgresql. My proposal is a Predicates table
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

This provides enough information to construct triples for export to a suitable format and stores predicate information
in the same place as the data itself, while retaining compatibility with normal ActiveRecord.

To integrate this with Rails, I envision the following:

Create a DSL for declaring predicates _in migrations_ rather than in models (this has always been an odd and unRails-y
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

Doing it this way has advantages:

1) It correctly represents the fact that predicate changes require data change, and are not changeable on the fly.
2) By storing them in a join table, it actually makes changing predicates much easier.
`update Predicates set predicate_URI = 'http://some.other/url/title' where id = 1;` will instantly change the URI
of all objects with an attribute using that URI throughout the system -- contrast with Fedora, where this would involve
individually updating each object, potentially taking hours (currently) or even days (with millions of digitized records).
Mistakes can easily become to expensive to fix in the Fedora model, and we have _already_ made several URI mistakes &
changes over time.

You could, alternatively, simply store the schema as one json blob document directly in the Predicates-Class table. eg) for any given class, there would be
one entry in the table containing a json blob like

```json
{
  "title": "http://purl.org/dc/terms/title",
  "alternate_title": "http://purl.org/dc/terms/alternative",
  ...
}
```

with everything working more-or-less the same. This isn't necessarily a terrible idea, but it could mean that similar objects that should share a predicate for, say, title become out of sync, as each class's schema will need to have the predicates updated individually.

The extreme version of this approach would be to put the schema column directly onto the Items, Theses, etc tables, such that each individual object's row contains a full copy of its schema. Don't do this. We benefit a lot from objects having very well-defined metadata schemas, so the waste of space of doing things this way is QUITE significant, and it puts you back into Fedora territory when it comes to fixing or changing a predicate URI -- every single object must be individually updated. I see no upside to this approach.


Representing membership
========================

We currently do this in a hybrid way. Fedora has support for nesting arbitrary documents, but in practice we
use this only indirectly through Hydra's PCDM implementation. Fedora's way of nesting items mostly creates
problems for us, as retrieving a parent object _requires_ Fedora to load every child of said object, ie. all
items in the collection, with terrible performance implications (https://groups.google.com/d/msg/samvera-tech/47pFj9lzkkQ/S1oUQs1CAwAJ)

In practice we treat this nesting as write-only, otherwise ignoring Fedora's capabilities and currently use paths stored on solr documents in order to express membership of items in collections and communities. This model can equally be used to arbitrarily represent anything with an id by a child of some other thing with an id, recursively, and be efficiently queried.

Leveraging Solr for this could theoretically continue indefinitely, although I think there are downsides in terms of
critical membership information not being stored in the primary RDBMS and therefore running the risk of getting out of sync due to a lack of shared transactions between Postgres and Solr updates.

Fortunately there are options available for implementing the same basic idea in Postgresql (represent membership trees as paths on objects). Either of https://github.com/ClosureTree/closure_tree (which I think is database agnostic) or https://github.com/sjke/pg_ltree (which relies on Postgres's ltree extension) should work for this purpose.

Note that the ltree implementation is more general than closure tree, and can directly represent a node having more than one path (ie, an item being in more than one collection), whereas some workarounds would be necessary in the closure_tree implementation (you could create an intermediate "proxy" model such that every instance of the proxy had a single parent but an item can be pointed at by more than one proxy. There are inefficiencies implied in loading or modifying this, though. My off-the-cuff suggestion is that pg_ltree is probably all you'll need).

Rochkind, on this same subject, wrote:

> We will plan from the start to prioritize efficient rdbms querying over ontological purity. Dealing with avoiding n+1 (or worse) when doing expected things like displaying a list of objects/works with thumbnails, or displaying all a work’s members with thumbnails. In some cases we may resort to recursive CTEs; some solution will be built into the tool, this isn’t something to make developer-users figure out for themselves each implementation.

I heartily co-sign the idea of abandoning any and all thoughts of "ontological purity" when it comes to designing the DAMS web applications' database models. Remember, the idea here is to let the web apps handle things in a webapp-y way and _transform_ this data via separate translator projects for things like triplestore ingestion, serving OAI feeds, etc. The transformations can output data as pure and normalized as metadata or OAI consumers want -- don't cripple the web application's performance to "pre-design" that purity before you need to.

Again, this is very much the approach taken in industry -- store data in a way that makes sense to keep the user-facing web applications fast and functional and _transform_ that data via pipeline tools on the way into completely separate data stores for other teams (a triplestore for Metadata team here is no different in overall purpose than a hadoop cluster for a machine-learning team at an internet company).

All that said, stay away from recursive CTEs to resolve membership queries. We know the path approach works -- if no sufficient tree representation is workable in postgresql, I'd look at the viability of doing it the way we're doing it right now via solr, rather than resort to expensive recursive SQL query approaches.


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
columns in the context statement)

Once you've done that, you should be able to leverage the generated JSON-LD in external PMPY-style projects that either ingest the json-ld into a triplestore directly, or have those external projects use the RDF gem to convert the JSON-LD into RDF as described in the json-ld gem repository. This should be easy to wrap up in an instance method in application_record.rb or some other common super-class of all "Predicatable" classes.

Solrization
============

When removing Fedora we will still presumably want to leverage solr for search (although if elasticsearch is ever
going to be on the table, now would be the time to switch). The major functionality that will need to be replaced
in a hand-rolled solution is getting information about documents into the Solr indexes.

I'd suggest abandoning the "name-mangling"/dynamic schema concept from Hydra and just spelling out index
types by-hand in schema.xml, at least initially. I'm not convinced that all of the added complexity of Solrizer really
saved any effort vs doing it by hand, and it certainly seemed to be more confusing/opaque for most people in practice.

In general I don't think this has to be very complicated. Each model could define a hash of attributes and the names of
the solr indexes they should be placed in. Given a schema.xml containing something like:

```xml
<field name="title_search" type="string" stored="true" indexed="true" multiValued="true"/>
<field name="title_sort" type="alphaSort" stored="true" indexed="true" multiValued="false"/>
<field name="subject_facet" type="string" stored="false" indexed="true" multiValued="true"/>
```

a model might declare solr indexes:

```ruby
   def solr_indexes
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
  self.solr_indexes.each do |attribute_name, indexes|
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

Alternatively, Rochkind mentions a plan to use Traject for indexing (presumably in the background?) in his proposed IR plan. It seems less _simple_ to do it that way, to me, but since he's both the core Traject developer and aware of what he needs for indexing, I can't say there's anything wrong with it, and I'm sure it's an approach with which he's intimately familiar. It seems like more moving parts for what's currently needed here for the IR, though.

Asset Management
=================

Rochkind is pitching Shrine as a more flexible solution than ActiveStorage. In the short term, he's probably correct, but I think history has shown that the existence of an "official" Rails solution generally leads to the slow death of most competitors. I can't see many reasons to invest effort into switching away from something that's currently working, and most of that flexibility has to do with using 3rd party CDNs, which we don't use (although they really are worth considering, see below).

ACLs
=====

To the extent you can stretch an ownership/group model (think traditional Unix permissions) to meet your needs, I suggest you fight tooth-and-nail to avoid buying into an ACL framework. Yes, they are flexible. Yes, they are a web "standard". But a flexible, standardized 90-barreled foot-gun is still mostly just a tool for shooting your own toes off.

It's worth really looking at what happened with The Samvera Permissioning and Analysis Working Group here. Users, even power-users and admins, think in terms of resource ownership because that's how most things work in real life. In the presence of an ACL system, "ownership" ceases to meaningfully exist, as any number of (possibly unknown to you) people can have any combination of permissions to an object. This inevitably leads to users presenting simple use-cases like "I would like to be able to transfer ownership of an object" that degenerate into the very question the Samvera Working Group wrapped up by asking: "There is still a need to determine whether this ownership transfer is intended to also transfer permissions, or if it has some other focus. What is being transferred and why?".

When your users think in terms of owning something, and your designers and developers are forced to ask _what ownership even means_, your system's semantics and your users' expectations are so utterly divorced that you're guaranteed that:

1) Nobody who uses the system understands how the permissions system really works.

2) As a consequence of this, some subset of users don't have permissions to things that they should. This is an annoyance.

3) ALSO as a consequence of this, some subset of users have permissions to things that they shouldn't. This is a security issue. We saw exactly this in Sufia-6 based ERA's objects.

Group permissioning & owner modeling can get you really, really far. I'd suggest being willing to go to suffer a LOT of pain to live with it, rather than moving to ACLs. What seems like a simple solution will inevitably entail endless frustration.

Blacklight
==========

A lot of the design decisions Blacklight makes are fairly non-Railsy and tend to force the rest of the application to know about Blacklight-specific design patterns. I don't feel like we suffered from using raw RSolr directly in Jupiter, and it made a lot of things a lot more transparent -- figuring out how to do things only required referencing the Solr documentation, rather than Blacklight's (lack of) documentation and digging through its opaque and hard-to-understand sourcecode. I can't see any reason to consider moving back towards Blacklight for the IR -- as I mention next, I'd look at dropping it entirely from all of the library's codebases.

Bypassing Blacklight was, I think, a big win for Jupiter.

The Rest of the DAMS
====================

Rochkind makes a very good point:

>  Having a local development team requires resources and perhaps some organizational cultural changes to properly involve technical decision-makers in technical decisions.

Discovery and Avalon are currently totally unrelated to Jupiter, and the decisions to use the technologies they use were made, broadly, without any input from experienced software developers. That's going to need to be rectified if the projects the development team has been handed responsibility _for_ are going to be able to be maintained properly over the long run. The current approach of structuring these as completely separate products, relying on completely disparate technologies being picked by people completely disconnected from the development team, is dysfunctional in its decision-making and results.

To be blunt, short of hiring nine developers and splitting them into 3 separate teams, maintaining 3 entirely separate and unrelated high-importance applications is going to be impossible over the long-haul. At any given time, 2 of the 3 are going to fall into a state of significant neglect, and developers are going to be stuck "in the middle" of competing stakeholders all arguing that their requirements are the most important. Unrealistic deadlines being imposed from above in order to "free up developers" to make progress on some other application are a symptom of this reality.

My experience has shown that efficiently sharing developer resources across applications  _requires_ efficiently sharing their work between applications, and that implies _trusting developers to use their knowledge and experience to make technical decisions themselves based on a comprehensive set of requirements_, as they are the only ones in a position to effectively judge what can and can't be shared to meet the needs of the stakeholders. Everyone else is merely blindly guessing.

With that said, here's what I'd do with Discovery & Avalon over the medium term to consolidate work and make this situation more maintainable:

Discovery
---------

I'd look at splitting the search-related files out of Jupiter and into their own gem, along with some of the views for /search, and start a separate Rails app using that gem (resist any urges to make one Rails app do EVERYTHING; building out separate apps with shared infrastructure will scale better). This is honestly a very small application, and once good requirements are finally fleshed out this should not take very long at all to build out -- almost everything Discovery needs is literally already done in Jupiter.

Once Sean has gathered sufficient requirements, rebuilding a cleaner ingest pipeline can be pursued together or separately with this -- ingest and web presentation should be decoupled as separate projects. Building a DSL on top of Traject that would allow catalogue librarians to exert some influence over ingest directly, without needing to bottleneck their needs through a developer, would probably prove very fruitful. An ingest pipeline that needs a lot of day-to-day attention from a developer for routine changes is going to be a costly time-sink.

Avalon
-------

If there's no appetite for pursuing "Avarax" (and, again, that would likely require its own set of full-time development resources), I'd suggest just adding the active-encode gem directly to Jupiter and using https://github.com/video-dev/hls.js/ or some other JS client on the front-end. To be honest, though, if the only concern is preservation of the master file and not the derivatives, I'd _STRONGLY_ suggest that people sit down and have some hard conversations about whether it is worth the cost and effort of owning, operating, and maintaining bespoke streaming infrastructure vs just uploading a copy of the master file to Amazon Elastic Transcode (or Zencloud, or tokbox or...) and then streaming the derivatives out of cloudfront or some other CDN.

This would reduce scaling difficulties and server maintenance costs almost completely, many of these services support keeping the data in Canada if necessary, you would still be able to restrict the content to whatever audiences are required (there are many, many tutorials on doing so) and this functionality could probably be added to Jupiter NOW, in less time than it took Chris to port Avalon 5 to 6. Going this route, I think the entire is maybe a couple of sprints of work max for someone who knows what they're doing with basic Rails and Sidekiq -- it will probably take longer to design and implement the upload forms and metadata model than make streaming work with a standard AWS setup).

Running the infrastructure seems like an effort and cost hole that provides no benefits and significantly increases both development time/cost and hosting complexity/sysadmin burden -- offloading the encoding and distribution would significantly decrease the ongoing workload Avalon places on both the development and sysadmin teams.

You could spin this up as a separate Rails application using a copy of the Jupiter codebase if it's politically necessary for some reason that these be separate "products", but I don't see any _technical_ need for "ERA but for video" to actually be a completely separate codebase soaking up a large chunk of developer time that doesn't benefit Jupiter, and vice versa. They're fundamentally almost the exact same thing.


Other random thoughts
======================

- Stick with GUIDs for primary keys on your items. Postgres handles this natively, and well. Switching to integers will
get you into trouble some years down the road as you digitize millions of records. Switching to NOIDs will slow things
down as all your primary key comparisons would require string comparisons. GUIDs are what you want. This is why I pushed so hard for using them in Jupiter phase 1.

- When it comes to big architectural or infrastructure decisions, get developers in on the process early and let them use their experience and expertise to _help you make the right decisions_. If there's a lack of Rails knowledge here, consider hiring consultants (particularly, non-DCE-style library world consultants. Seek the advice of professionals outside the bubble!) for short periods, to give you feedback on big architectural plans. A day spent sitting down and talking to an experienced developer with a solid Rails background outside of the Library community, to get feedback on Hydra and Fedora-based solutions, might have saved years of pain.
