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
  top.errors <-
    if   !containsQualifier(nonnullQualifier(location=bogusLoc()), top.op.typerep)
    then [errNullDereference(top.location)]
    else [];
}

aspect production memberExpr
top::Expr ::= lhs::Expr deref::Boolean rhs::Name
{
  top.errors <-
    if   deref && !containsQualifier(nonnullQualifier(location=bogusLoc()), lhs.typerep)
    then [errNullDereference(top.location)]
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

aspect production compilation
top::Compilation ::= srcAst::Root
{
  -- TODO: allow user to specify regions to ignore errors?
  -- TODO: allow user to control whether errors are raised from generated code?
  local srcErrorFilter :: (Boolean ::= Message) =
    \msg::Message ->
      case msg of
        errNullDereference(l) ->
          endsWith(".h", l.filename) ||
          endsWith(".xh", l.filename) ||
          case l of txtLoc(_) -> true | _ -> false end
      | _ -> true
      end;

  local hostErrorFilter :: (Boolean ::= Message) =
    \msg::Message ->
      case msg of
        errNullDereference(l) -> false
      | _                     -> true
      end;

  top.srcErrorFilters <- [srcErrorFilter];
  top.hostErrorFilters <- [hostErrorFilter];
  top.liftedErrorFilters <- [hostErrorFilter];
}

abstract production errNullDereference
top::Message ::= l::Location
{
  forwards to err(l, "possible NULL dereference");
}

