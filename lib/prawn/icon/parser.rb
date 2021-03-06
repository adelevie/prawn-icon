# encoding: utf-8
#
# parser.rb: Prawn icon tag text parser (pseudo-HTML).
#
# Copyright October 2014, Jesse Doyle. All rights reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module Prawn
  class Icon
    # Provides the necessary methods to enable the parsing
    # of <icon> tags from input text.
    #
    # = Supported Tags:
    # <icon></icon>::
    #   Place an icon key between the tags and the output
    #   will be translated into: <font name="fa">unicode</font>.
    #
    # = Supported Attributes:
    #
    # Various attributes will be extracted from +<icon>+ tags:
    #
    # color::
    #   The hex representation of a color that the icon should
    #   be rendered as. If left nil, the document's fill color
    #   will be used.
    #
    # size::
    #   The font size of a particular icon. If left nil, the
    #   document's font size will be used.
    #
    class Parser
      PARSER_REGEX  = Regexp.new \
                      '<icon[^>]*>|</icon>',
                      Regexp::IGNORECASE |
                      Regexp::MULTILINE

      CONTENT_REGEX = /<icon[^>]*>(?<content>[^<]*)<\/icon>/mi

      TAG_REGEX     = /<icon[^>]*>[^<]*<\/icon>/mi

      class << self
        def format(document, string)
          tokens  = string.scan(PARSER_REGEX)
          config  = config_from_tokens(tokens)
          content = string.scan(CONTENT_REGEX).flatten
          icons   = keys_to_unicode(document, content, config)
          tags    = icon_tags(icons)

          string.gsub(TAG_REGEX).with_index do |_, i|
            tags[i]
          end
        end

        def config_from_tokens(tokens)
          array = []

          tokens.each do |token|
            # Skip the closing tag
            next if token =~ /<\/icon>/i

            icon = {}

            # TODO: Only support double quotes?
            size  = /size="([^"]*)"/i.match(token)
            color = /color="([^"]*)"/i.match(token)

            icon[:size]  = size[1].to_f if size
            icon[:color] = color[1] if color

            array << icon
          end

          array
        end

        def icon_tags(icons)
          tags = []

          icons.each do |icon|
            # Mandatory
            content = icon[:content]
            set     = icon[:set]

            # Optional
            color = icon[:color]
            size  = icon[:size]

            opening = "<font name=\"#{set}\""

            unless color || size
              tags  << "#{opening}>#{content}</font>"
              next
            end

            opening += " size=\"#{size}\"" if size
            content = "<color rgb=\"#{color}\">#{content}</color>" if color

            opening += '>'
            tags << "#{opening}#{content}</font>"
          end

          tags
        end

        def keys_to_unicode(document, content, config)
          icons = []

          content.each_with_index do |icon, index|
            options ||= {}
            options = config[index] if config.any?
            info = {
              set:     FontData.specifier_from_key(icon),
              size:    options[:size],
              color:   options[:color],
              content: FontData.unicode_from_key(document, icon)
            }
            icons << info
          end

          icons
        end
      end
    end
  end
end
