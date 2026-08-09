module ApplicationLogger
  class << self
    def error(exception, location:, context: {})
      Rails.logger.error <<~LOG
        [ERROR] #{Time.current}
        | Location: #{location}
        | Error: #{exception.class}
        | Message: #{exception.message}
        | Context: #{format_context(context)}
        | Backtrace: #{format_backtrace(exception.backtrace)}
        -
      LOG
    end

    private

    def format_context(context)
      return "-" if context.blank?

      context.map { |key, value| "#{key}=#{value}" }.join(", ")
    end

    def format_backtrace(backtrace)
      return "-" if backtrace.blank?

      "\n" + backtrace.join("\n|  ")
    end
  end
end
