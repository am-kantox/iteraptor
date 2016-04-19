# Iteraptor

[![Build Status](https://travis-ci.org/am-kantox/iteraptor.svg?branch=master)](https://travis-ci.org/am-kantox/iteraptor)
This small mixin allows the deep iteration / mapping of `Enumerable`s instances.

Adopted to be used with hashes/arrays. It **is not** intended to be used with
large objects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'iteraptor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install iteraptor

## Usage



### Iteration

```ruby
λ = ->(parent, element) { puts ... }

[:a, b: {c: 42}].cada &λ
#⇒ 0 » :a
#⇒ 1 » {:b=>{:c=>42}}
#⇒ 1.b » {:c=>42}
#⇒ 1.b.c » 42

{a: 42, b: [:c, :d]}.cada &λ
#⇒ a » 42
#⇒ b » [:c, :d]
#⇒ b.0 » :c
#⇒ b.1 » :d
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/iteraptor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
