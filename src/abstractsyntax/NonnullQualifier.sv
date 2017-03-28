grammar edu:umn:cs:melt:exts:ableC:nonnull:src:abstractsyntax; 

imports edu:umn:cs:melt:ableC:abstractsyntax;

abstract production nonnullQualifier
top::Qualifier ::=
{
  local n :: String = "edu:umn:cs:melt:exts:ableC:nonnull";
  local isPositive :: Boolean = false;
  local appliesWithinRef :: Boolean = true;
  forwards to pluggableQualifier(n, isPositive, appliesWithinRef);
}

--aspect production integerConstant
--top::NumericConstant ::= num::String unsigned::Boolean suffix::IntSuffix
--{
--  top.addedNegQualifiers <-
--    if   toInt(num) == 0
--    then []
--    else [nonnullQualifier()];
--}

