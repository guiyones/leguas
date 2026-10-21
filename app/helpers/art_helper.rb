module ArtHelper
  ROOT = Rails.root.join("app/assets/images/art")

  def art_tag(kind, key, label:, size: nil, **options)
    if art_path_for(kind, key).exist?
      image_tag "art/#{kind}/#{key}.svg", alt: label, role: ("img" if label.present?), width: size, height: size, **options
    else
      raise ArgumentError, "arte não existe: art/#{kind}/#{key}.svg"
    end
  end

  def art_path_for(kind, key)
    ROOT.join(kind.to_s, "#{key}.svg")
  end
end
