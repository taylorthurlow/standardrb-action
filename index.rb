# Based almost completely on https://github.com/gimenete/rubocop-action
require "net/http"
require "json"
require "time"

@GITHUB_SHA = ENV["GITHUB_SHA"]
@GITHUB_EVENT_PATH = ENV["GITHUB_EVENT_PATH"]
@GITHUB_TOKEN = ENV["GITHUB_TOKEN"]
@GITHUB_WORKSPACE = ENV["GITHUB_WORKSPACE"]

@event = JSON.parse(File.read(ENV["GITHUB_EVENT_PATH"]))
@repository = @event["repository"]
@owner = @repository["owner"]["login"]
@repo = @repository["name"]

@check_name = "StandardRB checks"

@headers = {
  "Content-Type": "application/json",
  Accept: "application/vnd.github.antiope-preview+json",
  Authorization: "Bearer #{@GITHUB_TOKEN}",
  "User-Agent": "standardrb-action"
}

def create_check
  body = {
    "name" => @check_name,
    "head_sha" => @GITHUB_SHA,
    "status" => "in_progress",
    "started_at" => Time.now.iso8601
  }

  http = Net::HTTP.new("api.github.com", 443)
  http.use_ssl = true
  path = "/repos/#{@owner}/#{@repo}/check-runs"

  resp = http.post(path, body.to_json, @headers)

  if resp.code.to_i >= 300
    raise resp.message
  end

  data = JSON.parse(resp.body)
  data["id"]
end

def update_check(id, conclusion, output)
  body = {
    "name" => @check_name,
    "head_sha" => @GITHUB_SHA,
    "status" => "completed",
    "completed_at" => Time.now.iso8601,
    "conclusion" => conclusion,
    "output" => output
  }

  http = Net::HTTP.new("api.github.com", 443)
  http.use_ssl = true
  path = "/repos/#{@owner}/#{@repo}/check-runs/#{id}"

  resp = http.patch(path, body.to_json, @headers)

  if resp.code.to_i >= 300
    raise resp.message
  end
end

@annotation_levels = {
  "refactor" => "failure",
  "convention" => "failure",
  "warning" => "warning",
  "error" => "failure",
  "fatal" => "failure"
}

def run_standardrb
  annotations = []

  errors = JSON.parse(File.read("results.json"))

  conclusion = "success"
  count = 0

  raise "Standard checked zero files" if errors["files"].none?

  errors["files"].each do |file|
    path = file["path"]
    offenses = file["offenses"]

    offenses.each do |offense|
      severity = offense["severity"]
      message = offense["message"]
      location = offense["location"]
      annotation_level = @annotation_levels[severity]
      count += 1

      if annotation_level == "failure"
        conclusion = "failure"
      end

      annotations.push({
        "path" => path,
        "start_line" => location["start_line"],
        "end_line" => location["start_line"],
        :annotation_level => annotation_level,
        "message" => message
      })
    end
  end

  output = {
    :title => @check_name,
    :summary => "#{count} offense(s) found",
    "annotations" => annotations
  }

  {"output" => output, "conclusion" => conclusion}
end

def run
  id = create_check

  results = run_standardrb
  conclusion = results["conclusion"]
  output = results["output"]

  update_check(id, conclusion, output)
end

begin
  run
rescue => e
  puts e.message
  exit 1
end
