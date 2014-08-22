require 'sinatra'
require 'haml'
require 'json'

get '/list' do
	output = ""
	for x in Dir.entries("public/data").reject { |path| path.start_with?(".") }
		output += "<li><a href=\"/#"+x+"\">"+x+"</a></li>"
	end

	haml :list, :locals => { :project_list => output }
end

get '/list.json' do
	output = []
	for x in Dir.entries("public/data").reject { |path| path.start_with?(".") }
		output.push(x)
	end

	JSON.generate(output)
end

get '/' do
  haml :index
end
