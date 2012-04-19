require 'rubygems'
require 'awesome_print'

require './2b'


class Test


  def self.run
    methods = self.instance_methods.select do |m|
      m.to_s.index("testcase") == 0
    end

    methods.each do |m|
      instance = self.new

      begin
        instance.setup if instance.respond_to?(:setup)
        instance.send(m)
        instance.teardown if instance.respond_to?(:teardown)
      rescue AssertionFailedError => e
        puts "Assertion failed in `#{m}'"
        puts e.message
        puts "backtrace:"
        puts e.backtrace.join("\n")
      ensure
        instance.cleanup if instance.respond_to?(:cleanup)
      end
    end
  end


end


class SpecificTest < Test

  include Assertions


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

#puts text_between_brackets("asdf (zaczyna sie (w srodku) koniec) asdfasd")

