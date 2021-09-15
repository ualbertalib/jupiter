require 'test_helper'

class Digitization::BatchMetadataIngestionJobTest < ActiveJob::TestCase

  setup do
    RdfAnnotation.create(table: :digitization_books, column: :dates_issued, predicate: ::RDF::Vocab::DC.issued)
    RdfAnnotation.create(table: :digitization_books, column: :temporal_subjects,
                         predicate: ::RDF::Vocab::SCHEMA.temporalCoverage)
    RdfAnnotation.create(table: :digitization_books, column: :title, predicate: ::RDF::Vocab::DC.title)
    RdfAnnotation.create(table: :digitization_books, column: :alternative_titles,
                         predicate: ::RDF::Vocab::DC.alternative)
    RdfAnnotation.create(table: :digitization_books, column: :resource_type, predicate: ::RDF::Vocab::DC.type)
    RdfAnnotation.create(table: :digitization_books, column: :genres, predicate: ::RDF::Vocab::EDM.hasType)
    RdfAnnotation.create(table: :digitization_books, column: :languages, predicate: ::RDF::Vocab::DC.language)
    RdfAnnotation.create(table: :digitization_books, column: :publishers, predicate: ::RDF::Vocab::MARCRelators.pbl)
    RdfAnnotation.create(table: :digitization_books, column: :places_of_publication,
                         predicate: ::RDF::Vocab::MARCRelators.pup)
    RdfAnnotation.create(table: :digitization_books, column: :extent, predicate: ::TERMS[:rdau].extent)
    RdfAnnotation.create(table: :digitization_books, column: :notes, predicate: ::RDF::Vocab::SKOS.note)
    RdfAnnotation.create(table: :digitization_books, column: :geographic_subjects,
                         predicate: ::RDF::Vocab::DC11.coverage)
    RdfAnnotation.create(table: :digitization_books, column: :rights, predicate: ::RDF::Vocab::EDM.rights)
    RdfAnnotation.create(table: :digitization_books, column: :topical_subjects, predicate: ::RDF::Vocab::DC11.subject)
  end

  test 'batch ingestion job captures exceptions and updates batch ingest model' do
    batch_ingest = digitization_batch_metadata_ingests(:digitization_batch_ingest_with_two_items)

    def batch_ingest.processing!
      raise StandardError, 'Testing! Error has happened!'
    end

    assert_raises StandardError do
      assert_no_difference('::Digitization::Book.count') do
        Digitization::BatchMetadataIngestionJob.perform_now(batch_ingest)
      end
    end

    assert(batch_ingest.failed?)
    assert_equal('Testing! Error has happened!', batch_ingest.error_message)
  end

  test 'successful batch ingestion' do
    batch_ingest = digitization_batch_metadata_ingests(:digitization_batch_ingest_with_two_items)
    batch_ingest.csvfile.attach(io: File.open(file_fixture('digitization_metadata_graph.csv')),
                                filename: 'folkfest.csv')

    assert_difference('::Digitization::Book.count', +2) do
      Digitization::BatchMetadataIngestionJob.perform_now(batch_ingest)
    end

    batch_ingest.reload
    assert(batch_ingest.completed?)
    assert_equal(2, batch_ingest.books.count)
  end

end
