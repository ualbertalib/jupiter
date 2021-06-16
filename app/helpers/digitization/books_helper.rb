module Digitization::BooksHelper
  def language_search_link(book, language_uri)
    search_link_for(book, :languages, value: language_uri,
                                      display: humanize_uri(:digitization, :language, language_uri))
  end

  def subject_search_link(book, subject)
    search_link_for(book, :all_subjects, value: subject,
                                         display: humanize_uri_or_literal(:digitization, :subject, subject))
  end

  def creator_search_link(book, creator_uri)
    search_link_for(book, :publishers, value: creator_uri, display: humanize_uri(:digitization, :subject, creator_uri))
  end

  def rights_search_link(book)
    search_link_for(book, :rights, value: book.rights, display: humanize_uri(:digitization, :rights, book.rights))
  end

  def type_search_link(book)
    search_link_for(book, :resource_type, value: book.resource_type,
                                          display: humanize_uri(:digitization, :resource_type, book.resource_type))
  end

  def genre_search_link(book, genre_uri)
    search_link_for(book, :genres, value: genre_uri, display: humanize_uri(:digitization, :genre, genre_uri))
  end

  def place_of_publication_search_link(book, place_uri)
    search_link_for(book, :places_of_publication, value: place_uri,
                                                  display: humanize_uri(:digitization, :subject, place_uri))
  end
end
