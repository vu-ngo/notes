require 'test/unit'
require 'notes'

class NotesTest < Test::Unit::TestCase
  def test_english_hello
    assert_equal "hello world",
      Notes.hi("english")
  end

  def test_any_hello
    assert_equal "hello world",
      Notes.hi("ruby")
  end

  def test_spanish_hello
    assert_equal "hola mundo",
      Notes.hi("spanish")
  end
end
