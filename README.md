# Iteraptor

This small mixin allows the deep iteration / mapping of `Enumerable`s instances.

[![Build Status](https://travis-ci.org/am-kantox/iteraptor.svg?branch=master)](https://travis-ci.org/am-kantox/iteraptor)
[![Code Climate](https://codeclimate.com/github/am-kantox/iteraptor/badges/gpa.svg)](https://codeclimate.com/github/am-kantox/iteraptor)
[![Issue Count](https://codeclimate.com/github/am-kantox/iteraptor/badges/issue_count.svg)](https://codeclimate.com/github/am-kantox/iteraptor)
[![Test Coverage](https://codeclimate.com/github/am-kantox/iteraptor/badges/coverage.svg)](https://codeclimate.com/github/am-kantox/iteraptor/coverage)

Adopted to be used with hashes/arrays. It **is not** intended to be used with
large objects.

## Usage

```ruby
require 'iteraptor'
```

**[Blog post](http://rocket-science.ru/hacking/2018/03/29/iteraptor-for-the-rescue) with detailed API documentation.**

`Iteraptor` is intended to be used for iteration of complex nested structures.
The yielder is being called with two parameters: “current key” and “current value.”
The key is an index (converted to string for convenience) of an element for any
`Enumerable` save for `Hash`.

Nested `Enumerable`s are called with a compound key, represented as a “breadcrumb,”
which is a path to current key, joined with `Iteraptor::DELIMITER` constant. The
latter is just a dot in current release.

## Features

### Boring (for users who are too conservative)

```ruby
enum = [{foo: {bar: [:baz, 42]}}, [:foo, {bar: {baz: 42}}]].random

— enum.iteraptor.each(**params, ->(full_key, value))
— enum.iteraptor.map(**params, ->(full_key, (key, value)))
— enum.iteraptor.select(*filters, **params, ->(full_key, value)
— enum.iteraptor.reject(*filters, **params, ->(full_key, value)
— enum.iteraptor.flat_map(**params, ->(full_key, value))
— enum.iteraptor.flatten(**params, ->(full_key, value))
— enum.iteraptor.collect(**params, ->(full_key, value))
```

### Direct 🐒 patching in 🇪🇸

* `cada` (_sp._ `each`) iterates through all the levels of the nested `Enumerable`,
yielding `parent, element` tuple; parent is returned as a delimiter-joined string
* `mapa` (_sp._ `map`) iterates all the elements, yielding `parent, (key, value)`;
the mapper should return either `[key, value]` array or `nil` to remove this
element;
  * _NB_ this method always maps to `Hash`, to map to `Array` use `plana_mapa`
  * _NB_ this method will raise if the returned value is neither `[key, value]` tuple nor `nil`
* `plana_mapa` iterates yielding `key, value`, maps to the yielded value,
whatever it is; `nil`s are not treated in some special way
* `aplanar` (_sp._ `flatten`) the analogue of `Array#flatten`, but flattens
the deep enumerable into `Hash` instance
* `recoger` (_sp._ `harvest`, `collect`) the opposite to `aplanar`, it builds
the nested structure out of flattened hash
* `segar` (_sp._ `yield`), alias `escoger` (_sp._ `select`) allows to filter
and collect elelements
* `rechazar` (_sp._ `reject`) allows to filter out and collect elelements.

### Words are cheap, show me the code

```ruby
▶ require 'iteraptor'
#⇒ true

▶ hash = {company: {name: "Me", currencies: ["A", "B", "C"],
▷         password: "12345678",
▷         details: {another_password: "QWERTYUI"}}}
#⇒ {:company=>{:name=>"Me", :currencies=>["A", "B", "C"],
#              :password=>"12345678",
#              :details=>{:another_password=>"QWERTYUI"}}}

▶ hash.segar(/password/i) { "*" * 8 }
#⇒ {"company"=>{"password"=>"********",
#   "details"=>{"another_password"=>"********"}}}

▶ hash.segar(/password/i) { |*args| puts args.inspect }
["company.password", "12345678"]
["company.details.another_password", "QWERTYUI"]
#⇒ {"company"=>{"password"=>nil, "details"=>{"another_password"=>nil}}}

▶ hash.rechazar(/password/)
#⇒ {"company"=>{"name"=>"Me", "currencies"=>["A", "B", "C"]}}

▶ hash.aplanar
#⇒ {"company.name"=>"Me",
#   "company.currencies.0"=>"A",
#   "company.currencies.1"=>"B",
#   "company.currencies.2"=>"C",
#   "company.password"=>"12345678",
#   "company.details.another_password"=>"QWERTYUI"}

▶ hash.aplanar.recoger
#⇒ {"company"=>{"name"=>"Me", "currencies"=>["A", "B", "C"],
#   "password"=>"12345678",
#   "details"=>{"another_password"=>"QWERTYUI"}}}

▶ hash.aplanar.recoger(symbolize_keys: true)
#⇒ {:company=>{:name=>"Me", :currencies=>["A", "B", "C"],
#   :password=>"12345678",
#   :details=>{:another_password=>"QWERTYUI"}}}
```

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

### Mapping

Mapper function should return a pair `[k, v]` or `nil` when called from hash,
or just a value when called from an array. E. g., deep hash filtering:

```ruby
▶ hash = {a: true, b: {c: '', d: 42}, e: ''}
#⇒ {:a=>true, :b=>{:c=>"", :d=>42}, :e=>""}
▶ hash.mapa { |parent, (k, v)| v == '' ? nil : [k, v] }
#⇒ {:a=>true, :b=>{:d=>42}}
```

This is not quite convenient, but I currently have no idea how to help
the consumer to decide what to return, besides analyzing the arguments,
received by code block. That is because internally both `Hash` and `Array` are
iterated as `Enumerable`s.

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
▶ hash.segar(/[abc]/) do |parent, elem|
▷   puts "Parent: #{parent.inspect}, Element: #{elem.inspect}"
▷ end
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

#### Flatten the deeply nested hash:

```ruby
▶ hash = {a: true, b: {c: '', d: 42}, e: ''}
#⇒ {:a=>true, :b=>{:c=>"", :d=>42}, :e=>""}
▶ hash.aplanar(delimiter: '_', symbolize_keys: true)
#⇒ {:a=>true, :b_c=>"", :b_d=>42, :e=>""}
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'iteraptor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install iteraptor

## Changelog

- **`0.6.0`** — experimental support for `full_parent: true` param
- **`0.5.0`** — `rechazar` and `escoger`
- **`0.4.0`** — `aplanar` and `plana_mapa`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/iteraptor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
