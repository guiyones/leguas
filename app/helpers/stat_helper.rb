module StatHelper
  def stat(value, unit:, total: nil, prefix: nil, color: :gold)
    tag.p class: "stat" do
      safe_join [
        tag.span("#{prefix}#{format_number(value)}", class: "stat__value text-#{color}"),
        tag.span([ ("/ #{format_number(total)}" if total), unit ].compact.join(" "), class: "stat__unit")
      ], " "
    end
  end

  private
    def format_number(number)
      number_with_precision number, precision: 1, strip_insignificant_zeros: true
    end
end
