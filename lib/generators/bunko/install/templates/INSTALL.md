===============================================================================

Bunko has been installed!

Migrations, models, and initializer have been created.

Next steps:

1. (Optional) Customize your post types in config/initializers/bunko.rb

   We've configured "Blog" for you, but you can change that or add more:

   config.post_types = [
     { name: "Blog", slug: "blog" },
     { name: "Documentation", slug: "docs" },
     { name: "Changelog", slug: "changelog" }
   ]

2. Run the migrations:

   $ rails db:migrate

3. Run the setup task:

   $ rails bunko:setup

   This will:
   - Create PostTypes from your config
   - Generate controllers for each post type
   - Generate views (index, show) for each post type
   - Add routes for each post type

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

Want to add more collections later?
   1. Add the post type to config/initializers/bunko.rb
   2. Run either:
      - rails bunko:setup[product]  (set up just the new "product" collection)
      - rails bunko:setup           (set up all collections, safe to re-run unless you delete any setup files on other models)
   3. Done! Controllers, views, and routes are generated automatically.

Need help? Check out the documentation at:
https://github.com/kanejamison/bunko

===============================================================================
