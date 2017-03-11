module Request
  def json_halt(code = 400, errors = 'bad request')
    halt code, json(errors: errors)
  end

  def logger
    self.class.logger
  end
end
