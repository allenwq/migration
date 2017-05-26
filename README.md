# Coursemogy Migration
Migration script from Coursemology v1 to v2.

## Usage
Add this line to the application's Gemfile:

```ruby
gem 'mysql2'
```

Add a new connection to the old database in `database.yml`.
```yaml
v1:
  adapter: mysql2
  database: coursemology
  host: coursemology.org
```

Clone the files from this repo to Coursemology V2's app folder.

And then:
```sh
$ rake migration:start
```

