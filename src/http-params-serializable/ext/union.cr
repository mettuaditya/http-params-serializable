# :nodoc:
struct Union(*T)
  def self.new(http_param value : String)
    {% if @type.nilable? %}
      return nil if value.empty?
    {% end %}

    {% for type in T %}
      {% unless type == Nil %}
        begin
          v = {{type}}.new(http_param: value)
          return v
        rescue ex : TypeCastError
        end
      {% end %}
    {% end %}

    raise TypeCastError.new
  end

  def self.new(http_param value : String, path : Tuple, converter : C = nil) : self forall C
    {%
      if T.all? { |t| t.annotation(HTTP::Params::Serializable::Scalar) || t == Nil }
        raise "Unions of scalar types must be initialized with a single value argument"
      end
    %}

    {% if @type.nilable? %}
      return nil if value.empty?
    {% end %}

    {% for type in T %}
      {% unless type == Nil %}
        begin
          # FIXME: For some reason `Time::EpochConverter` turns into `Time::EpochConverter:Module`
          {% converter = C.name.stringify.gsub(/:Module$/, "").id %}

          {% if converter != "Nil" %}
            {% if type < Array %}
              v = {{type}}.new(http_param: value, path: path, converter: {{converter}})
            {% else %}
              v = {{converter.id}}.from_http_param(value, path)
            {% end %}
          {% else %}
            v = {{type}}.new(http_param: value, path: path)
          {% end %}

          return v
        rescue ex : TypeCastError
        end
      {% end %}
    {% end %}

    raise TypeCastError.new
  end
end
