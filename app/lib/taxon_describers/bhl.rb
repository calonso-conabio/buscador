module TaxonDescribers

  class Bhl < Base

    def self.describer_name
      'BHL'
    end

    def self.describe(taxon)

      url = "#{CONFIG.site_url}especies/#{taxon.id}/bhl"
      Rails.logger.debug "[DEBUG] Buscando con: #{url}"
      escaped_address = URI.escape(url)
      uri = URI.parse(escaped_address)
      Nokogiri::HTML(open(uri))
    end
  end
end