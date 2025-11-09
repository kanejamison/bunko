===============================================================================

Bunko has been installed!

Next steps:

1. Run the migrations:

   $ rails db:migrate

2. (Optional) Customize your post types in config/initializers/bunko.rb

   The default is just "Blog", but you can add more:

   config.post_types = [
     { name: "Blog", slug: "blog" },
     { name: "Documentation", slug: "docs" },
     { name: "Changelog", slug: "changelog" }
   ]

3. Run the setup task to create your post types:

   $ rails bunko:setup

   This reads your config/initializers/bunko.rb and creates the PostTypes.
   Safe to re-run if you add more types later!

4. Create your first post (Rails console or admin panel):

   blog_type = PostType.find_by(slug: "blog")
   Post.create!(
     title: "Welcome to Bunko",
     content: "Your first blog post!",
     post_type: blog_type,
     status: "published",
     published_at: Time.current
   )

5. Start your server and visit:

   http://localhost:3000/blog

Want to add more collections? Just create a controller and routes:

   # app/controllers/docs_controller.rb
   class DocsController < ApplicationController
     bunko_collection :docs, per_page: 20
   end

   # config/routes.rb
   resources :docs, only: [:index, :show], param: :slug

Need help? Check out the documentation at:
https://github.com/kanejamison/bunko

===============================================================================
