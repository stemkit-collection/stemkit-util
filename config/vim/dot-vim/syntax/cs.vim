" Vim syntax file
" Language:	C#
" Maintainer:	Johannes Zellner <johannes@zellner.org>
" Last Change:	Mon, 05 Nov 2001 10:45:07 +0100
" Filenames:	*.cs
" $Id: cs.vim,v 1.2 2001/11/05 09:46:02 joze Exp $

if exists("b:current_syntax")
    finish
endif

let s:cs_cpo_save = &cpo
set cpo&vim

" keyword definitions
syn keyword csKeyword		using namespace
syn keyword csStructure		class struct interface delegate event enum
syn keyword csKeyword		const readonly virtual override extern unsafe
syn keyword csKeyword		static public protected internal private abstract sealed
syn keyword csKeyword		explicit implicit operator
syn keyword csStorageClass	ref out params

syn keyword csStatement		if else break continue return
syn keyword csStatement		switch case default
syn keyword csStatement		for do while foreach in
syn keyword csStatement		this base super new is as typeof
syn keyword csStatement		goto
syn keyword csStatement		checked unchecked lock using
syn keyword csStatement		get set
syn keyword csException		throw try catch finally
syn keyword csNull		null
syn keyword csBoolean		true false
syn keyword csType		void sbyte byte short ushort int uint 
syn keyword csType		long ulong char float double bool decimal 
syn keyword csType		string object

" activate folding of blocks
syn region csBlock 		start="{" end="}" transparent fold

" Comments
"
" PROVIDES: @csCommentHook
"
" TODO: include strings ?
"
syn keyword csTodo		contained TODO FIXME XXX NOTE
syn region  csComment		start="/\*"  end="\*/" contains=@csCommentHook,csTodo fold
syn match   csComment		"//.*$" contains=@csCommentHook,csTodo

" doxygen comments
syn cluster doxygenRegionHook	add=csDoxygenCommentLeader
syn match csDoxygenCommentLeader +\/\*\*+ contained
syn region csDoxygenComment	start="/\*\*" end="\*/" contains=csDoxygenCommentLeader,@csDoxygen

syntax include @csDoxygen syntax\doxygen.vim

hi def link csDoxygenCommentLeader csDoxygenComment
hi csDoxygenComment guifg=#000099

" xml markup inside '///' comments
syn cluster xmlRegionHook	add=csXmlCommentLeader
syn cluster xmlCdataHook	add=csXmlCommentLeader
syn cluster xmlStartTagHook	add=csXmlCommentLeader
syn keyword csXmlTag contained Libraries Packages Types Excluded ExcludedTypeName ExcludedLibraryName
syn keyword csXmlTag contained ExcludedBucketName TypeExcluded Type TypeKind TypeSignature AssemblyInfo
syn keyword csXmlTag contained AssemblyName AssemblyPublicKey AssemblyVersion AssemblyCulture Base
syn keyword csXmlTag contained BaseTypeName Interfaces Interface InterfaceName Attributes Attribute
syn keyword csXmlTag contained AttributeName Members Member MemberSignature MemberType MemberValue
syn keyword csXmlTag contained ReturnValue ReturnType Parameters Parameter MemberOfPackage
syn keyword csXmlTag contained ThreadingSafetyStatement Docs devdoc example overload remarks returns summary
syn keyword csXmlTag contained threadsafe value internalonly nodoc exception param permission platnote
syn keyword csXmlTag contained seealso b c i pre sub sup block code note paramref see subscript superscript
syn keyword csXmlTag contained list listheader item term description altcompliant altmember

syn cluster xmlTagHook add=csXmlTag

syn match   csXmlCommentLeader	+\/\/\/+    contained
syn match   csXmlComment	+\/\/\/.*$+ contains=csXmlCommentLeader,@csXml
syntax include @csXml syntax/xml.vim
hi def link xmlRegion Comment

" 'preprocessor' stuff
syn region	csPreCondit	start="^\s*#" skip="\\$" end="$" contains=csComment,csRegion keepend fold
syn region	csRegion	start="^\s*#region" end="^\s*#endregion" transparent fold keepend extend
syn match	csRegionDelim	contained "#\(end\)?region"

" Strings and constants
" TODO special highlighting for unicode strings ?
syn match   csSpecialError	contained "\\."
syn match   csSpecialCharError	contained "[^']"
syn match   csSpecialChar	contained "\\\([4-9]\d\|[0-3]\d\d\|[\"\\'ntbrf]\|u\x\{4\}\)"
syn region  csString		start=+"+ end=+"+ end=+$+ contains=csSpecialChar,csSpecialError,@Spell
syn match   csCharacter		"'[^']*'" contains=csSpecialChar,csSpecialCharError
syn match   csCharacter		"'\\''" contains=csSpecialChar
syn match   csCharacter		"'[^\\]'"
syn match   csNumber		"\<\(0[0-7]*\|0[xX]\x\+\|\d\+\)[lL]\=\>"
syn match   csNumber		"\(\<\d\+\.\d*\|\.\d\+\)\([eE][-+]\=\d\+\)\=[fFdD]\="
syn match   csNumber		"\<\d\+[eE][-+]\=\d\+[fFdD]\=\>"
syn match   csNumber		"\<\d\+\([eE][-+]\=\d\+\)\=[fFdD]\>"

" The default highlighting.
hi def link csKeyword		StorageClass
hi def link csStructure		StorageClass
hi def link csStorageClass	StorageClass
hi def link csNull		Constant
hi def link csBoolean		Constant
hi def link csSpecialError	Error
hi def link csSpecialCharError	Error
hi def link csString		String
hi def link csPreCondit		PreCondit
hi def link csRegionDelim	PreCondit
hi def link csCharacter		Character
hi def link csSpecialChar	SpecialChar
hi def link csNumber		Number
hi def link csStatement		Statement
hi def link csConditional	Conditional
hi def link csXmlCommentLeader	Comment
hi def link csXmlComment	Comment
hi def link csComment		Comment
hi def link csTodo		Todo
hi def link csType		Type
hi def link csException		Exception
hi def link csXmlTag		Statement

let b:current_syntax = "cs"

let &cpo = s:cs_cpo_save
unlet s:cs_cpo_save

" Expand the out-most folding block, usually a class or a namespace
" set foldlevel=1

" vim: ts=8
