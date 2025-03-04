module SecurityLogger
  def self.log_attack(request, type, details)
    message = {
      type: type,
      ip: request.remote_ip,
      path: request.fullpath,
      method: request.method,
      user_agent: request.user_agent,
      details: details,
      timestamp: Time.current
    }
    
    Rails.logger.warn "SECURITY ALERT: #{message.to_json}"
  end
end
