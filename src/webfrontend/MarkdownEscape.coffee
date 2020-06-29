# Original JS code in https://github.com/kemitchell/markdown-escape.js
class MarkdownEscape

	@replacements = [
		[/\*/g, '\\*', 'asterisks'],
		[/#/g, '\\#', 'number signs'],
		[/\//g, '\\/', 'slashes'],
		[/\(/g, '\\(', 'parentheses'],
		[/\)/g, '\\)', 'parentheses'],
		[/\[/g, '\\[', 'square brackets'],
		[/\]/g, '\\]', 'square brackets'],
		[/</g, '&lt;', 'angle brackets'],
		[/>/g, '&gt;', 'angle brackets'],
		[/_/g, '\\_', 'underscores']
	]

	@escape: (string, skips) ->
		skips = skips || []
		return @replacements.reduce((string, replacement) =>
				name = replacement[2]
				return if name && skips.indexOf(name) != -1 then string else string.replace(replacement[0], replacement[1])
		, string)