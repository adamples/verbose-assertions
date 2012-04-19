$:.unshift("./lib")

require 'test/verbose_unit'


class SpecificTest < Test::VerboseUnit::TestCase



  def testcase_1
    b = 0
    1000000.times do
      b += 0.000004
    end

    assert_equal(2 * 2, b)
  end


  def testcase_2
    assert_equal(

      "Jakis\") tekst".kind_of?(Fixnum),
      # Some comment
      123
    )
  end


end


SpecificTest.run
