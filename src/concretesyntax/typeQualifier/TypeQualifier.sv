grammar edu:umn:cs:melt:exts:ableC:nonnull:src:concretesyntax:typeQualifier;

-- Import host language components
imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax as abs;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction as abs;


-- Some library utilities and the nonnull abstract syntax
imports silver:langutil;
imports edu:umn:cs:melt:exts:ableC:nonnull:src:abstractsyntax ;

marking terminal Nonnull_t 'nonnull' lexer classes {Ckeyword};

concrete production nonnullTypeQualifier_c
top::TypeQualifier_c ::= 'nonnull'
{
  top.typeQualifiers = abs:foldQualifier([nonnullQualifier(location=top.location)]);
  top.mutateTypeSpecifiers = [];
}

