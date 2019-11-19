module Admin
  class StatisticsController < BaseController
    content_security_policy only: :index do |policy|
      policy.style_src :self, :unsafe_inline
    end

    before_action :authorize_user

    # GET /admin/statistics
    def index
      @start_date = index_params[:start_date] || Time.zone.yesterday.to_date
      @end_date = index_params[:end_date] || Time.zone.today.to_date
      report = StatisticsReport.new(start_date: @start_date, end_date: @end_date).gather_data
      @data = {}

      StatisticsReport::ATTRS.each do |attr|
        @data[attr] = report.send(attr)
      end
    end

    private

    def index_params
      params.permit(:start_date, :end_date)
    end

    def authorize_user
      authorize! :read, StatisticsReport
    end
  end
end
