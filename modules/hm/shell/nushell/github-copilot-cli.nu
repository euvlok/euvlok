def copilot_helper [command: string, ...args] {
    use std log
    let temp_file = mktemp --tmpdir --suffix .nu

    let enhanced_args = ["shell:" "nushell" " " (nu -v)] ++ $args

    try {
        ^github-copilot-cli $command ...$enhanced_args --shellout $temp_file

        if $env.LAST_EXIT_CODE != 0 {
            log error "GitHub Copilot CLI command failed"
            return
        }

        if not ($temp_file | path exists) {
            log error "No command was generated"
            return
        }

        try {
            ^nu $temp_file
        } catch {|e|
            log error $"Failed to execute generated command: ($e.msg)"
        }

    } catch {|e|
        log error $"Command failed: ($e.msg)"
    }

    # Cleanup
    if ($temp_file | path exists) {
        rm $temp_file
    }
}

alias ?? = copilot_helper what-the-shell
alias wts = copilot_helper what-the-shell
alias git? = copilot_helper git-assist
alias gh? = copilot_helper gh-assist
