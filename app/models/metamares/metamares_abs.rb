class MetamaresAbs < ActiveRecord::Base

  self.abstract_class = true
  #establish_connection :metamares  # Descomentar si esta base se encuentra en otro servidor

end