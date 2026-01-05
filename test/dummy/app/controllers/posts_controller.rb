class PostsController < ApplicationController
  def index
    @blogs = Post.all
  end
end
