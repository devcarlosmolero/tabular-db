require "tabular-db"
require_relative "../models/user"

class PagesController < ApplicationController
  def index
    params.permit(:page, :limit, :sort_by, :sort_direction, :search)
    page = params.fetch(:page, 0).to_i
    limit = params.fetch(:limit, 10).to_i
    search = params.fetch(:search, nil)
    sort_by = params.fetch(:sort_by, nil)
    sort_direction = params.fetch(:sort_direction, nil)

    sort = nil
    where = nil

    if (sort_by === "age" or sort_by === "id") and sort_direction != "-"
      sort = "row['#{sort_by}'].to_i * #{sort_direction === "ASC" ? "1":"-1"}"
    end

    if (sort_by === "username" or sort_by === "name" or sort_by === "email") and sort_direction != "-"
      sort = "row['#{sort_by}']#{sort_direction === "ASC" ? nil:".downcase.reverse"}"
    end

    if search
      where = "row['email'].downcase.include?'#{search.downcase}' or row['username'].downcase.include? '#{search.downcase}' or row['name'].downcase.include? '#{search.downcase}'"
    end

    db = TabularDB.new("/app/db")
    data = db.read(User, {
      limit: limit,
      offset: limit * page,
      where: where,
      sort: sort
    })
    @users = data[:rows]
    @header = data[:header]
    @total_count = data[:total_count]
    @has_next = data[:has_next]
    @has_prev = data[:has_prev]

    @current_page = page
    @current_limit = limit
    @current_sort_by = sort_by
    @current_sort_direction = sort_direction
    @current_search = search
  end
end
