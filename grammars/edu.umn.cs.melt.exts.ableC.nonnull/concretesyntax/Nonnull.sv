grammar edu:umn:cs:melt:exts:ableC:nonnull:concretesyntax;

-- Import host language components
imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:host as abs;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as abs;


-- Some library utilities and the nonnull abstract syntax
imports silver:langutil;
imports edu:umn:cs:melt:exts:ableC:nonnull:abstractsyntax;

marking terminal Nonnull_t 'nonnull' lexer classes {Keyword, Global};

concrete production nonnullTypeQualifier_c
top::TypeQualifier_c ::= 'nonnull'
{
  top.typeQualifiers = abs:foldQualifier([nonnullQualifier(location=top.location)]);
  top.mutateTypeSpecifiers = [];
}

