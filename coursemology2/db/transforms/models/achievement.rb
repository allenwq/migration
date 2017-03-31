module V1::Source
  def_model 'achievements' do
    def transform_badge
      if icon_url.present?
        Downloader.download_to_local(icon_url, self)
      end
    end
  end
end
