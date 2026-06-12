# frozen_string_literal: true

module Bunko
  module Controllers
    module Collection
      extend ActiveSupport::Concern

      included do
        class_attribute :bunko_collection_name
        class_attribute :bunko_collection_options
      end

      class_methods do
        def bunko_collection(collection_name, **options)
          self.bunko_collection_name = collection_name.to_s
          self.bunko_collection_options = {
            per_page: 10,
            order: :published_at_desc
          }.merge(options)

          # Set layout if specified
          layout(options[:layout]) if options[:layout]

          # Define index and show actions
          define_method :index do
            load_collection
          end

          define_method :show do
            load_post
          end

          # Make helpers available
          helper_method :collection_name if respond_to?(:helper_method)
        end
      end

      private

      def load_collection
        @collection_name = bunko_collection_name

        # Smart lookup: Check PostType first, then Collection
        post_type_config = Bunko.configuration.find_post_type(@collection_name)
        collection_config = Bunko.configuration.find_collection(@collection_name)

        if post_type_config
          # Single PostType collection
          @post_type = PostType.find_by(name: @collection_name)
          unless @post_type
            bunko_not_found!("PostType '#{@collection_name}' not found in database. Run: rails bunko:setup[#{@collection_name}]")
          end

          base_query = post_model.published.by_post_type(@collection_name)
        elsif collection_config
          # Multi-type collection
          base_query = post_model.published.where(post_type: PostType.where(name: collection_config[:post_types]))

          # Apply collection scope if defined
          if collection_config[:scope]
            base_query = base_query.instance_exec(&collection_config[:scope])
          end
        else
          bunko_not_found!("Collection '#{@collection_name}' not found. Add it to config/initializers/bunko.rb")
        end

        # Apply ordering
        ordered_query = apply_ordering(base_query)

        # Apply pagination
        @posts = paginate(ordered_query)
        @pagination = pagination_metadata
      end

      def load_post
        @collection_name = bunko_collection_name

        # Smart lookup: Check PostType first, then Collection
        post_type_config = Bunko.configuration.find_post_type(@collection_name)
        collection_config = Bunko.configuration.find_collection(@collection_name)

        # Collections should not have show routes (posts are accessed via their canonical PostType URL)
        if collection_config
          bunko_not_found!("Posts in collection '#{@collection_name}' can only be accessed through their PostType URL. This collection only supports index.")
        end

        if post_type_config
          # Single PostType collection
          @post_type = PostType.find_by(name: @collection_name)
          unless @post_type
            bunko_not_found!("PostType '#{@collection_name}' not found in database. Run: rails bunko:setup[#{@collection_name}]")
          end

          base_query = post_model.published.by_post_type(@collection_name)
        else
          bunko_not_found!("Collection '#{@collection_name}' not found. Add it to config/initializers/bunko.rb")
        end

        # Find post by slug within this collection
        @post = base_query.find_by(slug: params[:slug])

        unless @post
          bunko_not_found!("Post with slug '#{params[:slug]}' not found in '#{@collection_name}'")
        end
      end

      # Raises a standard 404 so the host app's not-found handling applies.
      # The detailed reason is logged for developers but never sent to visitors,
      # since these messages reference internal setup commands and config paths.
      def bunko_not_found!(reason)
        Rails.logger.warn("[Bunko] #{reason}")
        raise ActiveRecord::RecordNotFound, reason
      end

      def post_model
        @post_model ||= Post
      end

      def apply_ordering(query)
        case bunko_collection_options[:order]
        when :published_at_desc
          query.reorder(published_at: :desc)
        when :published_at_asc
          query.reorder(published_at: :asc)
        when :created_at_desc
          query.reorder(created_at: :desc)
        when :created_at_asc
          query.reorder(created_at: :asc)
        else
          query
        end
      end

      def paginate(query)
        # to_s guards against non-scalar params (?page[]=1 arrives as an Array),
        # and clamping to total_pages keeps the OFFSET bounded by real data.
        per_page = [bunko_collection_options[:per_page].to_i, 1].max
        total_count = query.count
        total_pages = [(total_count.to_f / per_page).ceil, 1].max
        page_number = params[:page].to_s.to_i.clamp(1, total_pages)

        @_total_count = total_count
        @_current_page = page_number
        @_per_page = per_page

        query.limit(per_page).offset((page_number - 1) * per_page)
      end

      def pagination_metadata
        {
          current_page: @_current_page,
          per_page: @_per_page,
          total_count: @_total_count,
          total_pages: (@_total_count.to_f / @_per_page).ceil,
          prev_page: (@_current_page > 1) ? @_current_page - 1 : nil,
          next_page: (@_current_page < (@_total_count.to_f / @_per_page).ceil) ? @_current_page + 1 : nil
        }
      end

      def collection_name
        @collection_name
      end
    end
  end
end
