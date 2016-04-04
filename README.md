# Coursemogy Migration
Migration script from Coursemology v1 to v2.

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
- Some columns/tables which does not implementated in V2 are dropped (Like scribing questions).
