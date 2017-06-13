module V1
  def_model 'achievements' do
    def transform_badge(logger)
      if icon_url.present?
        Downloader.download_to_local(icon_url, self, logger)
      end
    end
  end
end
