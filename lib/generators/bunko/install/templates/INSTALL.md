===============================================================================

Bunko has been installed!

Next steps:

1. Run the migrations:

   $ rails db:migrate

2. Create your first post type in the Rails console or seeds.rb:

   PostType.create!(name: "Blog", slug: "blog")

3. Create your first post:

   blog_type = PostType.find_by(slug: "blog")
   Post.create!(
     title: "Welcome to Bunko",
     content: "Your first blog post!",
     post_type: blog_type,
     status: "published",
     published_at: Time.current
   )

4. Start your server and visit:

   http://localhost:3000/blog

5. Optional: Add more collections by creating controllers and routes:

   # app/controllers/docs_controller.rb
   class DocsController < ApplicationController
     bunko_collection :docs, per_page: 20
   end

   # config/routes.rb
   resources :docs, only: [:index, :show], param: :slug

Need help? Check out the documentation at:
https://github.com/kanejamison/bunko

===============================================================================
