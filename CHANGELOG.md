# Changelog
All notable changes to Jupiter project will be documented in this file. Jupiter is a University of Alberta Libraries-based initiative to create a sustainable and extensible digital asset management system. Currently it is for phase 1 (Institutional Repository). https://era.library.ualberta.ca/.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and releases in Jupiter project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Make supervisor and department facets to use existing functionality (requires reindex) [#1002](https://github.com/ualbertalib/jupiter/issues/1002)

### Added
- Added danger gem to project [#988](https://github.com/ualbertalib/jupiter/issues/998)
- regression tests for downloading restricted items from search results [PR#1070](https://github.com/ualbertalib/jupiter/pull/1069)
- Added rack-attack for rate limiting [#954](https://github.com/ualbertalib/jupiter/issues/954)

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
