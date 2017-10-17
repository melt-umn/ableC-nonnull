grammar edu:umn:cs:melt:exts:ableC:nonnull:abstractsyntax; 

imports silver:langutil;
imports silver:langutil:pp;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:injectable as inj;

global MODULE_NAME :: String = "edu:umn:cs:melt:exts:ableC:nonnull";

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
    | _                 -> [err(top.location, "`nonnull' cannot qualify a non-pointer")]
    end;
}

aspect production inj:dereferenceExpr
top::Expr ::= e::Expr
{
  -- true if a detected error should be suppressed; false if it should be raised
  local suppressError :: Boolean = checkSuppressError(top.location);

  -- Collect the compile-time error if it is not suppressed (e.g. for .h files
  -- or generated code). This will collect errors in the host tree where
  -- qualifiers have been removed; these host-tree errors will be added now then
  -- filtered out later.
  lerrors <-
    if !suppressError &&
         !containsQualifier(nonnullQualifier(location=builtinLoc(MODULE_NAME)), e.typerep)
    then [errNullDereference(top.location)]
    else [];

  local checkNull :: (Expr ::= Expr) = \tmpE :: Expr ->
    equalsExpr(tmpE, mkIntConst(0, builtinLoc(MODULE_NAME)), location=builtinLoc(MODULE_NAME));

  -- possible errors in .h files or in generated code are checked at runtime
  -- if the compile-time is suppressed
  runtimeMods <-
    if suppressError &&
         !containsQualifier(nonnullQualifier(location=builtinLoc(MODULE_NAME)), e.typerep)
    then [inj:runtimeCheck(checkNull, "ERROR: attempted NULL dereference\\n", top.location)]
    else [];
}

aspect production inj:memberExpr
top::Expr ::= lhs::Expr deref::Boolean rhs::Name
{
  local suppressError :: Boolean = checkSuppressError(top.location);

  lerrors <-
    if !suppressError &&
         !containsQualifier(nonnullQualifier(location=builtinLoc(MODULE_NAME)), lhs.typerep)
    then [errNullDereference(top.location)]
    else [];

  local checkNull :: (Expr ::= Expr) = \tmpLhs::Expr ->
    equalsExpr(tmpLhs, mkIntConst(0, builtinLoc(MODULE_NAME)), location=builtinLoc(MODULE_NAME));

  runtimeMods <-
    if suppressError &&
         !containsQualifier(nonnullQualifier(location=builtinLoc(MODULE_NAME)), lhs.typerep)
    then [inj:runtimeCheck(checkNull, "ERROR: attempted NULL dereference\\n", top.location)]
    else [];
}

-- TODO: should initialization be forced as part of the semantics of nonnull?
aspect production declarator
top::Declarator ::= name::Name ty::TypeModifierExpr attrs::Attributes initializer::MaybeInitializer
{
  local suppressError :: Boolean = checkSuppressError(top.sourceLocation);

  top.errors <-
    if !suppressError
    then
      case initializer of
      | justInitializer(_) -> []
      | _ ->
            if   containsQualifier(nonnullQualifier(location=builtinLoc(MODULE_NAME)), top.typerep)
            then [err(name.location, "nonnull pointer not initialized")]
            else []
      end
    else [];
}

aspect production addressOfOp
top::UnaryOp ::=
{
  top.injectedQualifiers <- [nonnullQualifier(location=builtinLoc(MODULE_NAME))];
}

aspect production inj:explicitCastExpr
top::Expr ::= ty::TypeName e::Expr
{
  local checkNull :: (Expr ::= Expr) = \tmpE :: Expr ->
    equalsExpr(tmpE, mkIntConst(0, builtinLoc(MODULE_NAME)), location=builtinLoc(MODULE_NAME));

  runtimeMods <-
    if containsQualifier(nonnullQualifier(location=builtinLoc(MODULE_NAME)), ty.typerep) &&
         !containsQualifier(nonnullQualifier(location=builtinLoc(MODULE_NAME)), e.typerep)
    then [inj:runtimeCheck(checkNull, "ERROR: attempted cast of NULL to nonnull\\n", top.location)]
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
        errNullDereference(l) -> false
      | _                     -> true
      end;

  top.hostErrorFilters <- [hostErrorFilter];
  top.liftedErrorFilters <- [hostErrorFilter];
}

abstract production errNullDereference
top::Message ::= l::Location
{
  forwards to err(l, "possible NULL dereference");
}

-- return true if an error at this location should be suppressed
function checkSuppressError
Boolean ::= loc::Location
{
  -- TODO: allow user to specify regions to ignore errors?
  -- TODO: allow user to control whether errors are raised from generated code?

  -- suppress errors in .h files and in generated code
  return
    endsWith(".h", loc.filename) ||
    endsWith(".xh", loc.filename) ||
    case loc of txtLoc(_) -> true | _ -> false end;
}

