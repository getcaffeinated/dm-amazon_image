# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dm-amazon_image}
  s.version = "2.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.4") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kyle Drake"]
  s.date = %q{2014-02-19}
  s.description = %q{Datamapper plugin for Amazon Image S3 uploads. Woo!}
  s.email = ["kyle@stepchangegroup.com"]
  s.files = ["lib/datamapper/amazon_image.rb", "test/helper.rb", "test/test.rb", "test/files", "test/files/lordhumungus.jpg", "Gemfile", "README.markdown"]
  s.homepage = %q{https://github.com/mjfreshyfresh/dm-amazon_image}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dm-amazon_image}
  s.rubygems_version = %q{1.3.7.1}
  s.summary = %q{Datamapper plugin for Amazon Image S3 uploads.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<aws-s3>, ["= 0.6.2"])
      s.add_runtime_dependency(%q<dm-core>, [">= 1.0.0"])
    else
      s.add_dependency(%q<aws-s3>, ["= 0.6.2"])
      s.add_dependency(%q<dm-core>, [">= 1.0.0"])
    end
  else
    s.add_dependency(%q<aws-s3>, ["= 0.6.2"])
    s.add_dependency(%q<dm-core>, [">= 1.0.0"])
  end
end
