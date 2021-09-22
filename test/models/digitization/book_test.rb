require 'test_helper'

class Digitization::BookTest < ActiveSupport::TestCase

  setup do
    @document = digitization_books(:folk_fest)
  end

  test 'valid Peel book' do
    assert @document.valid?
    assert_equal 'P010572.1', @document.peel_number
  end

  test 'unique Peel book' do
    book = Digitization::Book.create(peel_id: '10572', part_number: '1')
    assert_not book.valid?
    assert_equal('has already been taken', book.errors[:peel_id].first)
  end

  test 'invalid Peel book without peel id' do
    @document.assign_attributes(peel_id: nil, run: nil, part_number: '1')
    assert_not @document.valid?
    assert_equal("can't be blank", @document.errors[:peel_id].first)
  end

  test 'invalid Peel book from a run' do
    @document.assign_attributes(peel_id: '4242', run: '1', part_number: nil)
    assert_not @document.valid?
    assert_equal("can't be blank", @document.errors[:part_number].first)
  end

  test 'valid Peel book from a run' do
    book = digitization_books(:henderson)
    assert book.valid?
    assert_equal 'P03178.1.1', book.peel_number
  end

  test 'should have at least one type of subject' do
    @document.assign_attributes(temporal_subjects: nil, geographic_subjects: nil, topical_subjects: nil)
    assert_not @document.valid?
    assert_equal("can't be blank", @document.errors[:temporal_subjects].first)
    assert_equal("can't be blank", @document.errors[:geographic_subjects].first)
    assert_equal("can't be blank", @document.errors[:topical_subjects].first)
  end

  test 'should have a title' do
    @document.assign_attributes(title: nil)
    assert_not @document.valid?
    assert_equal("can't be blank", @document.errors[:title].first)
  end

  test 'unknown resource types are not valid' do
    @document.assign_attributes(resource_type: 'some_fake_resource_type')
    assert_not @document.valid?
    assert_includes @document.errors[:resource_type], 'is not recognized'
  end

  test 'unknown genres are not valid' do
    @document.assign_attributes(genres: ['some_fake_genres'])
    assert_not @document.valid?
    assert_includes @document.errors[:genres], 'is not recognized'
  end

  test 'unknown languages are not valid' do
    @document.assign_attributes(languages: ['some_fake_language'])
    assert_not @document.valid?
    assert_includes @document.errors[:languages], 'is not recognized'
  end

  test 'unknown rights are not valid' do
    @document.assign_attributes(rights: 'some_fake_right')
    assert_not @document.valid?
    assert_includes @document.errors[:rights], 'is not recognized'
  end

  test 'dates must conform to EDTF format' do
    @document.assign_attributes(dates_issued: ['INVALID DATE'], temporal_subjects: ['INVALID DATE'])
    assert_not @document.valid?
    assert_equal('does not conform to the Extended Date/Time Format standard',
                 @document.errors[:temporal_subjects].first)
    assert_equal('does not conform to the Extended Date/Time Format standard', @document.errors[:dates_issued].first)
  end

  test 'retrieve fulltext' do
    assert_equal(
      'Quia aliquam non nostrum ab ad distinctio consequuntur sunt dignissimos eum quia quia nobis et impedit ex '\
      'deserunt facilis quidem sint quaerat id sit alias dolores consectetur ut officiis autem repudiandae ut '\
      'reiciendis sed qui quia quisquam eos libero voluptatem mollitia temporibus optio est et aperiam nesciunt '\
      'nostrum dignissimos sapiente quos non consequatur magni reprehenderit minus vero unde laborum tempora nihil '\
      'provident qui ducimus excepturi minus et deleniti delectus itaque rerum vel error beatae praesentium nisi '\
      'accusantium ut vel explicabo omnis minima cupiditate illo assumenda est sit aut necessitatibus est molestiae '\
      'sed quisquam commodi sunt iusto voluptatem adipisci error molestias est voluptatem veniam deleniti '\
      'reprehenderit dolor saepe voluptate autem culpa aut corrupti voluptas sit beatae sequi quasi aut qui quibusdam '\
      'omnis dolore accusantium nam fugiat harum possimus cumque numquam modi qui ut cupiditate voluptas dolorum '\
      'voluptas non eum ducimus repellendus quidem esse dolorem voluptatibus magni molestias ea sunt non veniam '\
      'inventore placeat neque ea harum sed aut iste quod dolore id incidunt commodi fugit accusamus corporis '\
      'voluptatem quia enim et molestiae blanditiis iure possimus illum et enim saepe consequatur cumque minima '\
      'necessitatibus voluptas hic et omnis consectetur dolor et ullam facere iusto suscipit quod non laudantium '\
      'asperiores eos at occaecati odit voluptates rerum aut ipsam cum animi amet voluptates pariatur qui et et '\
      'numquam ipsum voluptatem in aperiam iste ut qui tenetur doloremque delectus magnam quam et natus sint enim sed '\
      'exercitationem veritatis et est nulla fugit eaque labore voluptas placeat velit et dolores ratione dicta '\
      'debitis aliquid aliquam quia.', @document.fulltext.text
    )
  end

end
