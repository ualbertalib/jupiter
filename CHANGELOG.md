# Changelog
All notable changes to Jupiter project will be documented in this file. Jupiter is a University of Alberta Library-based initiative to create a sustainable and extensible digital asset management system. Currently it is for phase 1 (Institutional Repository). https://era.library.ualberta.ca/.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and releases in Jupiter project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Added read only mode feature [#1838](https://github.com/ualbertalib/jupiter/issues/1838)

### Changed
- Enable Skylight in the Staging environment and remove it from the UAT environment (where it was unused, and the performance of the Docker environment is less likely to be similar to Production)
- uat configuration to accept proxy from upstream nginx-proxy [#1724](https://github.com/ualbertalib/jupiter/issues/1724)
- Changed oaisys' updated until scope [#1816](https://github.com/ualbertalib/jupiter/issues/1816)
- ActiveStorage::Blob now uses UUID for ids. You will need to recreate, remigrate, and reseed your DB.
- predeploy script to reference this branch

### Added
- script for watchtower to run from post-update hook [PR#1892](https://github.com/ualbertalib/jupiter/pull/1892)

### Fixed
- bump rubocop and fix cop violations [PR#1845](https://github.com/ualbertalib/jupiter/pull/1845)
- bump rubocop-performance and fix cop violations [PR#1850](https://github.com/ualbertalib/jupiter/pull/1850)
- N+1 query issue with attachments to models in search results [PR#1881](https://github.com/ualbertalib/jupiter/pull/1881)

### Security
- bump selfsigned CVE-2020-7720 

## [2.0.1.pre2] - 2020-09-01

### Added
- tmp/cache to docker ignore [#1680](https://github.com/ualbertalib/jupiter/issues/1680)
- Tie breaker for solr query results to make them deterministic [#1689](https://github.com/ualbertalib/jupiter/issues/1689)

### Changed
- Merge file_set and original_file AIP API entry points [#1557](https://github.com/ualbertalib/jupiter/issues/1557)
- Skipped failing Oaisys tests [#1817](https://github.com/ualbertalib/jupiter/issues/1817)
- webpacker resolved_paths to additional paths [#1836](https://github.com/ualbertalib/jupiter/issues/1836)
 
### Fixed
- Upgrade Rubocop/Erblint and fix cop violations [#1803](https://github.com/ualbertalib/jupiter/pull/1803)
- Fixed Oaisys testing issues by modifying and adding decorators [#1816](https://github.com/ualbertalib/jupiter/issues/1816)
- UAT nginx port 80 redirect [PR#1893](https://github.com/ualbertalib/jupiter/pull/1839)

## [2.0.1.pre1] - 2020-07-22

### Added
- Mounted Oaisys engine [PR#1361](https://github.com/ualbertalib/jupiter/pull/1361)
- Added tests surrounding Oaisys ListSets response [PR#1609](https://github.com/ualbertalib/jupiter/pull/1609)
- Version 1 of AIP API [PR#1441](https://github.com/ualbertalib/jupiter/pull/1441)
- Added and set up papertrail gem [PR#1437](https://github.com/ualbertalib/jupiter/pull/1437)
- Set up papertrail admin view [PR#1562](https://github.com/ualbertalib/jupiter/pull/1562)
- Added Draper and re-organized facet presenters [PR#1446](https://github.com/ualbertalib/jupiter/pull/1446)
- Metadata Presenters for OAI:DC & OAI:ETDMS [PR#1460](https://github.com/ualbertalib/jupiter/pull/1460)
- Local system accounts authentication [PR#1522](https://github.com/ualbertalib/jupiter/pull/1522)
- Bring in ERBLint [PR#1646](https://github.com/ualbertalib/jupiter/pull/1646)
- Thesis ingest rewrite [PR#1670](https://github.com/ualbertalib/jupiter/pull/1670)
- Rails 6 sidekiq queues [PR#1663](https://github.com/ualbertalib/jupiter/pull/1663)
- Add stylelint to Jupiter [#1120](https://github.com/ualbertalib/jupiter/issues/1120)
- migration to fix concatenated subjects (part 1) [#1449](https://github.com/ualbertalib/jupiter/issues/1449)
- fix bad logic on preservation errors

### Changed
- bump rubocop-rails to 2.4.1 Rails/FilePath default changed to slashes [PR#1398](https://github.com/ualbertalib/jupiter/pull/1398)
- Upgrade Rails gem to latest v6.x [#1430](https://github.com/ualbertalib/jupiter/issues/1430)
- Transition to Zeitwerk for Autoloading [#1432](https://github.com/ualbertalib/jupiter/issues/1432)
- Changed default docker setup and updated docker/docker-compose/travis/README [PR#1519](https://github.com/ualbertalib/jupiter/pull/1519)
- Changed thumbnail fallback to ERA logo without text instead of file icon [PR#1521](https://github.com/ualbertalib/jupiter/pull/1521)
- Description now optional for theses prior to 2009 [#1357](https://github.com/ualbertalib/jupiter/issues/1357)
- Transition to Webpacker from Sprockets [#1431](https://github.com/ualbertalib/jupiter/issues/1431)
- Post Fedora Automated Test Cleanup [#1445](https://github.com/ualbertalib/jupiter/issues/1445)
- Update UAL Logo [#1616](https://github.com/ualbertalib/jupiter/issues/1616)
- Refactor `inactive` draft cleanup rake task to be sidekiq cron job [#1611](https://github.com/ualbertalib/jupiter/issues/1611)
- Move Logic from SearchController into ItemSearch Concern [#932](https://github.com/ualbertalib/jupiter/issues/932)
- Feature Image on Item show page need to be centered align within column [#1405](https://github.com/ualbertalib/jupiter/issues/1405)
- Centralize Abstraction for Thumbnail Generation [#1343](https://github.com/ualbertalib/jupiter/issues/1343)
- Beefed up AR migrations by stating that certain attributes cannot be null [PR#1704](https://github.com/ualbertalib/jupiter/pull/1704)
- Finalize Item AIP data [#1557](https://github.com/ualbertalib/jupiter/issues/1557)
- Finalize Thesis AIP data [#1557](https://github.com/ualbertalib/jupiter/issues/1557)
- Change validations defined in models in favor of reusable validators

### Fixed
- failing tests [#1376](https://github.com/ualbertalib/jupiter/issues/1376)
- Fix Sprockets v4.0.0 upgrade problem with how Sass Variables were being defined [#1406](https://github.com/ualbertalib/jupiter/issues/1406)
- Fix bug for page_image_url helper which was double rendering urls for default image [PR#1512](https://github.com/ualbertalib/jupiter/pull/1512)
- Thumbnail choice no longer resets between saves [#1435](https://github.com/ualbertalib/jupiter/issues/1435)
- Fix three-state logic problems on DraftItem and DraftThesis models where boolean attribute is_published_in_era was nullable [#1408](https://github.com/ualbertalib/jupiter/issues/1408)
- Can now go through wizard with an old license [#1539](https://github.com/ualbertalib/jupiter/pull/1539)
- Fixed rake tasks [#1585](https://github.com/ualbertalib/jupiter/issues/1585)
- Style "Files" section as a card to keep consistent with rest of sidebar on item show page [#1676](https://github.com/ualbertalib/jupiter/issues/1676)
- Feature Images on Item show page are being styled as Thumbnails [#1675](https://github.com/ualbertalib/jupiter/issues/1675)
- Fix "This file is processing and will be available shortly [#1669](https://github.com/ualbertalib/jupiter/issues/1669)
- The tag method is used replacing the content_tag method which is now deprecated [#1706](https://github.com/ualbertalib/jupiter/issues/1706)
- Use #resize_to_limit instead of #resize for thumbnail/images in Jupiter [#1698](https://github.com/ualbertalib/jupiter/issues/1698)
- docker image can be built and deployed on UAT [#1680](https://github.com/ualbertalib/jupiter/issues/1680)

### Security
- add `noopener noreferrer` when opening a link in a new tab [PR#1344](https://github.com/ualbertalib/jupiter/pull/1344)

### Removed
- Removed Matomo analytic tracking [#1493](https://github.com/ualbertalib/jupiter/issues/1493)
- Cleanup all references of `is_published_in_era` and `drafts` scope on DraftItem/DraftThesis [#1614](https://github.com/ualbertalib/jupiter/issues/1614)

## [1.2.18] - 2019-10-22
- Removed Rack Attack

## [1.2.17] - 2019-09-24

### Security
- add omniauth-rails_csrf_protection gem and only use post requests to mitigate [CVE-2015-9284](https://nvd.nist.gov/vuln/detail/CVE-2015-9284) [PR#1221](https://github.com/ualbertalib/jupiter/pull/1221)

### Changed
- bump rubocop-performance from 1.4.0 to 1.4.1 and use match? instead of =~ [PR#1226](https://github.com/ualbertalib/jupiter/pull/1226)
- display graduation date in season year format [#1003](https://github.com/ualbertalib/jupiter/issues/1003)
- Improvement on rack-attack configuration [#1247](https://github.com/ualbertalib/jupiter/issues/1247)
- Lifting of embargo now stores item in embargo_history [#1219](https://github.com/ualbertalib/jupiter/issues/1219)
- bump ruby from 2.4 to 2.6 in travis jobs [#1214](https://github.com/ualbertalib/jupiter/issues/1214)
- Make supervisor and department facets to use existing functionality (requires reindex) [#1002](https://github.com/ualbertalib/jupiter/issues/1002)

### Fixed
- bump faker from 1.9.6 to 2.1.0 and fix breaking changes to dev seed data [PR#1231](https://github.com/ualbertalib/jupiter/pull/1231)
- allow batch ingest to lookup older licenses [#1115](https://github.com/ualbertalib/jupiter/issues/1115)
- Added selectize '|' delimiter to separate authors or subjects [#1211](https://github.com/ualbertalib/jupiter/issues/1211)

### Added
- Added javascript for thumbnail replacement on error [#1228](https://github.com/ualbertalib/jupiter/issues/1228)

## [1.2.16] - 2019-07-19

### Security
- bump mini_magick from 4.9.3 to 4.9.4 [PR#1212](https://github.com/ualbertalib/jupiter/pull/1212)

### Added
- initializer for fits characterization (configuration change) [#1215](https://github.com/ualbertalib/jupiter/issues/1215)

### Changed
- bump rubocop from 0.71.0 to 0.72.0 and add rubocop-rails gem [PR#1183](https://github.com/ualbertalib/jupiter/pull/1183)
- bump rubocop-rails from 2.1.0 to 2.2.1 and remove unnecessary disabling of Rails/TimeZone [PR#1205](https://github.com/ualbertalib/jupiter/pull/1205)

## [1.2.15] - 2019-06-26

### Security
- bump nokogiri from 1.10.2 to 1.10.3 [PR#1098](https://github.com/ualbertalib/jupiter/pull/1098)

### Added
- Ruby 2.5 to travis ci testing matrix [PR#1040](https://github.com/ualbertalib/jupiter/pull/1040)
- Added configuration for active storage to allow tifs to have a thumbnail [#991](https://github.com/ualbertalib/jupiter/issues/991)
- Added missing contoller tests [#865](https://github.com/ualbertalib/jupiter/issues/865)
- Dependency on ActsAsRdfable for annotating ActiveRecord classes with RDF predicates
- Collection, Community Item, and Thesis ActiveRecord models
- jupiter:get_me_off_of_fedora rake task to perform data migration
- drafts scope for DraftItem/DraftThesis

### Changed
- DeferredSimpleSolrQuery#sort renamed to 'order' and its two arguments replaced with a key-value, to better align with ActiveRecord
  API and ease removal of ActiveFedora.
- Change LockedLDPObject#find_by to take a named 'id:' parameter, to better align callers with ActiveRecord
- i18n fallback to english (configuration change) [PR#1058](https://github.com/ualbertalib/jupiter/pull/1058)
- pin rubocop version for hound [PR#1080](https://github.com/ualbertalib/jupiter/pull/1080)
- Skip flapping tests on travis CI [#1181](https://github.com/ualbertalib/jupiter/issues/1181)
- Replaced use of ActiveFedora's Solr connection with a direct connection to Solr setup locally.
- Made multiple seeds of db not duplicate types, languages, or institutions [#1117](https://github.com/ualbertalib/jupiter/issues/1117)
- Replaced all calls to `Solrizer.solr_name` with simplified local code to map Solr types/roles to wildcard stems.
- Removed Solrizer usage from the process of indexing ActiveFedora objects for Solr entirely. Replaced with Solr Exporter pattern for serialization of Solr data.
- DraftItem and DraftThesis have basic RDF annotations
- Removed: ActiveFedora
- Items, Theses, Collections, and Communities now have RDF predicates defined for their PostgreSQL columns via migration

### Fixed
- Cleared visibility_after_embargo and embargo_end_date when embargo option is not selected [PR#1041](https://github.com/ualbertalib/jupiter/pull/1041)
- fixed error in dangerfile [#1109](https://github.com/ualbertalib/jupiter/issues/1109)
- Fixed order-dependence in system tests regarding test data bleeding into other tests [#1286](https://github.com/ualbertalib/jupiter/issues/1286)

## [1.2.14] - 2019-04-15

### Added
- regression tests for downloading restricted items from search results [PR#1070](https://github.com/ualbertalib/jupiter/pull/1070)
- Added danger gem to project [#988](https://github.com/ualbertalib/jupiter/issues/998)
- Added rack-attack for rate limiting [#954](https://github.com/ualbertalib/jupiter/issues/954)

### Changed
- nginx configuration for docker-compose deployment (UAT, etc) so that active_storage/blobs are not served (configuration change) [PR#1081](https://github.com/ualbertalib/jupiter/pull/1081)

### Fixed
- use the download url helper on the search results page [PR#1079](https://github.com/ualbertalib/jupiter/pull/1079)

## [1.2.12] - 2019-04-05

### Fixed
- Addresses #1069 but without gem updates.

## [1.2.11] - 2019-04-05

### Fixed
- anonymous users should not be able to download ccid protected items from search results [#1069](https://github.com/ualbertalib/jupiter/issues/1069)

## [1.2.10] - 2019-03-14

### Security
- Bumps rails from 5.2.2 to 5.2.2.1. This update addresses [Two Vulnerabilities in Action View](https://weblog.rubyonrails.org/2019/3/13/Rails-4-2-5-1-5-1-6-2-have-been-released/). [PR#1042](https://github.com/ualbertalib/jupiter/pull/1042)

## [1.2.9] - 2019-03-08

### Added
-  Search supervisor and department from link [#1002](https://github.com/ualbertalib/jupiter/issues/1002)

### Changed
- Changed from Ruby Sass to sassc-railsis as Ruby Sass is deprecated and will be unmaintained as of 26 March 2019[#PR1032](https://github.com/ualbertalib/jupiter/pull/1032)

### Fixed
- [Faker Deprecations](https://github.com/stympy/faker/blob/master/CHANGELOG.md#deprecation-1) [PR#1019](https://github.com/ualbertalib/jupiter/pull/1019)

### Removed
- Removed workarounds for Datacite EZ API [PR#1030](https://github.com/ualbertalib/jupiter/pull/1030)

## [1.2.8] - 2019-01-27
### Added
- Add proper version file, meta generator tag and tool for managing releases [#55](https://github.com/ualbertalib/jupiter/issues/55)

### Fixed
- Fix wrong orientation in thumbnails for portrait mode images [PR#783](https://github.com/ualbertalib/jupiter/pull/783)
- workarounds for Datacite EZ API for tests [PR#945](https://github.com/ualbertalib/jupiter/pull/945)
- Fixed a firefox text overflow bug where filenames would overflow the file section sidebar [PR#980](https://github.com/ualbertalib/jupiter/pull/980)

### Changed
- Update to Bootstrap 4.2.1 [#683](https://github.com/ualbertalib/jupiter/issues/683)

## [1.2.7] - 2018-12-03
### Changed
- use Datacite EZ API for tests [#911](https://github.com/ualbertalib/jupiter/issues/911)
- proportions for portrait thumbnails [#661](https://github.com/ualbertalib/jupiter/issues/661)

### Security
- Bumps rails from 5.2.1 to 5.2.1.1. This update includes security fixes for ActiveStorage and ActiveJob. [PR#933](https://github.com/ualbertalib/jupiter/pull/933)

### Fixed
- Fix year limiter on collection item results [#931](https://github.com/ualbertalib/jupiter/pull/931)

## [1.2.6] - 2018-11-05
### Fixed
- can delete additional contributors [#830](https://github.com/ualbertalib/jupiter/issues/830)

## [1.2.5] - 2018-10-22
### Fixed
- Tuned SQL query for the gargage collection job to remove orphaned files [#888](https://github.com/ualbertalib/jupiter/issues/888)
- Fix time in sidekiq cron schedule, convert time to use UTC timezone (https://github.com/ualbertalib/jupiter/pull/892)
- fixes typo for conference paper item type [#879](https://github.com/ualbertalib/jupiter/issues/879)

## [1.2.4] - 2018-10-09
### Changed
- remove references to mbarnett properties [#868](https://github.com/ualbertalib/jupiter/issues/868)
- improvement on flagging tests [#875](https://github.com/ualbertalib/jupiter/pull/875)
- Security update: bump nokogiri from 1.8.4 to 1.8.5
- Multiple dependency updates


## [1.2.3] - 2018-09-19
### Fixed
- View object in the browser [PR#866](https://github.com/ualbertalib/jupiter/pull/866)
- Dependency for deployment of 1.2.0 in the release note.

## [1.2.2] - 2018-09-17
### Fixed
- Error handling and additional logging in data migration from Fedora to ActiveStorage [PR#860](https://github.com/ualbertalib/jupiter/pull/860)

## [1.2.1] - 2018-09-13
### Added
- Batch ingest with spreadsheet [#762](https://github.com/ualbertalib/jupiter/issues/762)

### Fixed
- `Conference Paper` Item Type should be mapped to `Conference/Workshop Presentation` instead [#789](https://github.com/ualbertalib/jupiter/issues/789)


## [1.2.0] - 2018-08-22
### Added
- Thesis deposit and edit for ERA administrators [#709](https://github.com/ualbertalib/jupiter/issues/709)
- Batch ingest with spreadsheet [#762](https://github.com/ualbertalib/jupiter/issues/762)

### Changed
- Main search results will sort by relevance by default [#693](https://github.com/ualbertalib/jupiter/issues/693)
- Deposit into Fedora is pushed into the background.

### Deployment notes:

- This release contains a significant data migration of data currently stored into Fedora onto the gluster storage. Serving files
to end users is now provided by Rails/ActiveStorage rather than through interacting with PCDM filesets.

  - For deployment, we will need to put both app servers into maintenance mode, and run the rake task `rake jupiter:migrate_filesets`, which will
    copy all existing files out of Jupiter and onto the Gluster. This is likely to take a SIGNIFICANT amount of time, and the app will not
    run properly until this is complete. We should thoroughly test this process on Staging, by doing a complete clone of Production
    Fedora and Solr back to the Staging environment, to get a feel for how long this will take in Production and catch any errors that
    may arise during this process before going live. It is possible, maybe even likely, that we may see Fedora lock up during this process,
    as it has never reacted particularly well to large numbers of downloads.

  - We will need to know the size of datastreams in Fedora to verify we have enough space provisioned on Gluster storage, plus headroom, as all deposits from now on
    will be stored in both Fedora (for preservation) and on the Gluster (for long term preservation)

  - One additional package needs to be added for ActiveStorage to server the PDF thumbnail is Poppler (Details [here](https://api.rubyonrails.org/v5.2/classes/ActiveStorage/Preview.html)). The package needs to be installed separately on application servers.

  - Starting with this release, new deposits will be uploaded to the gluster immediately, and then be ingested into Fedora in the background.
    This means we expect CPU usage and jobs processed on the sidekiq server to increase permanently to handle this new process.

  - Newly deposited items will initially show a 'This file is processing and will be available shortly' message in place of download link(s),
      until the background job has finished ingesting the file into Fedora. While we can revist this in the future, for the moment this is necessary
      as we require Fedora to finish ingesting the datastream and assign it an ID before we can provide a permanent URL for the file.

  - A new periodic task has been added to Jupiter to periodically delete unused, orphaned files from the gluster filesystem to prevent
    them from piling up endlessly. This is run automatically via schedule.yml queuing up a GarbageCollectBlobsJob every 12 hours.
    When necessary this can also be run manually by running the rake tast `rake jupiter:gc_blobs`

## [1.1.0] - 2018-06-25
### Added
- Embargo expiry job to remove elapsed embargoes from object [#526](https://github.com/ualbertalib/jupiter/issues/526)
- Upgrade to Rails 5.2 [#471](https://github.com/ualbertalib/jupiter/issues/471)
- Pushmi-Pullyu integration changes [#702](https://github.com/ualbertalib/jupiter/issues/702)
- Added Content Security Policy as part of the front end checklist [#562](https://github.com/ualbertalib/jupiter/issues/562)

## [1.0.0] - 2018-04-03
### Added
- Institutional Repository basic functions based on [IR Phase 1 Requirements](https://docs.google.com/spreadsheets/d/1fa4U_gZogMnG51YT0r3p1rAcGf3J-JPL8ziv8LyCKos/edit#gid=0)
