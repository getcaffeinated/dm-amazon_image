DataMapper::AmazonImage
==============================================

DataMapper::AmazonImage is a simple and reliable mechanism for dealing with image processing and S3 uploads of images within DataMapper.

Installation
-------------

    gem install dm-amazon_image
    require 'datamapper/amazon_image'

Note: You MUST HAVE IMAGEMAGICK INSTALLED ON THE SERVER. OSX: sudo port install ImageMagick (it takes a while to compile).

General Usage
-------------

For a list of options for resizing, see this manual: http://www.imagemagick.org/Usage/resize/#resize
Here are some tips:

* "123x" makes a thumbnail with the aspect ratio preserved.
* "x123" makes a square thumbnail
* "123x321" makes a thumbnail of the exact size provided, using the smallest of the dimensions as the axis for scaling

Create a model as such:

    class Photo
      include DataMapper::Resource
      include DataMapper::AmazonImage::Resource # Now creates amazon_filename property and save hooks for you!
      property :id, Serial

      def amazon_thumbnail_sizes
        {:main => '461x>', :thumb => '180x180', :original => '1000x>'}
      end

      def amazon_config
        {:access_key_id => "dsfsdsdsfher239r8yu23rblahblahblah",
         :secret_access_key => "X0odsfdsfdsfer239r8yu23rblahblahblah",
         :bucket_name => (ENV['RACK_ENV'] == :production ? 'bucket-name-production' : 'bucket-name-development')}
      end
    end

In your view, use amazon_file:

    <h1>Upload your Ska band pics!</h1>
    <form action="/photos" method="POST" enctype="multipart/form-data">
      SKA BAND PICTURE: <input name="photo[amazon_file]" type="file"/>
      <input type="submit" value="RUDE"/>
    </form>

In your controller:

    post '/photos' do
      @photo = Photo.create params[:photo]
      redirect "/photos/#{@photo.id}"
    end

In your views:

    <img src="<%= @photo.amazon_public_url(:size_name) %>"/>

Be sure to create an S3 bucket for development and production with your app.

If you need to save the amazon photos manually for some reason, use this syntax:

    @photo.save_amazon_photos

If you want to create a validation to ensure the file exists or check its format, try something like this (send via AJAX the $('#file_input').val() and it will provide string of the filename for type verification):

    validates_with_method :check_amazon_file

    def check_amazon_file
      return true if @amazon_file.is_a?(Hash)
      if @amazon_file.is_a?(String)
        return [false, 'Please attach a photo'] if @amazon_file.empty?
        return [false, 'Please attach a jpg, png, or gif photo file'] unless @amazon_file =~ /jpg|JPG|jpeg|JPEG|gif|GIF|png|PNG/
      end
      true
    end
