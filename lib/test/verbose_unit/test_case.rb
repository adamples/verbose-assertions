require 'test/verbose_unit/assertions'


module Test
  module VerboseUnit


    class TestCase

      include Assertions


      def self.run
        methods = self.instance_methods.select do |m|
          m.to_s.index("test") == 0
        end

        methods.each do |m|
          instance = self.new

          begin
            instance.setup if instance.respond_to?(:setup)
            instance.send(m)
            instance.teardown if instance.respond_to?(:teardown)
          rescue AssertionFailedError => e
            puts
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


  end # module VerboseUnit
end # module Test
