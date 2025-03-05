module UrlDecodedAttributeHelper
  def url_decoded_attribute(attribute)
    define_method(attribute) do
      return nil if self[attribute].nil?
      CGI.unescape(self[attribute])
    end
  end
end
