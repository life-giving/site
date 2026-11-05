class PagesController < ApplicationController
  def home
    @reports = Report.listed
  end
end
