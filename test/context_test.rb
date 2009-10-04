require 'riot'
require 'stringio'

context "any context" do
  setup do
    @reporter = Riot::NilReport.new
    @context = Riot::Context.new("a", @reporter)
  end

  context "that doesn't have passing tests" do
    setup do
      @context.should("a") { true }
      @context.should("b") { false }
      @context.should("c") { raise Exception, "blah" }
      @context.report
    end

    asserts("passed test count") { @reporter.passes }.equals(1)
    asserts("failure count") { @reporter.failures }.equals(1)
    asserts("unexpected errors count") { @reporter.errors }.equals(1)
  end # that doesn't have passing tests

  context "when running setup:" do
    setup { @context.setup { "foo" } }

    asserts "topic becomes available to test as result of setup" do
      @context.should("bar") { topic }.actual
    end.equals("foo")
  end # when running setup
end # any context

# 
# Test Context

test_context = context("foo", Riot::NilReport.new) do
  setup { @test_counter = 0 }
  asserts("truthiness") { @test_counter += 1; true }
  asserts("more truthiness") { @test_counter += 1; true }
end # A CONTEXT THAT IS DEQUEUED

context "test context" do
  setup { Riot.dequeue_context(test_context) }
  should("confirm context description") { test_context.to_s }.equals("foo")
  should("confirm assertion count") { test_context.assertions.length }.equals(2)

  should("call setup once per context") do
    test_context.situation.instance_variable_get(:@test_counter) # yuck
  end.equals(2)
end # test context

# 
# Nested Context

inner_nested_context, other_nested_context = nil, nil
nested_context = context("foo", Riot::NilReport.new) do
  setup do
    @test_counter = 0
    @foo = "bar"
  end
  asserts("truthiness") { @test_counter += 1; true }
  
  inner_nested_context = context("baz") do
    setup { @test_counter += 10 }
  end # A CONTEXT THAT IS DEQUEUED

  other_nested_context = context("bum") {} # A CONTEXT THAT IS DEQUEUED
end # A CONTEXT THAT IS DEQUEUED

context "nested context" do
  setup do
    [nested_context, inner_nested_context, other_nested_context].each do |c|
      Riot.dequeue_context(c)
    end
  end
  
  should("inherit parent context") do
    inner_nested_context.situation.instance_variable_get(:@test_counter)
  end.equals(10)

  should("chain context names") { inner_nested_context.to_s }.equals("foo baz")

  asserts "parent setup is called even if setup not defined for self" do
    other_nested_context.situation.instance_variable_get(:@foo)
  end.equals("bar")
end
