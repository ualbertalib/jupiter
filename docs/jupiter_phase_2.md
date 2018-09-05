The Path Forward
================

 There are fundamental problems with Fedora that are never going to make
it an appropriate datastore for a web application (https://groups.google.com/d/msg/samvera-tech/47pFj9lzkkQ/S1oUQs1CAwAJ)
ActiveFedora seems to be falling out of support with many of the major contributors now working on Valkyrie.

The writing is on the wall: Fedora is dead, and transitioning sooner rather than later seems smarter. The more data
gets thrown in Fedora, the more painful the inevitable switch is going to be down the road. In its current state
I would anticipate being forced off of Fedora in less than 5 years (I think Geoff once said something about all of these
systems having a very short lifespan, but respectfully, I completely disagree -- there's no reason the libraries shouldn't
be aiming to get 10-20 years out of a single well-maintained DAMs project. The failure of all systems this far to
survive even half that long is merely the direct and inevitable consequence of the technical immaturity of the library
ecosystem generally and the inexperience of the people making critical infrastructure and design decisions)

I think the temptation, especially with me gone, will be to look heavily towards Valkyrie as an "easy" path on
to Postgresql. My advice is to resist this temptation at all costs. It will not make the transition any easier
(everything that needs to be rewritten in this plan would need to be rewritten for Valkyrie anyways), and Valkyrie
has almost all of the same downsides as ActiveFedora -- you cannot hire anyone who knows it, it will seem completely
alien to anyone you do hire, it locks you out of a huge chunk of the Rails and Ruby ecosystem. In short it simply solves
no problems you actually have. It is another example of the community overengineering something bespoke and specific
to libraries when they should be looking to get out of that ghetto.

Everything in jupiter_core is intended to work such that there are only a few places in the application
that interact directly with ActiveFedora:

  - Inside LockedLdpObject itself.
  - Inside `unlocked do ... end` blocks in models
  - Inside `unlock_and_fetch_ldp_object` blocks generally

We need not worry about the first case as all, as it only exists to paper over defiiciencies in ActiveFedora.
If we're moving to ActiveRecord, we should remove it entirely in favour of ActiveRecord::Base

Prior to transitioning, the later two should be audited for anything particular dependent on ActiveFedora semantics.
A lot of what's in them should be completely compatible with ActiveRecord eg) validations and other supporting logic.

The main thrust of work will actually be in creating new ways of representing attribute-predicate relationships,
in altering the models to fit these new patterns, and in migrating the data itself into a new RDBMS.

The key to moving forward is to get away from the idea that the way data is stored for the web application needs to
look anything like the way it is represented for metadata purposes, or for distribution to other institutions, or for
distribution over the world wide web.

if I have seen one common theme across a lot of places over time it is that, while tempting,

 STORING DATA IN EXPORT FORMATS IS ALWAYS, _ALWAYS_ A MISTAKE

Store data for Jupiter in a way that makes sense for web applications. Follow the Pushmi-Pullyu model and create
different, single-purpose projects to move and transform this data to other systems. PMPY should continue to
transform the data and move it into preservation; a separate new project should be created to transform and move
data to a triplestore for metadata consumption, and yet another separate new project should be created to
transform and distribute the data for OAI. Avoid creating swiss-army knife projects, like datastores that are also
webservers that also handle OAI that also etc. This is very fragile and will not adapt well to changes over time.

Here's my thoughts on how you should do that:

- Create more-or-less completely standard Rails models for all of the existing things: Items, Theses, Collections, Communities.
Good news! We've secretely already been doing this with DraftItem and DraftThesis -- you should be able to rename these to Item and Thesis and simply add a column to indicate Draft state.
The one thing that databases aren't necessarily great at is representing arrays of values for a given column, but we've solved that in DraftItems
with json columns to represent arrays of values. This seems flexible enough to cover most cases.

- create a separate mechanism for tracking predicate information IN postgresql. My proposal is a Predicates table
consisting simply of:

id | predicate URI
===================
1  | http://purl.org/dc/terms/title
2  | ....

etc (with each URI appearing only once) and a separate Predicate-Class join table

id | table_name | column_name | predicate_id
=============================================
1  | items      | title       | 1
2  | ... etc

This provides enough information to construct triples for export to a suitable format, stores predicate information
in the same place as the data itself, while retaining compatibility with normal ActiveRecord.

To integrate this with Rails, I envision the following:

Create a DSL for declaring predicates _in migrations_ rather than in models (this has always been an odd and unrails-y
place to put them, as it implies they're dynamically redeclarable, which they're not). Picturing something like:

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

With the method handling the insertions into the Predicates, and Predicate-Class tables

Other random thoughts:

- stick with GUIDs for primary keys on your items. Postgres handles this natively, and well. Switching to integers will
get you into trouble some years down the road as you digitize millions of records. Switching to NOIDs will slow things
down as all your primary key comparisons would require string comparisons. GUIDs are what you want.

- consider hiring consultants (particularly, non-DCE style library world consultants. seek the advice of professionals
outside the bubble) to give you feedback on big architectural plans. A few hours spent getting feedback on Fedora-based solutions
from people with insights outside the Library world might have saved years of pain.
