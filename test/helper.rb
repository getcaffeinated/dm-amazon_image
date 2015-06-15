Bundler.setup
require 'bundler'
require 'stringio'
require 'test/unit'
require 'lib/datamapper/amazon_image.rb'
require 'dm-core'
require 'dm-sqlite-adapter'
require 'dm-migrations'
require 'contest'
require 'rest-client'
DataMapper.setup :default, 'sqlite::memory:'

# DataMapper.logger = STDOUT

raise 'Usage: bundle exec ruby test/test.rb ACCESS_KEY_ID SECRET_ACCESS_KEY BUCKET' unless ARGV.length == 3

ACCESS_KEY_ID, SECRET_ACCESS_KEY, BUCKET = ARGV

class Photo
  include DataMapper::Resource
  include DataMapper::AmazonImage::Resource
  property :id, Serial
  property :caption, String

  def amazon_thumbnail_sizes; {:thumb => '100x>', :original => ''} end

  def amazon_config
    {:access_key_id => ACCESS_KEY_ID,
     :secret_access_key => SECRET_ACCESS_KEY,
     :bucket_name => BUCKET}
  end
end

class PhotoWithUnimplementedSizes
  include DataMapper::Resource
  include DataMapper::AmazonImage::Resource
  property :id, Serial

  def amazon_config
    {:access_key_id => ACCESS_KEY_ID,
     :secret_access_key => SECRET_ACCESS_KEY,
     :bucket_name => BUCKET}
  end
end

class PhotoWithUnimplementedConfig
  include DataMapper::Resource
  include DataMapper::AmazonImage::Resource
  property :id, Serial

  def amazon_thumbnail_sizes; {:thumb => '100x>'} end
end
