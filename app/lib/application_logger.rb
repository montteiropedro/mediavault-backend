module ApplicationLogger
  class << self
    def info(message, location:, context: {})
      Rails.logger.info "[INFO] #{format_log(message, location:, context:)}"
    end

    def warn(message, location:, context: {})
      Rails.logger.warn "[WARN] #{format_log(message, location:, context:)}"
    end

    def error(exception, location:, context: {})
      error_string = [
        "[ERROR]",
        format_log(exception.message, location:, context: { error: exception.class }.merge(context)),
        format_backtrace(exception.backtrace).presence
      ].compact.join(" ")

      Rails.logger.error error_string
    end

    private

    def format_log(message, location:, context:)
      [Time.current, "location=#{location}", format_context(context).presence]
        .compact.join(" ") + ": #{message}"
    end

    def format_context(context)
      return if context.blank?

      context.map { |key, value| "#{key}=#{value}" }.join(" ")
    end

    def format_backtrace(backtrace)
      return if backtrace.blank?

      "\n [BACKTRACE]" + backtrace.first(15).join("\n  ")
    end
  end
end
