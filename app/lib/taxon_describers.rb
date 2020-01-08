module TaxonDescribers
  def self.describe(taxon, options = {})
    if options[:describer]
      txt = case options[:describer].to_s.downcase
              when "amphibiaweb" then TaxonDescribers::AmphibiaWeb.describe(taxon)
              when "eol" then TaxonDescribers::Eol.describe(taxon)
              when "eoles" then TaxonDescribers::EolEs.describe(taxon, :language => 'es')
              when "conabio" then TaxonDescribers::Conabio.describe(taxon)
              when "wikipedia" then TaxonDescribers::Wikipedia.describe(taxon)
              when "bhl" then TaxonDescribers::Bhl.describe(taxon)
              when "janium" then TaxonDescribers::Janium.describe(taxon)
            end
      return txt
    end
    describers = options[:describers]
    describers = [Wikipedia, Eol] if describers.blank?
    describers.each do |describer|
      text = describer.describe(taxon)
      return text unless text.blank?
    end
  end

  def self.get_describer(name)
    return nil if name.blank?
    TaxonDescribers::Base.descendants.detect do |d|
      class_name = d.name.split('::').last
      class_name.downcase == name.downcase || class_name.underscore == name
    end
  end
end
