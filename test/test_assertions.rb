$:.unshift("./lib")

require 'test/verbose_unit'
require 'test/unit'


class TestedTestCase < Test::VerboseUnit::TestCase
end


class AssertionsTestCase < Test::Unit::TestCase


  def setup
    @test_case = TestedTestCase.new
  end


  def cleanup
  end


  def equal_message(code_a, value_a, code_b, value_b)
<<EOS
#{code_a} != #{code_b}
where:
\t#{code_a} = #{value_a.inspect}
\t#{code_b} = #{value_b.inspect}
EOS
  end


  def test_equal_1
    assert_raise(Test::VerboseUnit::AssertionFailedError) do
      @test_case.assert_equal(true, false)
    end

    begin
      @test_case.assert_equal(true, false)
    rescue Test::VerboseUnit::AssertionFailedError => e
      expected_message = equal_message("true", true, "false", false)
      assert_equal(expected_message, e.message)
    end
  end


  def test_equal_2
    assert_raise(Test::VerboseUnit::AssertionFailedError) do
      @test_case.assert_equal(NilClass, Class)
    end

    begin
      @test_case.assert_equal(NilClass, Class)
    rescue Test::VerboseUnit::AssertionFailedError => e
      expected_message = equal_message("NilClass", NilClass, "Class", Class)
      assert_equal(expected_message, e.message)
    end
  end


  def test_equal_3
    assert_raise(Test::VerboseUnit::AssertionFailedError) do
      @test_case.assert_equal(
        Math::PI,
        3.14
      )
    end

    begin
      @test_case.assert_equal(
        Math::PI,
        3.14
      )
    rescue Test::VerboseUnit::AssertionFailedError => e
      expected_message = equal_message("Math::PI", Math::PI, "3.14", 3.14)
      assert_equal(expected_message, e.message)
    end
  end


  def test_equal_4
    assert_raise(Test::VerboseUnit::AssertionFailedError) do
      @test_case.assert_equal(
        # This test checks if additional tokens, like comments doesn't have
        # negative impact on library operation.
        Math::PI,
=begin
  Antoher multi-
  line comment
=end
        3.14
      )
    end

    begin
      @test_case.assert_equal(
        # This test checks if additional tokens, like comments doesn't have
        # negative impact on library operation.
        Math::PI,
=begin
  Antoher multi-
  line comment
=end
        3.14
      )
    rescue Test::VerboseUnit::AssertionFailedError => e
      expected_message = equal_message("Math::PI", Math::PI, "3.14", 3.14)
      assert_equal(expected_message, e.message)
    end
  end


  def test_equal_5
    assert_raise(Test::VerboseUnit::AssertionFailedError) do
      @test_case.assert_equal(
        %w[warsaw berlin paris budapest].select { |c| c.index('i').nil? },
        ['warsaw', 'budapest'].collect do |c|
          c.capitalize
        end
      )
    end

    begin
      @test_case.assert_equal(
        %w[warsaw berlin paris budapest].select { |c| c.index('i').nil? },
        ['warsaw', 'budapest'].collect do |c|
          c.capitalize
        end
      )
    rescue Test::VerboseUnit::AssertionFailedError => e
      expected_message = equal_message(
        "[\"warsaw\", \"berlin\", \"paris\", \"budapest\"].select { |c| c.index(\"i\").nil? }",
        %w[warsaw berlin paris budapest].select { |c| c.index("i").nil? },
        "[\"warsaw\", \"budapest\"].collect { |c| c.capitalize }",
        ['warsaw', 'budapest'].collect do |c|
          c.capitalize
        end
      )
      assert_equal(expected_message, e.message)
    end
  end


end
