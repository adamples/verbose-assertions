= VerboseAssertions

== example.rb

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
    #   assert(a) ( (a) ? (1) : ( printf ("%s:%d: %s(): assertion failed (%s).\n", \
    #     __FILE__, __LINE__, __FUNCTION__, #a), 0) )
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
        # even whole loops, as they return value too.
        assert_equal(
    
          "Jakis\") tekst".kind_of?(
              10.class.name.class
            ),
          # Some (comment "string"
          123
        )
      end
    
    
      # In this example we use even more complex syntax, but it aims to show other
      # thing. Statements below can be described in Ruby in more than one way. For
      # example strings can be denoted using apostrophes or quotation marks. If you
      # run this test, you will see, that syntax used in exception message differs
      # from original code (this can be considered as another limitation or a feature
      # of library).
      def test_3
        assert_equal(
          %w[warsaw berlin paris budapest].select { |c| c.index('i').nil? },
          ['warsaw', 'budapest'].collect do |c|
            c.capitalize
          end
        )
      end
    
    end
    
    
    # To keep code dry, logic that runs tests automagicly is not included. Instead
    # run method is invoked directly.
    ExampleTestCase.run

== lib/test/verbose_unit/test_case.rb

    require 'test/verbose_unit/assertions'
    
    
    module Test
      module VerboseUnit
    
    
        # Here is simpliest possible base class for unit testing. It includes module
        # with assertions and defines one method, used to run testing methods.
        class TestCase
    
          include Assertions
    
    
          # Run method enumerates instance methods of a class and runs those
          # named test*; for each invocation a new object is created. Failure of
          # assertion is passed as exception from that method -- all we need to do
          # is to print message and backtrace. This means, that message must be
          # created inside assertion method, where exception is thrown. Definition
          # of those methods can be found in Assertions module.
          def self.run
    
            # Get instance methods named test*
            methods = self.instance_methods.select do |m|
              m.to_s.index("test") == 0
            end
    
            # For each test method:
            #   - create new object
            #   - call setup
            #   - call test method
            #   - call teardown
            #   - call cleanup
            methods.each do |m|
              instance = self.new
    
              begin
                instance.setup if instance.respond_to?(:setup)
                instance.send(m)
                instance.teardown if instance.respond_to?(:teardown)
              rescue AssertionFailedError => e
                puts
                puts "Assertion failed in `#{instance.class.name}##{m}'"
                puts e.message
                puts "backtrace:"
                puts e.backtrace.join("\n")
              ensure
                instance.cleanup if instance.respond_to?(:cleanup)
              end
            end
          end
    
        end
    
    
      end # module VerboseUnit
    end # module Test

