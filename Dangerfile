# Make sure non-trivial amounts of code changes come with corresponding tests
has_app_changes = !git.modified_files.grep(/lib/).empty? || !git.modified_files.grep(/app/).empty?
has_spec_changes = !git.modified_files.grep(/test/).empty?

if  git.lines_of_code > 50 && has_app_changes && !has_spec_changes
  warn('There are code changes, but no corresponding tests. '\
         'Please include tests if this PR introduces any modifications in '\
         'behavior.',
       sticky: false)
end

# Mainly to encourage writing up some reasoning about the PR, rather than
# just leaving a title
warn('Please add a detailed summary in the description.') if github.pr_body.length < 5

# Warn when there is a big PR
warn('This PR is too big! Consider breaking it down into smaller PRs.') if git.lines_of_code > 500

# Let people say that this isn't worth a CHANGELOG entry in the PR if they choose
declared_trivial = (github.pr_title + github.pr_body).include?("#trivial") || !has_app_changes

if !git.modified_files.include?("CHANGELOG.md") && !declared_trivial
  fail("Please include a CHANGELOG entry. \nYou can find it at [CHANGELOG.md](https://github.com/ualbertalib/jupiter/blob/master/CHANGELOG.md).", sticky: false)
end
