grammar edu:umn:cs:melt:exts:ableC:nonnull:src:abstractsyntax; 

imports edu:umn:cs:melt:ableC:abstractsyntax;

global nonnullQualifierName :: String = "edu:umn:cs:melt:exts:ableC:nonnull";

abstract production nonnullQualifier
top::Qualifier ::=
{
  local n :: String = nonnullQualifierName;
  local isPositive :: Boolean = false;
  local appliesWithinRef :: Boolean = true;
  forwards to pluggableQualifier(n, isPositive, appliesWithinRef);
}

aspect production dereferenceOp
top::UnaryOp ::=
{
  top.errors <-
    if   !containsQualifier(nonnullQualifierName, top.op.typerep)
    then [err(top.location, "possible NULL dereference")]
    else [];
}

aspect production memberExpr
top::Expr ::= lhs::Expr deref::Boolean rhs::Name
{
  top.errors <-
    if   deref && !containsQualifier(nonnullQualifierName, lhs.typerep)
    then [err(top.location, "possible NULL dereference")]
    else [];
}

-- TODO: should initialization be forced as part of the semantics of nonnull?
aspect production declarator
top::Declarator ::= name::Name ty::TypeModifierExpr attrs::[Attribute] initializer::MaybeInitializer
{
  top.errors <-
    case initializer of
    | justInitializer(_) -> []
    | _ ->
          if   containsQualifier(nonnullQualifierName, top.typerep)
          then [err(name.location, "nonnull pointer not initialized")]
          else []
    end;
}

aspect production addressOfOp
top::UnaryOp ::=
{
  top.collectedTypeQualifiers <- [nonnullQualifier()];
}

