# Minitest::Silence

Minitest plugin to suppress output from tests. This plugin will buffer any output coming from a test going to STDOUT or STDERR, to make sure it doesn't interfere with the output of the test runner itself. By default, it will discard any output, unless the `--verbose` option is set. It also supports failing a test if it is writing anything to STDOUT or STDERR by setting the `--fail-on-output` command line option.

## Installation

Add this line to your application's Gemfile, and run `bundle install`:

```ruby
gem 'minitest-silence', require: false
```

## Usage

The plugin will be aiutomatically activated by Minitest if it is in your application's bundle.

- By default, it will simply discard any output writting to `STDOUT` or `STDERR` by your tests.
- When specifying `--verbose`, the output will be buffered and written to the `STDOUT` inside a box that makes clear what test the output originated from.
- When running with the `--fail-on-output` option, a test will fail if it writes anything to either `STDOUT` or `STDERR`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bin/rake install`. To release a new version, update the version number in `version.rb`, and then run `bin/rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopifyminitest-silence. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/Shopify/minitest-silence/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Minitest::Silence project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Shopify/minitest-silence/blob/master/CODE_OF_CONDUCT.md).
