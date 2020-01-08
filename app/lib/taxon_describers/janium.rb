module TaxonDescribers
  class Janium < Base

    def self.describer_name
      'Bioteca CONABIO'
    end

    def self.describe(taxon)
      if cat = taxon.present?
        name_to_find = taxon.id
        Rails.logger.debug "[DEBUG] JANIUM buscará #{name_to_find}"
        page = janium_service.search(name_to_find)
        page.text.blank? ? nil : page

      end
    end

    private
    def janium_service
      @janium_service=Janium_Service.new(:timeout => 20)
    end
  end
end
