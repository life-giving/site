module Admin
  class ReportsController < BaseController
    before_action -> { limit_request_body(:max_pdf_size_mb, admin_reports_path) }, only: %i[create update]
    before_action :set_report, only: %i[update destroy]

    def index
      @report = Report.new
      @reports = Report.listed
    end

    def create
      @report = Report.new(report_params)
      if @report.save
        redirect_to admin_reports_path, notice: t("admin.reports.uploaded"), status: :see_other
      else
        @reports = Report.listed
        render :index, status: error_status(@report)
      end
    end

    def update
      if @report.update(report_params)
        @report.move_to(params[:position]) if params.key?(:position)
        redirect_to admin_reports_path, notice: (t("admin.saved") unless params.key?(:position)), status: :see_other
      else
        flash.now[:alert] = @report.errors.full_messages.to_sentence
        index
        render :index, status: :unprocessable_content
      end
    end

    def destroy
      @report.destroy!
      redirect_to admin_reports_path, notice: t("admin.deleted"), status: :see_other
    end

    private

    def set_report
      @report = Report.find(params[:id])
    end

    # A non-file value here would be read by Active Storage as a signed blob id.
    def report_params
      attributes = params.fetch(:report, {}).permit(:title_uk, :title_en, :file)
      attributes.delete(:file) unless attributes[:file].respond_to?(:read)
      attributes
    end
  end
end
