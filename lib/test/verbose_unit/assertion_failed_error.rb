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
