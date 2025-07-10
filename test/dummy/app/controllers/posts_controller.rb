class PostsController < ApplicationController
  def index
    raise 'aadsfasdf'
    @blogs = Post.all
  end
end