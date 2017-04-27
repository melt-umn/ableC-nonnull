grammar edu:umn:cs:melt:exts:ableC:nonnull:src:abstractsyntax; 

imports silver:langutil;
imports silver:langutil:pp;
imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;


abstract production nonnullQualifier
top::Qualifier ::=
{
  local isPositive :: Boolean = false;
  local appliesWithinRef :: Boolean = true;
  local compat :: (Boolean ::= Qualifier) = \qualToCompare::Qualifier ->
    case qualToCompare of nonnullQualifier() -> true | _ -> false end;
  forwards to pluggableQualifier(isPositive, appliesWithinRef, compat);
}

aspect production dereferenceOp
top::UnaryOp ::=
{
  top.errors <-
    if   !containsQualifier(nonnullQualifier(), top.op.typerep)
    then [err(top.location, "possible NULL dereference")]
    else [];
}

aspect production memberExpr
top::Expr ::= lhs::Expr deref::Boolean rhs::Name
{
  top.errors <-
    if   deref && !containsQualifier(nonnullQualifier(), lhs.typerep)
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
          if   containsQualifier(nonnullQualifier(), top.typerep)
          then [err(name.location, "nonnull pointer not initialized")]
          else []
    end;
}

aspect production addressOfOp
top::UnaryOp ::=
{
  top.collectedTypeQualifiers <- [nonnullQualifier()];
}

