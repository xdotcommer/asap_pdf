module ApplicationHelper
  def safe_url(url)
    uri = URI.parse(url.strip)
    return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
