require 'logger'
module MagicLogger
  def logger
    if @_logger.nil?
      @_logger = Logger.new STDOUT
      @_logger.level = Logger.const_get((ENV['LOG_LEVEL'] || 'debug').upcase)
      @_logger.datetime_format = '%a %d-%m-%Y %H%M '
    end
    @_logger
  end
end
