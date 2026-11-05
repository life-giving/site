module Api
  class ReportsController < BaseController
    def index
      render json: Report.listed
    end
  end
end
