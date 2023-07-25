# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusFriendlyPromotions::ShippingRateDiscount do
  subject(:shipping_rate_discount) { build(:friendly_shipping_rate_discount) }

  it { is_expected.to respond_to(:shipping_rate) }
  it { is_expected.to respond_to(:promotion_action) }
  it { is_expected.to respond_to(:amount) }
  it { is_expected.to respond_to(:display_amount) }
  it { is_expected.to respond_to(:label) }
end
