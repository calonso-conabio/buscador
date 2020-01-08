class Metamares::Dato < MetamaresAbs

  self.table_name = "#{CONFIG.bases.metamares}.datos"

  ESTATUS_DATOS = [:'1', :'2', :'3']
  CREATIVE_COMMONS = [:cc0, :cc_by, :cc_by_nc, :cc_by_sa, :cc_by_nd, :cc_by_nc_sa, :cc_by_nc_nd, :no_licence]

end