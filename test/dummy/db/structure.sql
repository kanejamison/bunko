CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "post_types" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "title" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_post_types_on_name" ON "post_types" ("name");
CREATE TABLE IF NOT EXISTS "posts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "title" varchar NOT NULL, "slug" varchar NOT NULL, "content" text, "post_type_id" integer NOT NULL, "status" varchar DEFAULT 'draft' NOT NULL, "published_at" datetime(6), "title_tag" varchar, "meta_description" text, "word_count" integer, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_809bc8b296"
FOREIGN KEY ("post_type_id")
  REFERENCES "post_types" ("id")
);
CREATE INDEX "index_posts_on_post_type_id" ON "posts" ("post_type_id");
CREATE INDEX "index_posts_on_slug" ON "posts" ("slug");
CREATE INDEX "index_posts_on_status" ON "posts" ("status");
CREATE INDEX "index_posts_on_published_at" ON "posts" ("published_at");
CREATE UNIQUE INDEX "index_posts_on_post_type_id_and_slug" ON "posts" ("post_type_id", "slug");
INSERT INTO "schema_migrations" (version) VALUES
('20250101000002'),
('20250101000001');

