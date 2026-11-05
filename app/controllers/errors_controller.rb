# Rendered by config.exceptions_app. Someone in crisis can land here, so every page keeps the hotline.
class ErrorsController < ApplicationController
  skip_forgery_protection

  def not_found = show_error(:not_found, 404)
  def unprocessable = show_error(:unprocessable, 422)
  def server_error = show_error(:server_error, 500)

  private

  def show_error(key, status)
    # A failed /report.json request must still get the HTML page.
    render :show, formats: :html, status: status, locals: { key: key }
  end
end
