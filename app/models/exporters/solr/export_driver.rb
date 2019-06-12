class Exporters::Solr::ExportDriver
  def export(object)
    klass_name = object.class.name
    klass_sym = klass_name.to_sym
    @export_cache ||= {}

    return @export_cache[klass_sym] if @export_cache[klass_sym].present?

    @export_cache[object] = begin
      exporter_klass_name = "Exporters::Solr::#{klass_name}Exporter"
      exporter_klass_name.constantize
    rescue NameError
      raise Exporters::NoSuchExporter, "Exporter #{exporter_klass_name} is not defined for #{klass_name}"
    end
  end
end
