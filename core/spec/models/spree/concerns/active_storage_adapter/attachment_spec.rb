# frozen_string_literal: true

require "rails_helper"

unless ENV["DISABLE_ACTIVE_STORAGE"] == "true"
  RSpec.describe Spree::ActiveStorageAdapter::Attachment do
    describe "#variant" do
      it "converts to resize_to_limit when definition doesn't contain any special symbol" do
        image = create(:image)

        attachment = described_class.new(image.attachment.attachment, styles: {mini: "10x10"})

        expect(
          attachment.variant(:mini).variation.transformations
        ).to include(resize_to_limit: [10, 10])
      end

      it "converts to resize_to_limit when definition ends with >" do
        image = create(:image)

        attachment = described_class.new(image.attachment.attachment, styles: {mini: "10x10>"})

        expect(
          attachment.variant(:mini).variation.transformations
        ).to include(resize_to_limit: [10, 10])
      end

      it "converts to resize_to_fill when definition ends with ^" do
        image = create(:image)

        attachment = described_class.new(image.attachment.attachment, styles: {mini: "10x10^"})

        expect(
          attachment.variant(:mini).variation.transformations
        ).to include(resize_to_fill: [10, 10])
      end

      it "strips definitions" do
        image = create(:image)

        attachment = described_class.new(image.attachment.attachment, styles: {mini: " 10x10 "})

        expect(
          attachment.variant(:mini).variation.transformations
        ).to include(resize_to_limit: [10, 10])
      end

      it "defaults to the image's width and height" do
        image = create(:image)

        attachment = described_class.new(image.attachment.attachment, styles: {})

        expect(
          attachment.variant(:mini).variation.transformations
        ).to include(resize_to_limit: [attachment.width, attachment.height])
      end

      context "with an animated image" do
        let(:animated_webp) do
          frames = [[255, 0, 0], [0, 255, 0], [0, 0, 255]].map do |rgb|
            Vips::Image.black(20, 20).new_from_image(rgb)
          end
          image = Vips::Image.arrayjoin(frames, across: 1).mutate do |mutable|
            mutable.set_type!(GObject::GINT_TYPE, "page-height", 20)
            mutable.set_type!(Vips::ARRAY_INT_TYPE, "delay", [100, 100, 100])
          end
          file = Tempfile.new(["animated", ".webp"])
          image.write_to_file(file.path)
          file
        end

        let(:image) { create(:image, attachment: File.open(animated_webp.path)) }

        before { stub_spree_preferences(allowed_image_mime_types: %w[image/webp]) }

        it "keeps all frames" do
          attachment = described_class.new(image.attachment.attachment, styles: {mini: "10x10"})

          variant = Vips::Image.new_from_buffer(attachment.variant(:mini).download, "", n: -1)

          expect(variant.get("n-pages")).to eq(3)
          expect(variant.get("page-height")).to eq(10)
        end

        it "does not load all frames with MiniMagick" do
          active_storage_attachment = image.attachment.attachment
          attachment = described_class.new(active_storage_attachment, styles: {mini: "10x10"})
          allow(ActiveStorage).to receive(:variant_processor).and_return(:mini_magick)

          expect(active_storage_attachment).to receive(:variant)
            .with(hash_excluding(:loader))
            .and_return(double(processed: nil))

          attachment.variant(:mini)
        end
      end

      it "does not change the variation of non-animatable images" do
        image = create(:image)

        attachment = described_class.new(image.attachment.attachment, styles: {mini: "10x10"})

        expect(attachment.variant(:mini).variation.transformations).not_to have_key(:loader)
      end
    end
  end
end
