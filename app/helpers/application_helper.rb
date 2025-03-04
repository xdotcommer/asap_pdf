module ApplicationHelper
  def document_source(source)
    return {text: "", url: nil} unless source

    # Store original URL
    url = source.strip

    # Format the display text
    begin
      uri = URI.parse(url)
      # Get just the path component, remove leading/trailing slashes
      path = uri.path.sub(/^\//, "").sub(/\/$/, "")
      # If there's no path, use the host (domain)
      text = if path.blank?
        url
      else
        path.gsub("/", " ▸ ")
      end
    rescue URI::InvalidURIError
      text = ""
    end

    {text: text, url: url}
  end

  def format_metadata(value)
    value.presence || "—"
  end

  def short_number(number)
    number_to_human(number, format: "%n%u", units: {thousand: "k", million: "M", billion: "B"})
  end

  def safe_url(url)
    uri = URI.parse(url.strip)
    return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
