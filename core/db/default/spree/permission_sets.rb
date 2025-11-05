# frozen_string_literal: true

files = []

Spree::Core::Engine.root.join('app', 'models', 'spree', 'permission_sets', '**', '*.rb').tap do |path|
  files += Dir.glob(path.to_s)
end

if defined?(SolidusLegacyPromotions)
  SolidusLegacyPromotions::Engine.root.join('app', 'models', 'spree', 'permission_sets', '**', '*.rb').tap do |path|
    files += Dir.glob(path.to_s)
  end
end

if defined?(SolidusPromotions)
  SolidusPromotions::Engine.root.join('app', 'models', 'solidus_promotions', 'permission_sets', '**', '*.rb').tap do |path|
    files += Dir.glob(path.to_s)
  end
end

files.each do |file|
  require file
end

Spree::PermissionSets::Base.subclasses.each do |permission|
  Spree::PermissionSet.create!(
    name: permission.name.demodulize,
    set: permission.name,
    privilege: permission.privilege,
    category: permission.category
  )
end
