require 'spec_helper'

module Pageflow
  describe ZencoderAttachment do
    let(:zencoder_options) do
      Pageflow.config.zencoder_options
    end

    let(:s3_protocol) do
      zencoder_options[:s3_protocol]
    end

    let(:s3_host_alias) do
      zencoder_options[:s3_host_alias]
    end

    let(:version) do
      zencoder_options[:attachments_version]
    end

    def file_double(id:)
      double('File', id: id, class: double(to_s: 'File'))
    end

    describe '#original_filename' do
      it 'defaults to file_name_pattern' do
        attachment = ZencoderAttachment.new(file_double(id: 5), 'video.mp4')

        expect(attachment.original_filename).to eq('video.mp4')
      end

      it 'replaces {{number}} in with 0' do
        attachment = ZencoderAttachment.new(file_double(id: 5), 'thumbnail-{{number}}.jpg')

        expect(attachment.original_filename).to eq('thumbnail-0.jpg')
      end

      it 'appends format option' do
        attachment = ZencoderAttachment.new(file_double(id: 5), 'thumbnail', format: 'jpg')

        expect(attachment.original_filename).to eq('thumbnail.jpg')
      end
    end

    describe '#path' do
      it 'uses paperclip for interpolation' do
        file = file_double(id: 5)
        attachment = ZencoderAttachment.new(file, 'video.mp4')

        expect(attachment.path).to eq("/#{version}/test-host/files/000/000/005/video.mp4")
      end

      it 'replaces {{number}} in with 0' do
        file = file_double(id: 5)
        attachment = ZencoderAttachment.new(file, 'thumbnail-{{number}}.jpg')

        expect(attachment.path).to eq("/#{version}/test-host/files/000/000/005/thumbnail-0.jpg")
      end

      it 'appends format option' do
        file = file_double(id: 5)
        attachment = ZencoderAttachment.new(file, 'thumbnail', format: 'jpg')

        expect(attachment.path).to eq("/#{version}/test-host/files/000/000/005/thumbnail.jpg")
      end
    end

    describe '#url' do
      it 'uses s3_protocol and s3_host_alias from zencoder config' do
        file = file_double(id: 5)
        attachment = ZencoderAttachment.new(file, 'video.mp4')

        expect(attachment.url).to eq("#{s3_protocol}://#{s3_host_alias}/#{version}/" \
                                     'test-host/files/000/000/005/video.mp4')
      end

      it 'supports protocol relative urls' do
        Pageflow.config.zencoder_options[:s3_protocol] = ''
        file = file_double(id: 5)
        attachment = ZencoderAttachment.new(file, 'video.mp4')

        expect(attachment.url).to eq("//#{s3_host_alias}/#{version}/" \
                                     'test-host/files/000/000/005/video.mp4')
      end

      context 'with default_protocol options ' do
        it 'prepends protocol if url would be protocol relative' do
          Pageflow.config.zencoder_options[:s3_protocol] = ''
          file = file_double(id: 5)
          attachment = ZencoderAttachment.new(file, 'video.mp4')

          result = attachment.url(default_protocol: 'http')

          expect(result).to eq("http://#{s3_host_alias}/#{version}/" \
                               'test-host/files/000/000/005/video.mp4')
        end

        it 'does not alter relative urls' do
          Pageflow.config.zencoder_options[:s3_protocol] = ''
          file = file_double(id: 5)
          attachment = ZencoderAttachment.new(file, 'video.mp4', url: ':filename')

          expect(attachment.url(default_protocol: 'http')).to eq('video.mp4')
        end

        it 'does not alter protocol if configured' do
          Pageflow.config.zencoder_options[:s3_protocol] = 'https'
          file = file_double(id: 5)
          attachment = ZencoderAttachment.new(file, 'video.mp4')

          result = attachment.url(default_protocol: 'http')

          expect(result).to eq("https://#{s3_host_alias}/#{version}/" \
                               'test-host/files/000/000/005/video.mp4')
        end
      end

      it 'can append unique id to url' do
        file = file_double(id: 5)
        attachment = ZencoderAttachment.new(file, 'video.mp4')

        result = attachment.url(unique_id: 3)

        expect(result).to eq("#{s3_protocol}://#{s3_host_alias}/#{version}/" \
                             'test-host/files/000/000/005/video.mp4?n=3')
      end

      it 'can append url suffix to url' do
        file = file_double(id: 5)
        attachment = ZencoderAttachment.new(file, 'playlist.smil', url_suffix: '/master.m3u8')

        expect(attachment.url).to eq("#{s3_protocol}://#{s3_host_alias}/#{version}/" \
                                     'test-host/files/000/000/005/playlist.smil/master.m3u8')
      end

      it 'can append url suffix and unique id to url' do
        file = file_double(id: 5)
        attachment = ZencoderAttachment.new(file, 'playlist.smil', url_suffix: '/master.m3u8')

        result = attachment.url(unique_id: 3)

        expect(result).to eq("#{s3_protocol}://#{s3_host_alias}/#{version}/" \
                             'test-host/files/000/000/005/playlist.smil/master.m3u8?n=3')
      end
    end

    describe '#dir_name' do
      it 'returns directory path' do
        file = file_double(id: 5)
        attachment = ZencoderAttachment.new(file, 'video.mp4')

        expect(attachment.dir_name).to eq("/#{version}/test-host/files/000/000/005")
      end

      it 'includes dir components from file_name_pattern' do
        file = file_double(id: 5)
        attachment = ZencoderAttachment.new(file, 'dir/video.mp4')

        expect(attachment.dir_name).to eq("/#{version}/test-host/files/000/000/005/dir")
      end
    end

    describe '#base_name_pattern' do
      it 'removes dirs from pattern' do
        file = file_double(id: 5)
        attachment = ZencoderAttachment.new(file, 'dir/video-{{number}}')

        expect(attachment.base_name_pattern).to eq('video-{{number}}')
      end
    end
  end
end
