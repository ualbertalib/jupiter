RdfAnnotation.create!([
  {table: "active_storage_blobs", column: "filename", predicate: "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#resourceFilename"},
  {table: "active_storage_blobs", column: "content_type", predicate: "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#hasMimeType"},
  {table: "active_storage_blobs", column: "byte_size", predicate: "http://www.loc.gov/premis/rdf/v1#hasSize"},
  {table: "active_storage_blobs", column: "checksum", predicate: "http://www.loc.gov/premis/rdf/v1#hasMessageDigest"},
  {table: "items", column: "title", predicate: "http://purl.org/dc/terms/title"},
  {table: "items", column: "fedora3_uuid", predicate: "http://terms.library.ualberta.ca/fedora3UUID"},
  {table: "items", column: "depositor", predicate: "http://terms.library.ualberta.ca/depositor"},
  {table: "items", column: "alternative_title", predicate: "http://purl.org/dc/terms/alternative"},
  {table: "items", column: "doi", predicate: "http://prismstandard.org/namespaces/basic/3.0/doi"},
  {table: "items", column: "embargo_end_date", predicate: "http://purl.org/dc/terms/available"},
  {table: "items", column: "fedora3_handle", predicate: "http://terms.library.ualberta.ca/fedora3Handle"},
  {table: "items", column: "ingest_batch", predicate: "http://terms.library.ualberta.ca/ingestBatch"},
  {table: "items", column: "northern_north_america_filename", predicate: "http://terms.library.ualberta.ca/nnaFile"},
  {table: "items", column: "northern_north_america_item_id", predicate: "http://terms.library.ualberta.ca/nnaItem"},
  {table: "items", column: "rights", predicate: "http://purl.org/dc/elements/1.1/rights"},
  {table: "items", column: "sort_year", predicate: "http://terms.library.ualberta.ca/sortYear"},
  {table: "items", column: "visibility", predicate: "http://purl.org/dc/terms/accessRights"},
  {table: "items", column: "visibility_after_embargo", predicate: "http://projecthydra.org/ns/auth/acl#visibilityAfterEmbargo"},
  {table: "items", column: "embargo_history", predicate: "http://projecthydra.org/ns/auth/acl#embargoHistory"},
  {table: "items", column: "is_version_of", predicate: "http://purl.org/dc/terms/isVersionOf"},
  {table: "items", column: "member_of_paths", predicate: "http://terms.library.ualberta.ca/path"},
  {table: "items", column: "subject", predicate: "http://purl.org/dc/elements/1.1/subject"},
  {table: "items", column: "contributors", predicate: "http://purl.org/dc/elements/1.1/contributor"},
  {table: "items", column: "created", predicate: "http://purl.org/dc/terms/created"},
  {table: "items", column: "temporal_subjects", predicate: "http://purl.org/dc/terms/temporal"},
  {table: "items", column: "spatial_subjects", predicate: "http://purl.org/dc/terms/spatial"},
  {table: "items", column: "description", predicate: "http://purl.org/dc/terms/description"},
  {table: "items", column: "publisher", predicate: "http://purl.org/dc/terms/publisher"},
  {table: "items", column: "languages", predicate: "http://purl.org/dc/terms/language"},
  {table: "items", column: "license", predicate: "http://purl.org/dc/terms/license"},
  {table: "items", column: "item_type", predicate: "http://purl.org/dc/terms/type"},
  {table: "items", column: "source", predicate: "http://purl.org/dc/terms/source"},
  {table: "items", column: "related_link", predicate: "http://purl.org/dc/terms/relation"},
  {table: "items", column: "publication_status", predicate: "http://purl.org/ontology/bibo/status"},
  {table: "theses", column: "title", predicate: "http://purl.org/dc/terms/title"},
  {table: "theses", column: "fedora3_uuid", predicate: "http://terms.library.ualberta.ca/fedora3UUID"},
  {table: "theses", column: "depositor", predicate: "http://terms.library.ualberta.ca/depositor"},
  {table: "theses", column: "alternative_title", predicate: "http://purl.org/dc/terms/alternative"},
  {table: "theses", column: "doi", predicate: "http://prismstandard.org/namespaces/basic/3.0/doi"},
  {table: "theses", column: "embargo_end_date", predicate: "http://purl.org/dc/terms/available"},
  {table: "theses", column: "fedora3_handle", predicate: "http://terms.library.ualberta.ca/fedora3Handle"},
  {table: "theses", column: "ingest_batch", predicate: "http://terms.library.ualberta.ca/ingestBatch"},
  {table: "theses", column: "northern_north_america_filename", predicate: "http://terms.library.ualberta.ca/nnaFile"},
  {table: "theses", column: "northern_north_america_item_id", predicate: "http://terms.library.ualberta.ca/nnaItem"},
  {table: "theses", column: "rights", predicate: "http://purl.org/dc/elements/1.1/rights"},
  {table: "theses", column: "sort_year", predicate: "http://terms.library.ualberta.ca/sortYear"},
  {table: "theses", column: "visibility", predicate: "http://purl.org/dc/terms/accessRights"},
  {table: "theses", column: "visibility_after_embargo", predicate: "http://projecthydra.org/ns/auth/acl#visibilityAfterEmbargo"},
  {table: "theses", column: "embargo_history", predicate: "http://projecthydra.org/ns/auth/acl#embargoHistory"},
  {table: "theses", column: "is_version_of", predicate: "http://purl.org/dc/terms/isVersionOf"},
  {table: "theses", column: "member_of_paths", predicate: "http://terms.library.ualberta.ca/path"},
  {table: "theses", column: "subject", predicate: "http://purl.org/dc/elements/1.1/subject"},
  {table: "theses", column: "abstract", predicate: "http://purl.org/dc/terms/abstract"},
  {table: "theses", column: "language", predicate: "http://purl.org/dc/terms/language"},
  {table: "theses", column: "date_accepted", predicate: "http://purl.org/dc/terms/dateAccepted"},
  {table: "theses", column: "date_submitted", predicate: "http://purl.org/dc/terms/dateSubmitted"},
  {table: "theses", column: "degree", predicate: "http://purl.org/ontology/bibo/degree"},
  {table: "theses", column: "institution", predicate: "http://ontoware.org/swrc/ontology#institution"},
  {table: "theses", column: "dissertant", predicate: "http://terms.library.ualberta.ca/dissertant"},
  {table: "theses", column: "graduation_date", predicate: "http://terms.library.ualberta.ca/graduationDate"},
  {table: "theses", column: "thesis_level", predicate: "http://terms.library.ualberta.ca/thesisLevel"},
  {table: "theses", column: "proquest", predicate: "http://terms.library.ualberta.ca/proquest"},
  {table: "theses", column: "unicorn", predicate: "http://terms.library.ualberta.ca/unicorn"},
  {table: "theses", column: "specialization", predicate: "http://terms.library.ualberta.ca/specialization"},
  {table: "theses", column: "committee_members", predicate: "http://terms.library.ualberta.ca/commiteeMember"},
  {table: "collections", column: "title", predicate: "http://purl.org/dc/terms/title"},
  {table: "theses", column: "departments", predicate: "http://terms.library.ualberta.ca/department"},
  {table: "collections", column: "fedora3_uuid", predicate: "http://terms.library.ualberta.ca/fedora3UUID"},
  {table: "collections", column: "depositor", predicate: "http://terms.library.ualberta.ca/depositor"},
  {table: "collections", column: "community_id", predicate: "http://terms.library.ualberta.ca/path"},
  {table: "collections", column: "description", predicate: "http://purl.org/dc/terms/description"},
  {table: "collections", column: "restricted", predicate: "http://terms.library.ualberta.ca/restrictedCollection"},
  {table: "collections", column: "creators", predicate: "http://purl.org/dc/terms/creator"},
  {table: "collections", column: "visibility", predicate: "http://purl.org/dc/terms/accessRights"},
  {table: "communities", column: "title", predicate: "http://purl.org/dc/terms/title"},
  {table: "communities", column: "fedora3_uuid", predicate: "http://terms.library.ualberta.ca/fedora3UUID"},
  {table: "communities", column: "depositor", predicate: "http://terms.library.ualberta.ca/depositor"},
  {table: "communities", column: "description", predicate: "http://purl.org/dc/terms/description"},
  {table: "communities", column: "creators", predicate: "http://purl.org/dc/terms/creator"},
  {table: "communities", column: "visibility", predicate: "http://purl.org/dc/terms/accessRights"},
  {table: "items", column: "creators", predicate: "http://purl.org/dc/elements/1.1/creator"},
  {table: "items", column: "hydra_noid", predicate: "http://terms.library.ualberta.ca/hydraNoid"},
  {table: "theses", column: "hydra_noid", predicate: "http://terms.library.ualberta.ca/hydraNoid"},
  {table: "collections", column: "hydra_noid", predicate: "http://terms.library.ualberta.ca/hydraNoid"},
  {table: "communities", column: "hydra_noid", predicate: "http://terms.library.ualberta.ca/hydraNoid"},
  {table: "items", column: "date_ingested", predicate: "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#dateIngested"},
  {table: "items", column: "record_created_at", predicate: "http://terms.library.ualberta.ca/recordCreatedInJupiter"},
  {table: "theses", column: "date_ingested", predicate: "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#dateIngested"},
  {table: "theses", column: "record_created_at", predicate: "http://terms.library.ualberta.ca/recordCreatedInJupiter"},
  {table: "collections", column: "date_ingested", predicate: "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#dateIngested"},
  {table: "collections", column: "record_created_at", predicate: "http://terms.library.ualberta.ca/recordCreatedInJupiter"},
  {table: "communities", column: "date_ingested", predicate: "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#dateIngested"},
  {table: "communities", column: "record_created_at", predicate: "http://terms.library.ualberta.ca/recordCreatedInJupiter"},
  {table: "theses", column: "supervisors", predicate: "http://terms.library.ualberta.ca/supervisor"},
  {table: "digitization_books", column: "dates_issued", predicate: "http://purl.org/dc/terms/issued"},
  {table: "digitization_books", column: "temporal_subjects", predicate: "http://schema.org/temporalCoverage"},
  {table: "digitization_books", column: "title", predicate: "http://purl.org/dc/terms/title"},
  {table: "digitization_books", column: "resource_type", predicate: "http://purl.org/dc/terms/type"},
  {table: "digitization_books", column: "genres", predicate: "http://www.europeana.eu/schemas/edm/hasType"},
  {table: "digitization_books", column: "languages", predicate: "http://purl.org/dc/terms/language"},
  {table: "digitization_books", column: "publishers", predicate: "http://id.loc.gov/vocabulary/relators/pbl"},
  {table: "digitization_books", column: "places_of_publication", predicate: "http://id.loc.gov/vocabulary/relators/pup"},
  {table: "digitization_books", column: "extent", predicate: "http://rdaregistry.info/Elements/u/P60550"},
  {table: "digitization_books", column: "notes", predicate: "http://www.w3.org/2004/02/skos/core#note"},
  {table: "digitization_books", column: "geographic_subjects", predicate: "http://purl.org/dc/elements/1.1/coverage"},
  {table: "digitization_books", column: "topical_subjects", predicate: "http://purl.org/dc/elements/1.1/subject"},
  {table: "digitization_books", column: "volume_label", predicate: "https://www.w3.org/TR/rdf-schema/#ch_label"},
  {table: "digitization_books", column: "date_ingested", predicate: "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#dateIngested"},
  {table: "digitization_books", column: "record_created_at", predicate: "http://terms.library.ualberta.ca/recordCreatedInJupiter"},
  {table: "digitization_newspapers", column: "date_ingested", predicate: "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#dateIngested"},
  {table: "digitization_newspapers", column: "record_created_at", predicate: "http://terms.library.ualberta.ca/recordCreatedInJupiter"},
  {table: "digitization_images", column: "date_ingested", predicate: "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#dateIngested"},
  {table: "digitization_images", column: "record_created_at", predicate: "http://terms.library.ualberta.ca/recordCreatedInJupiter"},
  {table: "digitization_maps", column: "date_ingested", predicate: "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#dateIngested"},
  {table: "digitization_maps", column: "record_created_at", predicate: "http://terms.library.ualberta.ca/recordCreatedInJupiter"},
  {table: "digitization_books", column: "alternative_titles", predicate: "http://purl.org/dc/terms/alternative"},
  {table: "digitization_books", column: "rights", predicate: "http://www.europeana.eu/schemas/edm/rights"},
  {table: "digitization_newspapers", column: "dates_issued", predicate: "http://purl.org/dc/terms/issued"},
  {table: "digitization_newspapers", column: "title", predicate: "http://purl.org/dc/terms/title"},
  {table: "digitization_newspapers", column: "alternative_titles", predicate: "http://purl.org/dc/terms/alternative"},
  {table: "digitization_newspapers", column: "resource_type", predicate: "http://purl.org/dc/terms/type"},
  {table: "digitization_newspapers", column: "genres", predicate: "http://www.europeana.eu/schemas/edm/hasType"},
  {table: "digitization_newspapers", column: "languages", predicate: "http://purl.org/dc/terms/language"},
  {table: "digitization_newspapers", column: "places_of_publication", predicate: "http://id.loc.gov/vocabulary/relators/pup"},
  {table: "digitization_newspapers", column: "extent", predicate: "http://rdaregistry.info/Elements/u/P60550"},
  {table: "digitization_newspapers", column: "notes", predicate: "http://www.w3.org/2004/02/skos/core#note"},
  {table: "digitization_newspapers", column: "geographic_subjects", predicate: "http://purl.org/dc/elements/1.1/coverage"},
  {table: "digitization_newspapers", column: "rights", predicate: "http://www.europeana.eu/schemas/edm/rights"},
  {table: "digitization_newspapers", column: "volume", predicate: "http://purl.org/ontology/bibo/volume"},
  {table: "digitization_newspapers", column: "issue", predicate: "http://purl.org/ontology/bibo/issue"},
  {table: "digitization_newspapers", column: "editions", predicate: "http://id.loc.gov/ontologies/bibframe/editionStatement"}
])
