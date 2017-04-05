if defined?(::NewRelic)
  Correios.class_eval do
    include ::NewRelic::Agent::MethodTracer
    add_method_tracer :quote
  end

  Intelipost.class_eval do
    include ::NewRelic::Agent::MethodTracer
    add_method_tracer :quote
  end

  Quotations.class_eval do
    include ::NewRelic::Agent::MethodTracer
    add_method_tracer :to_a
  end

  PackageQuotations.class_eval do
    include ::NewRelic::Agent::MethodTracer
    add_method_tracer :to_h
  end

  ZipCodeLocation.class_eval do
    class << self
      include ::NewRelic::Agent::MethodTracer

      add_method_tracer :get_geolocation_for
      add_method_tracer :try_to_create_new_location
    end
  end
end
