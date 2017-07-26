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

  describe "Including into cache" do
    it "should not done with distributed store" do
      refute @dstore.candocas?
      assert @store.candocas?
    end
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

    describe "Test Multi cas" do
      it "should fail with empty names" do
        refute @store.cas_multi { |_hash| flunk }
      end

      it "should set new values" do
        @store.write('rabbit', @white_rabbit)
        @store.write('hare', @black_rabbit)
        assert_equal true, (@store.cas_multi('rabbit', 'hare') do |hash|
          assert_equal({ "rabbit" => @white_rabbit, 'hare' => @black_rabbit }, hash)
          { "rabbit" => @black_rabbit, 'hare' => @white_rabbit }
        end)
        assert_equal({ "rabbit" => @black_rabbit, 'hare' => @white_rabbit }, @store.read_multi('rabbit', 'hare'))
      end

      it "should set a ttl " do
        @store.write('rabbit', @white_rabbit)
        @store.write('hare', @black_rabbit)
        @store.cas_multi('rabbit','hare',{:expires_in => 600,:race_condition_ttl => 1}) do |hash|
          { "rabbit" => @black_rabbit, "hare" =>  @white_rabbit}
        end
        values = @store.read_multi('rabbit', 'hare')
        assert_equal({ "rabbit" => @black_rabbit, 'hare' => @white_rabbit },values)
        re = @store.instance_variable_get('@data')
        assert re.ttl('rabbit') > 0
        assert re.ttl('hare') > 0

      end

      it "should not send values for not existing keys" do
        assert(@store.cas_multi('not_exist') do |hash|
          assert hash.empty?
          {}
        end)
      end

      it "should not write keys not in parameter" do
        @store.write('foo', 'baz')
        assert @store.cas_multi('foo') { |_hash| { 'fu' => 'baz' } }
        assert_nil @store.read('fu')
        assert_equal 'baz', @store.read('foo')
      end

      def test_cas_multi_with_partial_update
        @store.write('foo', 'bar')
        @store.write('fud', 'biz')
        assert(@store.cas_multi('foo', 'fud') do |hash|
          assert_equal({ "foo" => "bar", "fud" => "biz" }, hash)

          { "foo" => "baz" }
        end)
        assert_equal({ "foo" => "baz", "fud" => "biz" }, @store.read_multi('foo', 'fud'))
      end

      def test_cas_multi_with_partial_conflict
        @store.write('foo', 'bar')
        @store.write('fud', 'biz')
        result = @store.cas_multi('foo', 'fud') do |hash|
          assert_equal({ "foo" => "bar", "fud" => "biz" }, hash)
          @store.write('foo', 'bad')
          { "foo" => "baz", "fud" => "buz" }
        end
        assert result
        assert_equal({ "foo" => "bad", "fud" => "buz" }, @store.read_multi('foo', 'fud'))
      end

    end
  end

end