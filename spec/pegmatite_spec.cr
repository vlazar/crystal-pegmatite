require "./spec_helper"
require "json"

describe Pegmatite do
  it "tokenizes basic JSON and builds a tree of JSON nodes" do
    source = <<-JSON
    {
      "hello": "world",
      "from": {
        "name": "Pegmatite",
        "version": [0, 1, 0],
        "nifty": true,
        "overcomplicated": false,
        "worse-than": null,
        "problems": []
      }
    }
    JSON
    
    tokens = Pegmatite.tokenize(Fixtures::JSON, source)
    tokens.should eq [
      {:object, 0, 182},
        {:pair, 4, 20},
          {:string, 5, 10}, # "hello"
          {:string, 14, 19}, # "world"
        {:pair, 24, 180},
          {:string, 25, 29}, # "from"
          {:object, 32, 180},
        {:pair, 38, 57},
          {:string, 39, 43}, # "name"
          {:string, 47, 56}, # "Pegmatite"
        {:pair, 63, 83},
          {:string, 64, 71}, # "version"
          {:array, 74, 83},
            {:number, 75, 76}, # 0
            {:number, 78, 79}, # 1
            {:number, 81, 82}, # 0
        {:pair, 89, 102},
          {:string, 90, 95}, # "nifty"
          {:true, 98, 102}, # true
        {:pair, 108, 132},
          {:string, 109, 124}, # "overcomplicated"
          {:false, 127, 132}, # false
        {:pair, 138, 156},
          {:string, 139, 149}, # "worse-than"
          {:null, 152, 156}, # null
        {:pair, 162, 176},
          {:string, 163, 171}, # "problems"
          {:array, 174, 176}, # []
    ]
    
    builder = ->(token : Pegmatite::Token, children : Array(JSON::Any)) do
      kind, start, finish = token
      case kind
      when :null then JSON::Any.new(nil)
      when :true then JSON::Any.new(true)
      when :false then JSON::Any.new(false)
      when :string then JSON::Any.new(source[start...finish])
      when :number then JSON::Any.new(source[start...finish].to_i64)
      when :array then JSON::Any.new(children)
      when :pair then JSON::Any.new(children)
      when :object then
        object = {} of String => JSON::Any
        children.each do |pair|
          key, value = pair.as_a
          object[key.as_s] = value
        end
        JSON::Any.new(object)
      else raise NotImplementedError.new(kind.inspect)
      end
    end
    
    result = Pegmatite.build_tree(tokens, builder)
    
    result.should eq JSON::Any.new({
      "hello" => JSON::Any.new("world"),
      "from" => JSON::Any.new({
        "name" => JSON::Any.new("Pegmatite"),
        "version" => JSON::Any.new([
          JSON::Any.new(0_i64),
          JSON::Any.new(1_i64),
          JSON::Any.new(0_i64),
        ]),
        "nifty" => JSON::Any.new(true),
        "overcomplicated" => JSON::Any.new(false),
        "worse-than" => JSON::Any.new(nil),
        "problems" => JSON::Any.new([] of JSON::Any),
      } of String => JSON::Any)
    } of String => JSON::Any)
  end
end
