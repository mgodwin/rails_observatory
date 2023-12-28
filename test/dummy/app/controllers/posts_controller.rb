class PostsController < ApplicationController
  def index
    @blogs = Post.all
    raise "This is an error"
  end
end