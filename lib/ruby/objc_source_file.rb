require 'json'

class ObjCSourceFile

  BIN = File.dirname(File.expand_path(__FILE__)) + '/../../bin'

  def initialize(path)
    @path = path
  end

  def complexity
    json = JSON.parse(`#{BIN}/objcparser #{@path}`)
    result = {}
    json.each {|k,v| result[k.to_sym] = v }
    result
  end

end
