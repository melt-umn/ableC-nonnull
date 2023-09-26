grammar edu:umn:cs:melt:exts:ableC:nonnull:abstractsyntax; 

imports silver:langutil;
imports silver:langutil:pp;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:injectable as inj;

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
  top.errors :=
    case top.typeToQualify of
      pointerType(_, _) -> []
    | _                 -> [errFromOrigin(top, "`nonnull' cannot qualify a non-pointer")]
    end;
}

aspect production inj:dereferenceExpr
top::Expr ::= e::Expr
{
  -- true if a detected error should be suppressed; false if it should be raised
  local suppressError :: Boolean = checkSuppressError();

  -- Collect the compile-time error if it is not suppressed (e.g. for .h files
  -- or generated code). This will collect errors in the host tree where
  -- qualifiers have been removed; these host-tree errors will be added now then
  -- filtered out later.
  lerrors <-
    if !suppressError &&
         !containsQualifier(nonnullQualifier(), e.typerep)
    then [errNullDereference()]
    else [];

  local checkNull :: (Expr ::= Expr) = \tmpE :: Expr ->
    equalsExpr(tmpE, mkIntConst(0));

  -- possible errors in .h files or in generated code are checked at runtime
  -- if the compile-time is suppressed
  runtimeMods <-
    if suppressError &&
         !containsQualifier(nonnullQualifier(), e.typerep)
    then [inj:runtimeCheck(checkNull, "ERROR: attempted NULL dereference\\n")]
    else [];
}

aspect production inj:memberExpr
top::Expr ::= lhs::Expr deref::Boolean rhs::Name
{
  local suppressError :: Boolean = checkSuppressError();

  lerrors <-
    if !suppressError && deref &&
         !containsQualifier(nonnullQualifier(), lhs.typerep)
    then [errNullDereference()]
    else [];

  local checkNull :: (Expr ::= Expr) = \tmpLhs::Expr ->
    equalsExpr(tmpLhs, mkIntConst(0));

  runtimeMods <-
    if suppressError &&
         !containsQualifier(nonnullQualifier(), lhs.typerep)
    then [inj:runtimeCheck(checkNull, "ERROR: attempted NULL dereference\\n")]
    else [];
}

-- TODO: should initialization be forced as part of the semantics of nonnull?
aspect production declarator
top::Declarator ::= name::Name ty::TypeModifierExpr attrs::Attributes initializer::MaybeInitializer
{
  local suppressError :: Boolean = checkSuppressError();

  top.errors <-
    if !suppressError
    then
      case initializer of
      | justInitializer(_) -> []
      | _ ->
            if   containsQualifier(nonnullQualifier(), top.typerep)
            then [errFromOrigin(name, "nonnull pointer not initialized")]
            else []
      end
    else [];
}

aspect production inj:addressOfExpr
top::Expr ::= e::Expr
{
  injectedQualifiers <- [nonnullQualifier()];
}

aspect production inj:explicitCastExpr
top::Expr ::= ty::TypeName e::Expr
{
  local checkNull :: (Expr ::= Expr) = \tmpE :: Expr ->
    equalsExpr(tmpE, mkIntConst(0));

  runtimeMods <-
    if containsQualifier(nonnullQualifier(), ty.typerep) &&
         !containsQualifier(nonnullQualifier(), e.typerep)
    then [inj:runtimeCheck(checkNull, "ERROR: attempted cast of NULL to nonnull\\n")]
    else [];
}

aspect production compilation
top::Compilation ::= srcAst::Root
{
  -- filter out false errors that were added to the host tree only because
  -- qualifiers were removed
  local hostErrorFilter :: (Boolean ::= Message) =
    \msg::Message ->
      case msg of
        errNullDereference() -> false
      | _                    -> true
      end;

  top.hostErrorFilters <- [hostErrorFilter];
}

abstract production errNullDereference
top::Message ::=
{
  top.where = getParsedOriginLocationOrFallback(top);
  top.message = "possible NULL dereference";
  top.severity = 2;
}

-- return true if an error at this location should be suppressed
function checkSuppressError
Boolean ::=
{
  -- TODO: allow user to specify regions to ignore errors?
  -- TODO: allow user to control whether errors are raised from generated code?

  -- suppress errors in generated code
  return originatesInExt(getOriginInfoChain(ambientOrigin())).isJust;
}

