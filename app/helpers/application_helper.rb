module ApplicationHelper
  def document_source(source)
    return "" unless source
    # Remove protocol and domain, keep path
    path = source.sub(%r{^https?://[^/]+/}, "")
    # Remove trailing slash if present
    path = path.sub(/\/$/, "")
    # Replace forward slashes with &raquo;
    path.gsub("/", " ▸ ") + " ▸ "
  end

  def safe_url(url)
    uri = URI.parse(url.strip)
    return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
