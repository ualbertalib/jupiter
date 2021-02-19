require 'test_helper'

class VocabularyTest < ActiveSupport::TestCase

  test 'should validate that [namespace, vocab, uri] is unique'

  test 'should validate that [namespace, vocab, code] is unique'

  test 'should lookup preferred label from graph of URI and use it to set code'

  test 'should set i18n translation on creation'

end
