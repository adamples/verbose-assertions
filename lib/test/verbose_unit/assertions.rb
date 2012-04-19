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
