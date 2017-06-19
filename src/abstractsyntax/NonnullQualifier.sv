grammar edu:umn:cs:melt:exts:ableC:nonnull:src:abstractsyntax; 

imports silver:langutil;
imports silver:langutil:pp;
imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;

import edu:umn:cs:melt:ableC:abstractsyntax:overload as ovrld;

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

aspect production ovrld:dereferenceExpr
top::Expr ::= e::Expr
{
  -- TODO: allow user to specify regions to ignore errors?
  -- TODO: allow user to control whether errors are raised from generated code?
  local doCollectError :: Boolean =
    !endsWith(".h", top.location.filename) &&
    !endsWith(".xh", top.location.filename) &&
    case top.location of txtLoc(_) -> false | _ -> true end;

  top.errors <-
    if doCollectError &&
         !containsQualifier(nonnullQualifier(location=bogusLoc()), e.typerep)
    then [errNullDereference(top.location)]
    else [];

  local checkNull :: (Expr ::= Expr) = \tmpE :: Expr ->
    binaryOpExpr(
      tmpE,
      compareOp(equalsOp(location=bogusLoc()), location=bogusLoc()),
      mkIntConst(0, bogusLoc()),
      location=bogusLoc()
    );

  runtimeChecks <-
    if !doCollectError &&
         !containsQualifier(nonnullQualifier(location=bogusLoc()), e.typerep)
    then [pair(checkNull, "ERROR: attempted NULL dereference")]
    else [];
}

aspect production ovrld:memberExpr
top::Expr ::= lhs::Expr deref::Boolean rhs::Name
{
  local doCollectError :: Boolean =
    !endsWith(".h", top.location.filename) &&
    !endsWith(".xh", top.location.filename) &&
    case top.location of txtLoc(_) -> false | _ -> true end;

  top.errors <-
    if doCollectError &&
         !containsQualifier(nonnullQualifier(location=bogusLoc()), lhs.typerep)
    then [errNullDereference(top.location)]
    else [];

  local checkNull :: (Expr ::= Expr) = \tmpLhs::Expr ->
    binaryOpExpr(
      tmpLhs,
      compareOp(equalsOp(location=bogusLoc()), location=bogusLoc()),
      mkIntConst(0, bogusLoc()),
      location=bogusLoc()
    );

  runtimeChecks <-
    if !doCollectError &&
         !containsQualifier(nonnullQualifier(location=bogusLoc()), lhs.typerep)
    then [pair(checkNull, "ERROR: attempted NULL dereference")]
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

aspect production ovrld:explicitCastExpr
top::Expr ::= ty::TypeName e::Expr
{
  local checkNull :: (Expr ::= Expr) = \tmpE :: Expr ->
    binaryOpExpr(
      tmpE,
      compareOp(equalsOp(location=bogusLoc()), location=bogusLoc()),
      mkIntConst(0, bogusLoc()),
      location=bogusLoc()
    );
  runtimeChecks <-
    if containsQualifier(nonnullQualifier(location=bogusLoc()), ty.typerep) &&
         !containsQualifier(nonnullQualifier(location=bogusLoc()), e.typerep)
    then [pair(checkNull, "ERROR: attempted NULL dereference")]
    else [];
}

aspect production compilation
top::Compilation ::= srcAst::Root
{
  -- TODO: allow user to specify regions to ignore errors?
  -- TODO: allow user to control whether errors are raised from generated code?
--  local srcErrorFilter :: (Boolean ::= Message) =
--    \msg::Message ->
--      case msg of
--        errNullDereference(l) ->
--          endsWith(".h", l.filename) ||
--          endsWith(".xh", l.filename) ||
--          case l of txtLoc(_) -> true | _ -> false end
--      | _ -> true
--      end;

  local hostErrorFilter :: (Boolean ::= Message) =
    \msg::Message ->
      case msg of
        errNullDereference(l) -> false
      | _                     -> true
      end;

  -- FIXME: why is this filtering out source null dereferences?
--  top.srcErrorFilters <- [srcErrorFilter];
  top.hostErrorFilters <- [hostErrorFilter];
  top.liftedErrorFilters <- [hostErrorFilter];
}

abstract production errNullDereference
top::Message ::= l::Location
{
  forwards to err(l, "possible NULL dereference");
}

