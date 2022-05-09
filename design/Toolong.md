## Loose goals
* Discussion is a directed graph, not a linked list.
* Discussion is _precise_; often responses are specific to certain parts of another comment, rather than the entire comment itself.
* Editing should be possible, and the result should be natural as far as possible.
* You need the ability to "overlay" different aspects on the discussion..
	* Example: Moderators need to be able to see all flagged comments.
	* Example: The OP should be able to group related points. (E.g. multiple questions about a certain topic)
	* Example: Marking discussions as "resolved."
* Accessibility support should be built-in.
* Moderator tools need attention.
* Search needs to work well.
* Feature composition should work well.
* Performance should be excellent.

## Core concepts
- A *[[discussion]]* is a directed graph of comments.
- A *[[comment]]* is a singular fragment of a discussion.
	- In the common case, a comment would have 1 or more parent *comment selections*. It may also have 0 parent comment selections, such as someone commenting on a meta aspect of a thread.
	- Comments support at least a basic set of reactions.
	- Comments support tagging. Other people can add tags to existing comments.
	- Comments should have titles, facilitating "collapsing" comments in the UI.
	- Comments support flagging.
- A *[[comment selection]]* is either an entire comment, or a subrange of a comment.
- A _[[post]]_ is a comment that starts a discussion.
- A _[[discussion view]]_ is a view displaying a [[discussion]].
	- Every discussion view has a canonical form. This can be edited by a strict subset of users (mods + OP maybe?).
	- People can modify the discussion view to suit their needs.

## Key pieces
* `CommentView`:
	* Key functionality:
		* Rendering Markdown
			* Markdown flavor is CommonMark w/ some extensions.
				* Extension: `@` mentions for people.
				* Extension: Tables
				* Extension: Math via KaTeX
		* Support selections.
		* Editing a comment. Editing + selections mean that we need some level of bidirectionality between the output rich text and the input Markdown, so that we can map pre-edit selections to post-edit selections. Perhaps Peritext's model of anchors is the right fit here.
* `CommentActions`
	* Click to select
		* Reply
		* Flag
	* React
	* Tab to cycle
* `DiscussionActions`:
	* (Mod only) Lock discussion
	* Filter comments by tag etc.
* Responsive design:
	* How does this work on phones?
* Accessibility:
	* Key unknowns:
		* The UI would be heavily mouse-based for many actions. How do we make everything work in a keyboard-based environment?
			* Example: Cycling through different comments which are organized like a graph. Perhaps can be done through proper use of Aria labels?
			* Example: Selecting the part of someone's comment to respond to. -- How do you support narrowing selection in an fast & intuitive way?
* Internationalization
* Authentication and authorization

## Implementation notes
Considering trying Phoenix LiveView

Resources:
* [Latency simulation](https://hexdocs.pm/phoenix_live_view/0.17.9/js-interop.html#simulating-latency)
- [Example app with Markdown preview](https://github.com/nickdichev/markdown-live)
- [Fly.io posts](https://fly.io/phoenix-files/)
	- [Accessibility](https://fly.io/blog/intro-to-accessibility/) 
		- "Compared to an accessibility checklist, an accessibility-focused _process_ asks what barriers each choice might impose, then works to either address or eliminate those before they're set in stone. Doing this requires knowing which questions to ask, and asking them before they become costly mistakes that are hard to fix."

## Example threads that Toolong should help with
People rehashing points across the thread:
https://old.reddit.com/r/haskell/comments/ujpzx3/was_simplified_subsumption_worth_it_for_industry/

Very long thread for a seemingly small change: https://forums.swift.org/t/se-0345-if-let-shorthand-for-shadowing-an-existing-optional-variable/55805