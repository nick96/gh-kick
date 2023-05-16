require "readline"
require "open3"

module GhKick
  def self.kick(pr, main: get_default_branch, remote: "origin", confirm: true)
    Dir.mktmpdir do |d|
      git("worktree", "add", "--force", main, d, exception: true)
      Dir.chdir(d) do
        system("gh", "pr", "checkout", pr, exception: true)
        git("fetch", origin, main, exception: true)
        git("rebase", "#{origin}/#{main}", exception: true)
        if confirm
          if Readline
               .readline("Force push (with lease) back to remote? [yN] ")
               .strip
               .downcase == "y"
            git("push", "--force-with-lease", origin)
          end
        end
      end
    end
  end

  def self.get_default_branch
    git("config", "--get", "init.defaultBranch", capture: true)
  end

  def self.current_branch
    git("rev-parse", "--abbrev-ref", "HEAD", capture: true)
  end

  def self.git(*args, exception: true, capture: false)
    STDERR.puts "$ git #{arg.join(" ")}"
    if capture
      stdout, status = Open3.capture2("git", *args)
      if exception
        raise "Error running git command: #{status}" unless status.success?
      end
      stdout.chomp
    else
      system("git", *args, exception: exception)
    end
  end
end
