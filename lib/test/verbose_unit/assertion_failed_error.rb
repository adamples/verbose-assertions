module Test
  module VerboseUnit


    class AssertionFailedError < Exception

      def initialize(message, stack_trace)
        super(message)
        set_backtrace(stack_trace)
      end

    end


  end # module VerboseUnit
end # module Test
