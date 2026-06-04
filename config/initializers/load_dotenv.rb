# Minimal .env loader for local development/test.
#
# We don't use the dotenv gem: its 3.2 parser dropped our key's value to an
# empty string. This reads KEY=value lines directly. It never overrides a real
# ENV var (so production / Railway env vars always win) and only runs locally.
if Rails.env.local?
  env_file = Rails.root.join(".env")
  if File.exist?(env_file)
    File.foreach(env_file) do |line|
      line = line.strip
      next if line.empty? || line.start_with?("#")

      key, separator, value = line.partition("=")
      next if separator.empty?

      key = key.strip
      value = value.strip.gsub(/\A["']|["']\z/, "")
      next if key.empty?

      # Fill from .env when the current ENV value is blank. This matters
      # because some host environments export ANTHROPIC_API_KEY="" (empty),
      # which a plain ||= would preserve. A real, non-empty ENV var still wins.
      ENV[key] = value if ENV.fetch(key, "").to_s.strip.empty?
    end
  end
end
