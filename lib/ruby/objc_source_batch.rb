class ObjCSourceBatch

  BIN = File.dirname(File.expand_path(__FILE__)) + '/../../bin'

  def initialize(paths)
    @paths = paths
  end

  def process
    results = {}
    if (@paths.length > 0)
      # NEED TO FIX SPACES IN FILENAMES!
      sanitised_path = ""
      @paths.each { |apath| sanitised_path = sanitised_path +   apath.gsub(" ", "\\ ") + " " }
      
      json = JSON.parse(`#{BIN}/objcparser #{sanitised_path}`)
      json.each { |path, item|
        results[path] = process_item(item)
      }
    end
    results
  end

  private
  def process_item(item)
    result = {}
    if !item.nil?
      item.each { |k, v| result[k.to_sym] = v }
    end
    result
  end
end