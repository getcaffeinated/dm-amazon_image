require 'digest'
require 'cgi'
require 'aws/s3'

module DataMapper
  module AmazonImage
    module Resource
      module ClassMethods
        def amazon_generate_token; Digest::MD5.hexdigest((Time.now.to_i * rand(10000)).to_s)[0..10] end
      end

      def self.included(base)
        base.extend ClassMethods
        base.send :property, :amazon_filename, String
        base.send :before, :save, :amazon_before_create_hook
        base.send :after, :destroy, :amazon_after_destroy_hook
      end

      def log(msg); DataMapper.logger << "#{msg}\n" end

      def amazon_config; raise NotImplementedError, "Implement the amazon_config method for the #{self.class} model." end
      def amazon_thumbnail_sizes; raise NotImplementedError, "Implement the amazon_thumbnail_sizes method for the #{self.class} model." end

      def save_amazon_photos; amazon_before_create_hook end

      def amazon_file=(o); (o.nil? ? nil : @amazon_file = Image.new(o)) end

      def amazon_public_path(name); "#{self.class}/#{CGI.escape name.to_s}/#{self.amazon_filename}" end
      def amazon_public_url(name=nil); self.amazon_filename.nil? ? nil : "http://s3.amazonaws.com/#{amazon_config[:bucket_name]}/#{self.amazon_public_path name}" end

      protected

      def amazon_before_create_hook
        return if @amazon_file.nil?
        self.amazon_filename = "#{self.class.amazon_generate_token}#{File.extname @amazon_file.filename}"
        self.save_thumbnails @amazon_file
        @amazon_file = nil
      end

      def amazon_after_destroy_hook
        amazon_thumbnail_sizes.each do |name, size|
          log "DataMapper::AmazonImage: Deleting #{amazon_config[:bucket_name]}/#{amazon_public_path name}"
          connect_to_amazon
          AWS::S3::S3Object.delete amazon_public_path(name), amazon_config[:bucket_name]
        end
      end

      def save_thumbnails(amazon_file)
        amazon_thumbnail_sizes.each do |key,value|
          size = value || key
          tempfile_new = Tempfile.new 'tempfile_new'
          # Generate a thumbnail of exact dimensions provided, using the minimum
          # X-axis or Y-axis value for scaling

          if size.to_s == '' # No resizing will be done
            tempfile_new.write amazon_file.tempfile.read
            tempfile_new.rewind
          elsif (size.to_s =~ /^\d{1,}x\d{1,}$/) === 0
            sizes = size.match /^(\d{1,})x(\d{1,})$/
            `convert -resize #{sizes[1].to_i*2}x#{sizes[2].to_i*2}^ -resize 50%x50% -gravity center -crop #{sizes[1]}x#{sizes[2]}+0+0 +repage  #{amazon_file.tempfile.path} #{tempfile_new.path}`
          # Generate a square thumbnail for any "x123" key
          elsif (size.to_s =~ /^x\d{1,}/) === 0
            thisSize = size[(size.to_s =~ /\d{1,}$/)..size.length]
            `convert -resize x#{thisSize.to_i*2} -resize 50%x50% -gravity center -crop #{thisSize}x#{thisSize}+0+0 +repage  #{amazon_file.tempfile.path} #{tempfile_new.path}`
          else
            `convert -resize "#{size}" #{amazon_file.tempfile.path} #{tempfile_new.path}`
          end
          self.save_to_amazon tempfile_new, :as => self.amazon_public_path(key)
          tempfile_new.close! if tempfile_new.respond_to? :close!
        end
      end

      def save_to_amazon(file, opts={})
        target_filename = opts[:as]
        log "DataMapper::AmazonImage: Saving #{amazon_config[:bucket_name]}/#{target_filename}"
        connect_to_amazon
        begin
          AWS::S3::S3Object.store target_filename, file, amazon_config[:bucket_name], :access => :public_read, :use_ssl => true
        rescue Errno::ECONNRESET
          log "DataMapper::AmazonImage: Connection reset by peer for #{self.class}, retrying"
          retry
        end
        true
      end

      def connect_to_amazon
        unless AWS::S3::Base.connected?
          AWS::S3::Base.establish_connection! :access_key_id => amazon_config[:access_key_id], :secret_access_key => amazon_config[:secret_access_key]
        end
      end

    end


    class Image
      extend DataMapper::AmazonImage::Resource::ClassMethods

      attr_reader :filename, :tempfile
      def initialize(o)
        case o
        when Hash
          if o[:tempfile].is_a? Tempfile
            @tempfile = o[:tempfile]
          elsif o[:tempfile].respond_to? :read
            @tempfile = Tempfile.new 'stringio'
            @tempfile.write o[:tempfile].read
            @tempfile.rewind
          end
          @filename = o[:filename]
        when File
          @tempfile = o
          @filename = "#{self.class.amazon_generate_token}.#{File.extname o.path}"
        when Tempfile
          raise 'An ext (extension) must be specified for direct Tempfile inclusion' unless o[:ext]
          @tempfile = o
          @filename = "#{DataMapper::AmazonImage.amazon_generate_token}.#{o[:ext]}"
        end
      end
      def to_hash; {:tempfile => @tempfile, :filename => @filename} end
    end
  end
end
