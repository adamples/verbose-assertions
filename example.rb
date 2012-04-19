$:.unshift("./lib")

require 'test/verbose_unit'


# Basic problem with test/unit and test-unit frameworks for Ruby which this code
# tries to address is that:
#
#   assert(checkSomething())
#
# results in most helpful message like this:
#
#   <false> is not <true>
#
# Of course libraries enable us to pass additional message as last parameter
# of assertion, but that's not very convinient. In fact it's not convinient
# at all. And as we consider ourselves lazy (but in a good way!) we just need
# to spent few hours to find a solution -- code that will generate more
# appropriate error messages.
#
# In C we could do something like this:
#
#   assert(a) ( (a) ? (1) : ( printf ("%s:%d: %s(): assertion failed (%s).\n", __FILE__, __LINE__, __FUNCTION__, #a), 0) )
#
# Preprocessor will replace #a with actual *code* that we passed to macro, eg.
#
#   assert(2 * 2 == 5)
#
# Will produce output:
#
#   file.c:44: function(): assertion failed(2 * 2 == 5).
#
# Now we know what is wrong at a glance. But we cannot simply apply this approach
# to Ruby, unless we use some custom preprocessor -- typical ruby interpreter from
# typical ruby installation has no preprocessor.
#
# On the other hand Ruby is interpreted language. Source files can be accessed
# from code like any other files. Actually Ruby always passes IO handler to actual
# file as global constant (__DATA__). So why not in case of failed assertion just
# open file which called it and read params list?
#
# This simple idea does have some problems, but we will talk them later. For now
# we will just define interface that we *want* to use. To find out how it works
# proceed to Test::VerboseUnit::TestCase class documentation.
#
# Code of following class should be familiar to everyone, who have ever had any
# interaction with unit testing frameworks in Ruby. It inherits some base class
# from framework, which usually provides assertion methods and some magic/logic
# that runs tests.
#
# Our work is to define test methods.
class ExampleTestCase < Test::VerboseUnit::TestCase


  # Test method is identified by its name (beginning with "test" string).
  def test_1
    # Here we do some calulcations; usually we use some library that we want
    # to test
    b = 0
    1000000.times do
      b += 0.000004
    end

    # And here we test is result is correct. Two expressions are passed to
    # assertion method. If it fails (and it will), we expect error message in
    # following hair:
    #
    #   assert_equal failed in test_1!
    #   2 * 2 != b
    #     2 * 2 = 4
    #     b = 3.9999...
    #   backtrace follows...
    assert_equal(Math.exp(Math.log(4)), b)
  end


  # This method in turn will do assertion with somewhat more complex invocation
  def test_2
    # This assertion arguments contain many syntax structures that are hard
    # to parse without actual ruby parser, eg. strings and comments with brackets,
    # event whole loops, as they return value too.
    assert_equal(

      "Jakis\") tekst".kind_of?(
          Fixnum
        ),
      # Some (comment "string"
      123
    )
  end


end


# To keep code dry, logic that runs tests automagicly is not included. Instead
# run method is invoked directly.
ExampleTestCase.run
