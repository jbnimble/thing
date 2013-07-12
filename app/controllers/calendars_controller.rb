class CalendarsController < ApplicationController
  def index
    render_options = {}

    respond_to do |format|
      format.html {
        load_data
      }
      format.ics {
        filename = "pennsic-#{Schedule::PENNSIC_YEAR}-all.ics"
        cache_filename = Rails.root.join('tmp', filename)

        unless File.exists?(cache_filename)
          render_options[:calendar_name] = "PennsicU #{Schedule::PENNSIC_YEAR}"
          load_data
          renderer = CalendarRenderer.new(@instances, @instructables)
          data = renderer.render_ics(render_options, filename, cache_filename)
          cache_in_file(cache_filename, data)
        end
        send_file(cache_filename, type: Mime::ICS, disposition: "inline; filename=#{filename}", filename: filename)
      }
      format.pdf {
        omit_descriptions = params[:brief].present?
        no_page_numbers = params[:unnumbered].present?

        filename = [
          "pennsic-#{Schedule::PENNSIC_YEAR}-all",
          omit_descriptions ? 'brief' : nil,
          no_page_numbers ? 'unnumbered' : nil,
        ].compact.join('-') + '.pdf'
        cache_filename = Rails.root.join('tmp', filename)

        unless File.exists?(cache_filename)
          render_options[:omit_descriptions] = omit_descriptions
          render_options[:no_page_numbers] = no_page_numbers
          load_data
          renderer = CalendarRenderer.new(@instances, @instructables)
          data = renderer.render_pdf(render_options, filename, cache_filename)
          cache_in_file(cache_filename, data)
        end
        send_file(cache_filename, type: Mime::PDF, disposition: "inline; filename=#{filename}", filename: filename)
      }
      format.csv {
        filename = "pennsic-#{Schedule::PENNSIC_YEAR}-all.csv"
        cache_filename = Rails.root.join('tmp', filename)

        unless File.exists?(cache_filename)
          load_data
          renderer = CalendarRenderer.new(@instances, @instructables)
          data = renderer.render_csv(render_options, "pennsic-#{Schedule::PENNSIC_YEAR}-full.csv")
          cache_in_file(cache_filename, data)
        end
        send_file(cache_filename, type: Mime::CSV, disposition: "filename=#{filename}", filename: filename)
      }
      format.xlsx {
        filename = "pennsic-#{Schedule::PENNSIC_YEAR}-all.xlsx"
        cache_filename = Rails.root.join('tmp', filename)

        unless File.exists?(cache_filename)
          load_data
          renderer = CalendarRenderer.new(@instances, @instructables)
          data = renderer.render_xlsx(render_options, "pennsic-#{Schedule::PENNSIC_YEAR}-full.xlsx")
          cache_in_file(cache_filename, data)
        end
        send_file(cache_filename, type: Mime::XLSX, disposition: "filename=#{filename}", filename: filename)
      }
    end
  end

  private

  def load_data
    @instructables = Instructable.where(scheduled: true).order(:topic, :subtopic, :culture, :name).includes(:instances, :user)
    @instances = Instance.where(instructable_id: @instructables.map(&:id)).order('start_time, btrsort(location)').includes(instructable: [:user])
  end

  def cache_in_file(cache_filename, data)
    if cache_filename
      tmp_filename = [cache_filename, SecureRandom.hex(16)].join
      File.open(tmp_filename, 'wb') do |f|
        f.write data
      end
      File.rename(tmp_filename, cache_filename)
    end
  end
end
