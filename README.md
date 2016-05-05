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

```
require 'iteraptor'
require 'iteraptor/greedy' # to patch Array and Hash
```

`Iteraptor` is intended to be used for iteration of complex nested structures.
The yielder is being called with two parameters: “current key” and “current value.”
The key is an index (converted to string for convenience) of an element for any
`Enumerable` save for `Hash`.

Nested `Enumerable`s are called with a compound key, represented as a “breadcrumb,”
which is a path to current key, joined with `Iteraptor::DELIMITER` constant. The
latter is just a dot in current release.

### Iteration

`Iteraptor#cada` iterates all the `Enumerable` elements, recursively. As it meets
the `Enumerable`, it yields it and then iterates items through.

```ruby
λ = ->(parent, element) { puts "#{parent} » #{element.inspect}" }

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

## Examples

#### Find and report all empty values:

```ruby
▶ hash = {a: true, b: {c: '', d: 42}, e: ''}
#⇒ {:a=>true, :b=>{:c=>"", :d=>42}, :e=>""}
▶ hash.cada { |k, v| puts "#{k} has an empty value" if v == '' }
#⇒ b.c has an empty value
#⇒ e has an empty value
```

#### Filter keys, that meet a condition:

In the example below we yield all keys, that matches the regexp given as parameter.

```ruby
▶ hash.segar(/[abc]/) { |parent, elem| puts "Parent: #{parent.inspect}, Element: #{elem.inspect}" }
# Parent: "a", Element: true
# Parent: "b", Element: {:c=>"", :d=>42}
# Parent: "b.c", Element: ""
# Parent: "b.d", Element: 42

#⇒ {"a"=>true, "b"=>{:c=>"", :d=>42}, "b.c"=>"", "b.d"=>42}
```

#### Change all empty values in a hash to `'N/A'`:

```ruby
▶ hash = {a: true, b: {c: '', d: 42}, e: ''}
#⇒ {:a=>true, :b=>{:c=>"", :d=>42}, :e=>""}
▶ hash.mapa { |parent, (k, v)| [k, v == '' ? v = 'N/A' : v] }
#⇒ {:a=>true, :b=>{:c=>"N/A", :d=>42}, :e=>"N/A"}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/iteraptor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
