require 'rubygems'
require 'ruby_parser'
require 'ruby2ruby'
require 'test/verbose_unit/assertion_failed_error'


module Test
  module VerboseUnit


    module Assertions

      def get_arguments_code
        stack_trace = caller

        method = stack_trace[0].match(/:in `(.*)'/)[1]

        t = stack_trace[1].match(/([^:]+):(\d+):/)
        path = t[1]
        line_number = t[2].to_i

        lines = []

        begin
          File.open(path, "r") do |io|
            lines = io.readlines
          end
        rescue Errno::ENOENT => e
          return nil
        rescue IOError
          return nil
        end

        i = line_number - 1

        while i > 0 && lines[i].index(method).nil?
          i -= 1
        end

        code = lines[i..-1].join
        start = code.index(method)
        fragment = code[start, method.length + 1]
        code = code[(start + method.length + 1)..-1]

        sexp = nil

        code.each_char do |ch|
          begin
            parser = RubyParser.new
            sexp = parser.process(fragment)
            break
          rescue Exception => e
            fragment += ch
          end
        end

        return nil if sexp.nil?

        ruby2ruby = Ruby2Ruby.new
        result = []

        sexp[3].each_with_index do |arg, i|
          next if i == 0
          result << ruby2ruby.process(arg)
        end

        return result
      end


      def assert_equal(a, b)
        if a != b
          stack_trace = caller
          args = get_arguments_code

          if args.nil?
            raise AssertionFailedError.new("#{a.inspect} != #{b.inspect}", stack_trace)
          else
            raise AssertionFailedError.new("#{args[0]} != #{args[1]}\nwhere:\n" +
              "\t#{args[0]} = #{a.inspect}\n" +
              "\t#{args[1]} = #{b.inspect}\n",
            stack_trace)
          end
        end
      end

    end # module Assertions


  end # module VerboseUnit
end # module Test
