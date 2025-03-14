require "tabular-db"
require_relative "../models/user"

class PagesController < ApplicationController
  def index
    params.permit(:page, :limit, :sort_by, :sort_direction)
    page = params.fetch(:page, 0).to_i
    limit = params.fetch(:limit, 10).to_i
    sort_by = params.fetch(:sort_by, nil)
    sort_direction = params.fetch(:sort_direction, nil)

    sort = nil

    if (sort_by === "age" or sort_by === "id") and sort_direction != "-"
      sort = "row['#{sort_by}'].to_i * #{sort_direction === "ASC" ? "1":"-1"}"
    end

    db = TabularDB.new("/app/db")
    data = db.read(User, limit, page * limit, nil, sort)
    @users = data[:rows]
    @header = data[:header]
    @has_next = data[:has_next]
    @has_prev = data[:has_prev]

    @current_page = page
    @current_limit = limit
    @current_sort_by = sort_by
    @current_sort_direction = sort_direction
  end
end
