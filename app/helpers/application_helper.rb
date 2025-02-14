module ApplicationHelper
  def document_source(source)
    return {text: "", url: nil} unless source

    # Store original URL
    url = source.strip

    # Format the display text
    # Remove protocol and domain, keep path
    path = source.sub(%r{^https?://[^/]+/}, "")
    # Remove trailing slash if present
    path = path.sub(/\/$/, "")
    # Replace forward slashes with arrow
    text = path.gsub("/", " ▸ ")

    {text: text, url: url}
  end

  def safe_url(url)
    uri = URI.parse(url.strip)
    return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
