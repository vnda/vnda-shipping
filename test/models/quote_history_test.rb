require 'test_helper'

class QuoteHistoryTest < ActiveSupport::TestCase
  test ".register does not save record if no shop_id" do
    assert_no_difference("QuoteHistory.count") do
      QuoteHistory.register(nil, nil)
    end
  end

  test ".register does not save record if no cart_id" do
    assert_no_difference("QuoteHistory.count") do
      QuoteHistory.register(1, nil)
    end
  end

  test ".register save record if both shop_id and cart_id" do
    assert_difference("QuoteHistory.count", 1) do
      QuoteHistory.register(1, 2)
    end
  end

  test ".register save other attributes" do
    history = QuoteHistory.register(1, 2)
    assert_nil history.external_request
    assert_nil history.external_response
    assert_nil history.quotations

    history = QuoteHistory.register(1, 2, external_request: "foo")
    assert_equal "foo", history.external_request

    history = QuoteHistory.register(1, 2, external_response: "bar")
    assert_equal "bar", history.external_response

    history = QuoteHistory.register(1, 2, quotations: "baz")
    assert_equal "baz", history.quotations
  end

  test ".register does not raise error if receive unknown attributes" do
    assert_difference("QuoteHistory.count", 1) do
      QuoteHistory.register(1, 2, foo: "bar")
    end
  end
end
