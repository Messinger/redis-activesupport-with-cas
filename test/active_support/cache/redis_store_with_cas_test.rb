require 'active_support/test_helper'
require 'ostruct'

describe "ActiveSupport::Cache::RedisStoreWithCas" do

  def setup
    @store  = ActiveSupport::Cache::RedisStoreWithCas.new "redis://127.0.0.1:6379/5/cachetest"
    @dstore = ActiveSupport::Cache::RedisStoreWithCas.new "redis://127.0.0.1:6379/5", "redis://127.0.0.1:6379/6"

    @rabbit = OpenStruct.new :name => "bunny"
    @white_rabbit = OpenStruct.new :color => "white"
    @black_rabbit = OpenStruct.new :color => 'black'

  end

  def teardown
    @store.instance_variable_get("@data").flushdb
    @dstore.instance_variable_get("@data").flushdb
  end

  describe "Single cas " do
    it "should not swap missing key" do
      refute @store.cas('rabbit') { |_value| flunk }
    end

    it "should correct swap value" do
      @store.write "rabbit", @rabbit
      assert(@store.cas('rabbit') do |value|
        assert_equal @rabbit, value
        @white_rabbit
      end)
      @store.read("rabbit").must_equal(@white_rabbit)
    end

    it "should not swap if value changes" do
      @store.write('rabbit', @rabbit)
      refute @store.cas('rabbit') { |_value|
        @store.write('rabbit', @black_rabbit)
        @white_rabbit
      }
      @store.read("rabbit").must_equal(@black_rabbit)
    end

  end

end