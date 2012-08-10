require 'spec_helper'

describe Split::Metric do
  before(:each) { Split.redis.flushall }
  let(:experiment) do
    experiment = Split::Experiment.new('basket_text', 'Basket', "Cart")
    experiment.save
    experiment
  end
  context "generate_key" do
    let(:key) { Split::Metric.generate_key("basket_text", "clicks") }
    subject { key }
    it { should == "basket_text:metric:clicks" }
  end
  context "create" do
    let(:metric) do
      Split::Metric.create(name: "clicks", experiment_name: experiment.name, values: {"true" => 1})
    end
    context "success" do
      context "name" do
        subject { metric.name }
        it { should eql "clicks" }
      end
      context "experiment_name" do
        subject { metric.experiment_name }
        it { should eql "basket_text" }
      end
      context "values" do
        context "keys" do
          subject { metric.values.keys }
          it { should include "true" }
        end
        context "values" do
          subject { metric.values.values }
          it { should include 1 }
        end
      end
    end
  end
  context "find" do
    before do
      Split::Metric.create(name: "clicks", experiment_name: experiment.name, values: {"true" => 1})
    end
    let(:metric) { Split::Metric.find(Split::Metric.generate_key(experiment.name, "clicks")) }
    subject { metric }
    it { should_not be_nil }
    context "name" do
      subject { metric.name }
      it { should eql "clicks" }
    end
    context "experiment_name" do
      subject { metric.experiment_name }
      it { should eql "basket_text" }
    end
    context "values" do
      context "keys" do
        subject { metric.values.keys }
        it { should include "true" }
      end
      context "values" do
        subject { metric.values.values }
        it { should include 1 }
      end
    end
  end
  context "find_or_create" do
    context "doesn't exist, creates" do
      let(:metric) do
        Split::Metric.find_or_create(name: "clicks", experiment_name: experiment.name, values: {"true" => 1})
      end
      subject { metric }
      it { should_not be_nil }
    end
    context "exists, finds" do
      before do
        Split::Metric.create(name: "clicks", experiment_name: experiment.name, values: {"true" => 1})
      end
      let (:metric) { Split::Metric.find Split::Metric.generate_key(experiment.name, "clicks") }
      subject { metric }
      it { should_not be_nil }
    end
  end


end
