# Coursemogy Migration
Migration script from Coursemology v1 to v2, still workign in progress.

## Usage
Add this line to the application's Gemfile:

```ruby
gem 'database_transform'
gem 'mysql2'
```

Add a new connection to the old database in `database.yml`.
```yaml
coursemology_v1:
  adapter: mysql2
  database: coursemology
  host: coursemology.org
```

Clone the files from this repo to Coursemology V2's app folder.

And then:
```sh
$ rake db:transform[coursemology_v1]
```

## Known Issues
- Auto graded coding questions does not work, unless manually upload a new package contains the programming files and test cases.
- S3 URLS in models are not parsed (V1 directly uploads things to S3 and put the raw url in the html description, this however need to be tracked in V2).
- Some columns/tables which does not implementated in V2 are droped (Like scribing questions and forum post votes).
