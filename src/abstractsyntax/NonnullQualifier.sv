grammar edu:umn:cs:melt:exts:ableC:nonnull:src:abstractsyntax; 

imports silver:langutil;
imports silver:langutil:pp;
imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;


abstract production nonnullQualifier
top::Qualifier ::=
{
  top.pp = text("nonnull");
  top.mangledName = "nonnull";
  top.qualIsPositive = false;
  top.qualIsNegative = true;
  top.qualAppliesWithinRef = true;
  top.qualCompat = \qualToCompare::Qualifier ->
    case qualToCompare of nonnullQualifier() -> true | _ -> false end;
  top.qualIsHost = false;
  top.qualifyErrors =
    case top.typeToQualify of
      pointerType(_, _) -> []
    | _                 -> [err(top.location, "`nonnull' cannot qualify a non-pointer")]
    end;
}

aspect production dereferenceOp
top::UnaryOp ::=
{
  -- TODO: allow user to specify regions to ignore errors?
  local doCollectError :: Boolean =
    !endsWith(".h", top.location.filename) &&
    !endsWith(".xh", top.location.filename) &&
    case top.location of txtLoc(_) -> false | _ -> true end;

  top.errors <-
    if   doCollectError &&
         !containsQualifier(nonnullQualifier(location=bogusLoc()), top.op.typerep)
    then [err(top.location, "possible NULL dereference")]
    else [];
}

aspect production memberExpr
top::Expr ::= lhs::Expr deref::Boolean rhs::Name
{
  local doCollectError :: Boolean =
    !endsWith(".h", top.location.filename) &&
    !endsWith(".xh", top.location.filename) &&
    case top.location of txtLoc(_) -> false | _ -> true end;

  top.errors <-
    if   deref && doCollectError &&
         !containsQualifier(nonnullQualifier(location=bogusLoc()), lhs.typerep)
    then [err(top.location, "possible NULL dereference")]
    else [];
}

-- TODO: should initialization be forced as part of the semantics of nonnull?
aspect production declarator
top::Declarator ::= name::Name ty::TypeModifierExpr attrs::Attributes initializer::MaybeInitializer
{
  top.errors <-
    case initializer of
    | justInitializer(_) -> []
    | _ ->
          if   containsQualifier(nonnullQualifier(location=bogusLoc()), top.typerep)
          then [err(name.location, "nonnull pointer not initialized")]
          else []
    end;
}

aspect production addressOfOp
top::UnaryOp ::=
{
  top.collectedTypeQualifiers <- [nonnullQualifier(location=bogusLoc())];
}

