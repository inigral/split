module Split
  class Metric
    attr_accessor :name
    attr_accessor :experiment_name
    attr_accessor :values

    def initialize(attributes)
      @experiment_name = attributes[:experiment_name]
      @name = attributes[:name]
      @values = attributes[:values]
    end

    def to_s
      name
    end

    def self.find(key)
      if Split.redis.exists(key)
        experiment_name = key.to_s.split(':')[0]
        metric_name = key.to_s.split(':')[2]
        values = Split.redis.hgetall(key)
        values.each { |k,v| values[k] = v.to_i }
        self.new(name: metric_name, experiment_name: experiment_name, values: values)
      end
    end

    def self.create(attributes)
      experiment_name = attributes[:experiment_name]
      name = attributes[:name]
      values = attributes[:values]
      key = self.generate_key(experiment_name, name)
      if !Split.redis.exists key
        Split.redis.hmset key, values.flatten
        metric = self.new attributes
      else
        raise "Metric already exists"
      end
      metric
    end
    def self.find_or_create(attributes)
      name = attributes[:name]
      experiment_name = attributes[:experiment_name]
      metric = self.find generate_key(experiment_name, name)
      unless metric
        metric = Split::Metric.create(attributes)
      end
      metric
    end

    def self.generate_key(experiment_name, name)
      "#{experiment_name}:metric:#{name}"
    end

    def increment(alternative)
      Split.redis.hincrby key, alternative, 1
      @values = Split.redis.hgetall key
      @values.each { |k,v| @values[k] = v.to_i }
    end

    def experiment
      Split::Experiment.find(experiment_name)
    end

    def save
      Split.redis.hkeys(key).each do |k|
        Split.redis.hsetnx key, k, 0
      end
    end

    def reset
      Split.redis.hkeys(key).each do |k|
        Split.redis.hmset key, k, 0
      end
    end


    def delete
      Split.redis.del(key)
    end

    def self.valid?(name)
      String === name || hash_with_correct_values?(name)
    end

    def self.hash_with_correct_values?(name)
      Hash === name && String === name.keys.first && Float(name.values.first) rescue false
    end

    private

    def key
      Split::Metric.generate_key(experiment_name, name)
    end
  end
end

