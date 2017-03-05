module Request
  def json_halt(code = 400, errors = 'bad request')
    halt code, json(errors: errors)
  end

  def logger
    return request.logger if respond_to? :request
    require 'logger'
    Logger.new(STDOUT)
  end
end
