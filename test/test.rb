require 'test/helper'

lord_humungus_path = File.join 'test', 'files', 'lordhumungus.jpg'
FILE = File.open lord_humungus_path, 'r'
FILESIZE = File.size FILE.path
TEMPFILE = Tempfile.new 'testphoto'
TEMPFILE.write FILE.read
TEMPFILE.rewind
STRINGIO = StringIO.new File.read(lord_humungus_path)
AMAZON_FILE = {:tempfile => TEMPFILE, :filename => "#{Photo.amazon_generate_token}.jpg"}
AMAZON_FILE_STRINGIO = {:tempfile => STRINGIO, :filename => "#{Photo.amazon_generate_token}.jpg"}

class AmazonImageTest < Test::Unit::TestCase

  setup do
    DataMapper.auto_migrate!
    TEMPFILE.rewind
    FILE.rewind
    STRINGIO.rewind
  end

  context 'the Photo model upon creation' do

    setup do
      @photo = Photo.create :caption => 'Lord Humungus at a political rally',
                            :amazon_file => AMAZON_FILE
    end

    teardown { @photo.destroy }

    test 'uploads original that is the same size' do
      result = RestClient.get @photo.amazon_public_url(:original)
      assert_equal FILESIZE, result.size
    end

    test 'uploads thumb that is smaller than original size' do
      result = RestClient.get @photo.amazon_public_url(:thumb)
      assert result.size < FILESIZE
    end

    test 'retains the unrelated model data' do
      assert_equal @photo.caption, 'Lord Humungus at a political rally'
    end

    test 'provides the public image url' do
      assert_equal @photo.amazon_public_url(:thumb), "http://s3.amazonaws.com/#{BUCKET}/#{@photo.amazon_public_path(:thumb)}"
    end

    test 'uploads remote files' do
      result = RestClient.get @photo.amazon_public_url(:thumb)
      assert_equal result.code, 200
      result = RestClient.get @photo.amazon_public_url(:original)
      assert_equal result.code, 200
      assert result.length > 0
    end

    test 'fails with invalid file request' do
      assert_raises RestClient::ResourceNotFound do
        RestClient.get @photo.amazon_public_url(:does_not_exist)
      end
    end
  end

  test 'successfully creates with direct file' do
    photo = Photo.create :amazon_file => FILE
    result = RestClient.get photo.amazon_public_url(:original)
    assert_equal result.code, 200
    assert_equal FILESIZE, result.size
    photo.destroy
  end

  test 'successfully creates with any IO providing a read method' do
    photo = Photo.create :amazon_file => AMAZON_FILE_STRINGIO
    result = RestClient.get photo.amazon_public_url(:original)
    assert_equal result.code, 200
    assert_equal FILESIZE, result.size
    photo.destroy
  end

  test 'saves record even if no image is attached' do
    photo = Photo.create :caption => 'Lord Humungus, no photo yet'
    assert_not_same nil, photo.id
  end

  test 'photo successfully deletes when model is destroyed' do
    photo = Photo.create :caption => 'Lord Humungus at a political rally',
                                     :amazon_file => AMAZON_FILE
    photo.destroy
    assert_raises RestClient::ResourceNotFound do
      RestClient.get photo.amazon_public_url(:original)
    end
  end

  test 'photo successfully deletes when model is destroyed if not connected to AWS' do
    photo = Photo.create :caption => 'Lord Humungus at a political rally',
                                     :amazon_file => AMAZON_FILE
    AWS::S3::Base.disconnect!
    photo.destroy
    assert_raises RestClient::ResourceNotFound do
      RestClient.get photo.amazon_public_url(:original)
    end
  end

  test 'the PhotoWithUnimplementedSizes model throws NotImplementedError without amazon_thumbnail_sizes method on create' do
    assert_raises NotImplementedError do
      PhotoWithUnimplementedSizes.create :amazon_file => AMAZON_FILE
    end
  end

  test 'the PhotoWithUnimplementedConfig model throws NotImplementedError without amazon_thumbnail_sizes method on create' do
    assert_raises NotImplementedError do
      PhotoWithUnimplementedConfig.create :amazon_file => AMAZON_FILE
    end
  end

end
