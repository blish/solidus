# frozen_string_literal: true

require "mini_magick"

module Spree
  module ActiveStorageAdapter
    # Decorates ActiveStorage attachment to add methods expected by Solidus'
    # Paperclip-oriented attachment support.
    class Attachment
      ANIMATABLE_CONTENT_TYPES = %w[image/gif image/webp].freeze

      delegate_missing_to :@attachment

      attr_reader :attachment

      def initialize(attachment, styles: {})
        @attachment = attachment
        @transformations = styles_to_transformations(styles)
      end

      def exists?
        attached?
      end

      def filename
        blob&.filename.to_s
      end

      def url(style = nil)
        variant(style)&.url
      end

      def variant(style = nil)
        transformation = @transformations[style] || default_transformation(width, height)

        @attachment.variant({
          **loader_options,
          saver: {
            strip: true
          }
        }.merge(transformation)).processed
      end

      def height
        metadata[:height]
      end

      def width
        metadata[:width]
      end

      def destroy
        return false unless attached?

        purge
        true
      end

      private

      def metadata
        analyze unless analyzed?

        @attachment.metadata
      rescue ActiveStorage::FileNotFoundError => error
        logger.error("#{error} - Image id: #{attachment.record.id} is corrupted or cannot be found")

        {identified: nil, width: nil, height: nil, analyzed: true}
      end

      def styles_to_transformations(styles)
        styles.transform_values(&method(:imagemagick_to_image_processing_definition))
      end

      def imagemagick_to_image_processing_definition(definition)
        width_height = definition.split("x").map(&:to_i)

        case definition[-1].to_sym
        when :^
          {resize_to_fill: width_height}
        else
          default_transformation(*width_height)
        end
      end

      def default_transformation(width, height)
        {resize_to_limit: [width, height]}
      end

      # Vips only loads the first frame unless told otherwise. Limited to
      # animatable types, because any change to the transformations changes
      # the variant digest and would re-process every existing variant.
      def loader_options
        return {} unless ActiveStorage.variant_processor == :vips
        return {} unless content_type.in?(ANIMATABLE_CONTENT_TYPES)

        {loader: {n: -1}}
      end
    end
  end
end
