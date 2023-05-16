require "readline"
require "open3"
require "tmpdir"

module GhKick
  def self.kick(
    pr,
    main: get_default_branch,
    origin: "origin",
    confirm: true,
    dry_run: false
  )
    begin
      tmpdir = nil
      Dir.mktmpdir do |d|
        tmpdir = d
        self.git("worktree", "add", "--force", d, main, dry_run: dry_run)

        Dir.chdir(d) do
          self.gh("pr", "checkout", pr, dry_run: dry_run)
          self.git("fetch", origin, main, dry_run: dry_run)
          self.git("rebase", "#{origin}/#{main}", dry_run: dry_run)
          if confirm
            if Readline
                 .readline("Force push (with lease) back to remote? [yN] ")
                 .strip
                 .downcase == "y"
              self.git(
                "push",
                "--force-with-lease",
                origin,
                main,
                dry_run: dry_run
              )
            end
          end
        end
      end
    ensure
      self.git("worktree", "remove", tmpdir, exception: false, dry_run: dry_run)
    end
  end

  def self.get_default_branch
    git("config", "--get", "init.defaultBranch", capture: true)
  end

  def self.current_branch
    git("rev-parse", "--abbrev-ref", "HEAD", capture: true)
  end

  def self.git(*args, **kwargs)
    self.run("git", *args, **kwargs)
  end

  def self.gh(*args, **kwargs)
    self.run("gh", *args, **kwargs)
  end

  def self.run(*args, exception: true, capture: false, dry_run: false)
    STDERR.puts "$ #{args.join(" ")}"

    if capture
      return SecureRandom.hex if dry_run
      stdout, status = Open3.capture2(*args)
      if exception
        raise "Error running command: #{status}" unless status.success?
      end
      stdout.chomp
    else
      system(*args, exception: exception)
    end
  end
end