== lib/test/verbose_unit/assertions.rb

    require 'rubygems'
    require "bundler/setup"
    require 'ruby_parser'
    require 'ruby2ruby'
    require 'test/verbose_unit/assertion_failed_error'
    
    
    module Test
      module VerboseUnit
    
    
        # Assertions module is where all the magick is hidden. It contains only one
        # assertion: #assert_equal, which is not very complicated by itself.
        module Assertions
    
          public
    
          # This method compares its arguments using standard == operator. Operands
          # order is the same as params in method invocation.
          #
          # @param a  first operand of comparison
          # @param b  second operand of comparison
          # @raise AssertionFailedException   if comparison evaluates as false
          def assert_equal(a, b)
            # Here you can see it with your own eyes:
            if a == b
            else
              # When assertion fails, try to get code for arguments. This task is
              # delegated to another method, in case we may want to write more
              # assertions.
              args = get_arguments_code
    
              # Something *may* go wrong. Always. Especially with this sort of code.
              # In that case we rely on our method returning nil and fallback to
              # usual message.
              if args.nil? || args.size != 2
                # Prepared backtrace is provided for exception object to not include
                # following line as source of an error, but rather line where
                # assertion was called from.
                raise AssertionFailedError.new("#{a.inspect} != #{b.inspect}", caller)
              else
                # But when everything is ok, args should contain code of two arguments,
                # and we still can provide their values as additional information.
                raise AssertionFailedError.new("#{args[0]} != #{args[1]}\nwhere:\n" +
                  "\t#{args[0]} = #{a.inspect}\n" +
                  "\t#{args[1]} = #{b.inspect}\n",
                caller)
              end
            end
          end
    
    
          protected
    
          # Returns code of arguments of calling method as an array of strings. When
          # fails to find this data, returns nil.
          #
          # Hic sunt leones
          #
          # @return [Array]   code of arguments of calling method or nil in case of
          #   failure.
          def get_arguments_code
    
            # Stack trace certainly will be useful.
            stack_trace = caller
    
            # First of all, calling method name will be needed. It's simply parsed
            # from stack trace using regexp.
            method = stack_trace[0].match(/:in `(.*)'/)[1]
    
            # Going deeper, file path and line, where previous method was called are
            # parsed.
            t = stack_trace[1].match(/([^:]+):(\d+):/)
            path = t[1]
            line_number = t[2].to_i
    
            # Read the file
            lines = []
    
            begin
              File.open(path, "r") do |io|
                lines = io.readlines
              end
            rescue Errno::ENOENT => e
              # May this file not exist at all? I don't know, but it will be foolish
              # to assume, that if I don't know, it cannot happen.
              return nil
            rescue IOError
              # This can happen always for several reasons
              return nil
            end
    
            # Now some folklore. It happens that the most widely used Ruby
            # implementation has bug in implementation of Kernel#caller. If method
            # invocation takes more than one line, instead of line where the name
            # of method was, we get one of the following lines (I suspect that it's
            # always the one with first argument, but dont know exactly).
            #
            # As workaround we go up the file until we find line containing method
            # name.
            #
            # Another digression: what if one of the lines contain method name which
            # is not its invocation, eg. inside string or comment? Well, then all
            # this will fail, and you get "false != true". It is a limitation, but
            # I can live with that.
            i = line_number - 1
    
            while i > 0 && lines[i].index(method).nil?
              i -= 1
            end
    
            # Code to search is crated as invocation line and all following code.
            # First line is trimmed to begin with method name.
            #
            # After that part of code from begin is moved to anther variable and
            # removed from code itself. This part will be called _fragment_.
            #
            # Initial fragment contains method name and opening bracket, eg:
            #
            #   | fragment  | code                                  |
            #   assert_equal(arg1, arg2)\n# Some comment in next line
            code = lines[i..-1].join
            start = code.index(method)
            fragment = code[start, method.length + 1]
            code = code[(start + method.length + 1)..-1]
    
            sexp = nil
    
            # Now in loop we check if fragment contains valid (parsable) Ruby code.
            # Syntax error in code cause exception to be thrown. In that case, we just
            # add another char from code to fragment and check again, until success
            # or and of code.
            code.each_char do |ch|
              begin
                parser = RubyParser.new
                sexp = parser.process(fragment)
                break
              rescue Exception => e
                fragment += ch
              end
            end
    
            # Code ended, but invocation cannot be parsed. Again: can this actually
            # happen?
            return nil if sexp.nil?
    
            # Parsed code results in structure called s-expression (sexps). It has
            # a tree-like structure that describes Ruby code and thus can be turned
            # into code again (+ all the whitespace will be removed).
            ruby2ruby = Ruby2Ruby.new
            result = []
    
            sexp[3].each_with_index do |arg, i|
              next if i == 0
              result << ruby2ruby.process(arg)
            end
    
            # Here we can return array of source code strings
            return result
          end
    
        end # module Assertions
    
    
      end # module VerboseUnit
    end # module Test

== lib/test/verbose_unit/assertion_failed_error.rb

    module Test
      module VerboseUnit
    
    
        # This class faciliate two tasks for us:
        #   - allows us to distinguish VerboseUnit exception from other exceptions,
        #   - lets us create an exception with custom backtrace in one line.
        class AssertionFailedError < Exception
    
          # Constructor sets message and stack trace for exception
          # @param [String] message     human-readable message explaining cause of exception
          # @param [Array] stack_trace  backtrace for exception
          def initialize(message, stack_trace)
            super(message)
            set_backtrace(stack_trace)
          end
    
        end
    
    
      end # module VerboseUnit
    end # module Test

== test/test_assertions.rb

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
