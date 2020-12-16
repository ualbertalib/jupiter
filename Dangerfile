# Make sure non-trivial amounts of code changes come with corresponding tests
has_app_changes = !git.modified_files.grep(/lib/).empty? || !git.modified_files.grep(/app/).empty?
has_test_changes = !git.modified_files.grep(/test/).empty?

if  git.lines_of_code > 50 && has_app_changes && !has_test_changes
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

# Ensure link to PR/issue is present in all CHANGELOG entries for this release
cl = File.read("CHANGELOG.md")

# get relevant section of CL (between unreleased and next version header)
cl = cl.split("## [Unreleased]").last.split("## [").first

# remove empty lines
cl.gsub! /^$\n/, ''

# remove headers
cl.gsub! /^###.+\n*/, ''

# remove lines with a link
cl.gsub! /^.+\]\(https:\/\/github.com\/ualbertalib\/jupiter\/.+\n*/, ''

unless cl.empty?
  fail("The following CHANGELOG entries are missing a link to a PR/issue:\n#{cl}", sticky: false)
end
