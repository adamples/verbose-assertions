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
